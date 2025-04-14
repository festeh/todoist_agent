"""
WebSocket endpoint logic for handling real-time communication,
including text messages and chunked audio data transfer.
"""

import json
import os
from typing import final
from fastapi import WebSocket, WebSocketDisconnect, status
from enum import StrEnum
from dotenv import load_dotenv

from src.ai_manager import AiManager
from src.code_manager import CodeManager
from src.groq_manager import GroqManager
from src.todoist_manager import TodoistManager
from src.tts_manager import TTSManager

_ = load_dotenv()

TODOIST_AGENT_ACCESS_KEY = os.getenv("TODOIST_AGENT_ACCESS_KEY")
if not TODOIST_AGENT_ACCESS_KEY:
    raise ValueError("TODOIST_AGENT_ACCESS_KEY environment variable not set.")


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
        self.transcription = None
        self.todoist_coro = None
        self.audio_buffer = bytearray()
        self.history = []

    async def _send_message(self, message_type: MessageType, message: str):
        print(f"Sending {message_type} message: {message}")
        await self.ws.send_text(json.dumps({"type": message_type, "message": message}))

    async def _send_bytes(self, message_type: MessageType, message: bytes):
        print(f"Sending {message_type} message: {len(message)} bytes.")
        await self.ws.send_bytes(message)

    def fetch_tasks(self):
        self.todoist_coro = self.todoist_manager.get_tasks()

    def add_chunk(self, chunk: bytes):
        self.audio_buffer.extend(chunk)
        print(
            f"Received audio chunk: {len(chunk)} bytes. Total: {len(self.audio_buffer)} bytes."
        )

    async def transcribe(self):
        try:
            self.transcription = await self.groq_manager.transcribe_audio(
                bytes(self.audio_buffer), file_format="opus"
            )
            await self._send_message(MessageType.TRANSCRIPTION, self.transcription)
        except Exception as e:
            error_message = f"Transcription task failed: {e}"
            print(error_message)
            await self._send_message(MessageType.ERROR, error_message)

    async def tasks(self) -> str:
        if self.todoist_coro is None:
            print("Error: todoist_coro is None")
            self.todoist_coro = self.todoist_manager.get_tasks()
        return await self.todoist_coro

    async def exec_flow(self, transcription: str | None = None):
        if transcription is None:
            n_bytes = len(self.audio_buffer)
            print(f"Finished receiving audio: {n_bytes} bytes")
            await self.transcribe()
        else:
            self.transcription = transcription
        if self.transcription is None:
            return
        tasks = await self.tasks()
        code_info = self.todoist_manager.get_code_info()
        code = self.ai_manager.get_code_ai_response(
            tasks, code_info, self.transcription
        )
        await self._send_message(MessageType.CODE, code)
        exec_result = self.code_manager.execute(code)
        answer = self.ai_manager.get_answer_ai_response(tasks, code, exec_result)
        await self._send_message(MessageType.ANSWER, answer)
        audio = self.tts_manager.text_to_speech(answer)
        await self._send_bytes(MessageType.AI_SPEECH, audio)


async def websocket_endpoint(websocket: WebSocket):
    auth_header = websocket.headers.get("X-Agent-Access-Key")
    if auth_header != TODOIST_AGENT_ACCESS_KEY:
        print(
            "WebSocket connection rejected: Invalid or missing X-Agent-Access-Key header."
        )
        await websocket.close(code=status.WS_1008_POLICY_VIOLATION)
        return

    await websocket.accept()
    print(f"Client {websocket.client} connected with valid access key.")
    manager = WebsocketManager(websocket)
    try:
        while True:
            message = await websocket.receive()
            if message.get("text", False):
                data: str = message["text"]
                print(f"Received text message: {data}")
                if data == "INIT":
                    manager.reset()
                if data == "START_AUDIO":
                    manager.fetch_tasks()
                    print("Started receiving audio.")
                    await manager._send_message(
                        MessageType.INFO, "Audio transmission started."
                    )
                elif data == "END_AUDIO":
                    await manager.exec_flow()
                elif data == "ping":
                    await websocket.send_text("pong")
                else:
                    try:
                        json_data: dict[str, str] = json.loads(data)
                        if json_data.get("type") == MessageType.TRANSCRIPTION:
                            manager.fetch_tasks()
                            await manager.exec_flow(json_data["message"])
                    except json.JSONDecodeError:
                        await websocket.send_text("Error: Invalid JSON data.")
                        continue

            elif message.get("bytes", False):
                audio_chunk: bytes = message["bytes"]
                manager.add_chunk(audio_chunk)

    except WebSocketDisconnect:
        print(f"Client {websocket.client} disconnected")
