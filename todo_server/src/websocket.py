"""
WebSocket endpoint logic for handling real-time communication,
including text messages and chunked audio data transfer.
"""

import asyncio # Add this import
import json
import os
import sys
from typing import final
from fastapi import WebSocket, WebSocketDisconnect, status
from enum import StrEnum
from dotenv import load_dotenv
from loguru import logger
from openai.types.chat import ChatCompletionMessageParam

from src.ai_manager import AiManager
from src.code_manager import CodeManager
from src.groq_manager import GroqManager
from src.todoist_manager import TodoistManager
from src.tts_manager import TTSManager

_ = load_dotenv()

TODOIST_AGENT_ACCESS_KEY = os.getenv("TODOIST_AGENT_ACCESS_KEY")
if not TODOIST_AGENT_ACCESS_KEY:
    logger.error("TODOIST_AGENT_ACCESS_KEY environment variable not set.")
    raise ValueError("TODOIST_AGENT_ACCESS_KEY environment variable not set.")


logger.remove()
_ = logger.add(
    sys.stderr,
    format="{time:YYYY-MM-DD HH:mm:ss.S} | {level: <8} | {name}:{function}:{line} - {message}",
    level="DEBUG",
)


class MessageType(StrEnum):
    ERROR = "error"
    INFO = "info"
    TRANSCRIPTION = "transcription"
    CODE = "code"
    ANSWER = "answer"
    AI_SPEECH = "ai_speech"


@final
class WebsocketManager:
    def __init__(self, ws: WebSocket):
        self.groq_manager = GroqManager()
        self.todoist_manager = TodoistManager()
        self.ai_manager = AiManager()
        self.code_manager = CodeManager()
        self.tts_manager = TTSManager()
        self.ws = ws

        self.reset()

    def reset(self):
        logger.info("Resetting WebsocketManager")
        self.transcription = None
        self.todoist_coro = None
        self.audio_buffer = bytearray()
        self.history: list[ChatCompletionMessageParam] = []

    async def send_message(self, message_type: MessageType, message: str):
        # Use debug for potentially verbose messages, info for confirmation
        log_message_preview = message[:100] + "..." if len(message) > 100 else message
        logger.debug(f"Preparing to send {message_type} message: {log_message_preview}")
        await self.ws.send_text(json.dumps({"type": message_type, "message": message}))
        logger.info(f"Sent {message_type} message (awaited)") # Log after await completes

    async def send_bytes(self, message_type: MessageType, message: bytes):
        logger.debug(f"Preparing to send {message_type} bytes ({len(message)} bytes)...")
        if len(message) == 0:
            logger.warning(f"Received empty {message_type} message.")
            await self.send_message(MessageType.ERROR, "Received empty bytes message.")
            logger.warning(f"Attempted to send empty {message_type} message.")
            await self.send_message(MessageType.ERROR, "Attempted to send empty bytes message.")
            return
        await self.ws.send_bytes(message)
        logger.info(f"Sent {message_type} message: {len(message)} bytes (awaited).") # Log after await completes

    def fetch_tasks(self):
        self.todoist_coro = self.todoist_manager.get_tasks()
        logger.info("Fetching tasks initiated.")

    def add_chunk(self, chunk: bytes):
        self.audio_buffer.extend(chunk)
        logger.debug(
            f"Received audio chunk: {len(chunk)} bytes. Total: {len(self.audio_buffer)} bytes."
        )

    async def transcribe(self):
        try:
            self.transcription = await self.groq_manager.transcribe_audio(
                bytes(self.audio_buffer), file_format="opus"
            )
            await self.send_message(MessageType.TRANSCRIPTION, self.transcription)
        except Exception as e:
            error_message = f"Transcription task failed: {e}"
            logger.error(error_message)
            await self.send_message(MessageType.ERROR, error_message)
        finally:
            self.audio_buffer = bytearray()

    async def tasks(self) -> str:
        logger.info("Fetching tasks...")
        if self.todoist_coro is None:
            logger.warning(
                "todoist_coro was None when tasks() was called. Re-fetching."
            )
            self.todoist_coro = self.todoist_manager.get_tasks()
        tasks = await self.todoist_coro
        logger.info("Tasks ready")
        return tasks

    async def exec_flow(self, transcription: str | None = None):
        if transcription is None:
            n_bytes = len(self.audio_buffer)
            logger.info(
                f"Finished receiving audio: {n_bytes} bytes. Starting transcription."
            )
            await self.transcribe()
        else:
            logger.info(f"Using provided transcription: {transcription}")
            self.transcription = transcription
        if self.transcription is None:
            return
        tasks = await self.tasks()
        code_info = self.todoist_manager.get_code_info()
        code = self.ai_manager.get_code_ai_response(
            tasks, code_info, self.transcription, self.history
        )
        await self.send_message(MessageType.CODE, code)
        await asyncio.sleep(0.05) # Small delay experiment

        logger.debug("Executing code...")
        exec_result = self.code_manager.execute(code)
        logger.debug(f"Code execution finished.")
        await self.send_message(MessageType.INFO, exec_result)
        await asyncio.sleep(0.05) # Small delay experiment

        answer = self.ai_manager.get_answer_ai_response(
            tasks, code, exec_result, self.history
        )
        await self.send_message(MessageType.ANSWER, answer)
        await asyncio.sleep(0.05) # Small delay experiment

        audio = self.tts_manager.text_to_speech(answer)
        await self.send_bytes(MessageType.AI_SPEECH, audio)
        # No sleep after last send

        self.update_history(code, exec_result, answer)

    def update_history(self, code: str, exec_result: str, answer: str):
        transcription = """
<user_request_history>
{transcription}
</user_request_history>
        """.strip()
        self.history.append({"content": transcription, "role": "user"})
        combined_message = f"""<code_history>
{code}
</code_history>
<output_history>
{exec_result}
</output_history>
<answer_history>
{answer}
</answer_history>""".strip()
        self.history.append({"content": combined_message, "role": "assistant"})


async def websocket_endpoint(websocket: WebSocket):
    auth_header = websocket.headers.get("X-Agent-Access-Key")
    if auth_header != TODOIST_AGENT_ACCESS_KEY:
        logger.warning(
            f"WebSocket connection rejected for {websocket.client}: Invalid or missing X-Agent-Access-Key header."
        )
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await websocket.accept()
    logger.info(f"Client {websocket.client} connected with valid access key.")
    manager = WebsocketManager(websocket)
    try:
        while True:
            message = await websocket.receive()
            if message.get("text", False):
                data: str = message["text"]
                logger.info(f"Received message: {data}")
                if data == "INIT":
                    manager.reset()
                elif data == "START_AUDIO":
                    manager.fetch_tasks()
                    await manager.send_message(
                        MessageType.INFO, "Audio transmission started."
                    )
                elif data == "END_AUDIO":
                    await manager.exec_flow()
                else:
                    try:
                        json_data: dict[str, str] = json.loads(data)
                        if json_data.get("type") == MessageType.TRANSCRIPTION:
                            manager.fetch_tasks()
                            await manager.exec_flow(json_data["message"])
                    except json.JSONDecodeError:
                        logger.warning(f"Received invalid JSON data: {data}")
                        await manager.send_message(
                            MessageType.ERROR, "Received invalid JSON data."
                        )
                        continue

            elif message.get("bytes", False):
                audio_chunk: bytes = message["bytes"]
                manager.add_chunk(audio_chunk)

    except WebSocketDisconnect:
        logger.info(f"Client {websocket.client} disconnected")
