"""
WebSocket endpoint logic for handling real-time communication,
including text messages and chunked audio data transfer.
"""

import json
from typing import final
from fastapi import WebSocket, WebSocketDisconnect
from enum import StrEnum

from src.ai_manager import AiManager
from src.code_manager import CodeManager

from .groq_manager import GroqManager
from .todoist_manager import TodoistManager


class MessageType(StrEnum):
    ERROR = "error"
    INFO = "info"
    TRANSCRIPTION = "transcription"
    CODE = "code"
    ANSWER = "answer"


@final
class WebsocketManager:
    def __init__(self, ws: WebSocket):
        self.groq_manager = GroqManager()
        self.todoist_manager = TodoistManager()
        self.ai_manager = AiManager()
        self.code_manager = CodeManager()
        self.ws = ws

        self.reset()

    def reset(self):
        self.transcription = None
        self.todoist_coro = None
        self.audio_buffer = bytearray()

    async def _send_message(self, message_type: MessageType, message: str):
        await self.ws.send_text(json.dumps({"type": message_type, "message": message}))

    def fetch_tasks(self):
        self.todoist_coro = self.todoist_manager.get_tasks()

    def add_chunk(self, chunk: bytes):
        self.audio_buffer.extend(chunk)
        print(
            f"Received audio chunk: {len(chunk)} bytes. Total: {len(self.audio_buffer)} bytes."
        )

    async def init_flow(self):
        self.reset()
        self.fetch_tasks()
        print("Started receiving audio.")

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
            # await self.ws.send_text(
            #     Info(f"Audio transmission finished. Received {n_bytes} bytes.").to_msg()
            # )
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
        code_coro = self._send_message(MessageType.CODE, code)
        exec_result = self.code_manager.execute(code)
        print("Execution result:", exec_result)
        answer = self.ai_manager.get_answer_ai_response(tasks, code, exec_result)
        await code_coro
        await self._send_message(MessageType.ANSWER, answer)


async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    receiving_audio = False
    manager = WebsocketManager(websocket)
    try:
        while True:
            message = await websocket.receive()
            if message.get("text", False):
                data: str = message["text"]
                print(f"Received text message: {data}")
                if data == "START_AUDIO":
                    await manager.init_flow()
                    receiving_audio = True
                    await manager._send_message(MessageType.INFO, "Audio transmission started.")
                elif data == "END_AUDIO":
                    await manager.exec_flow()
                elif data == "ping":
                    if receiving_audio:
                        await websocket.send_text(
                            "Error: Cannot process 'ping' while receiving audio."
                        )
                    else:
                        await websocket.send_text("pong")
                else:
                    try:
                        json_data: dict[str, str] = json.loads(data)
                        if json_data.get("type") == MessageType.TRANSCRIPTION:
                            await manager.init_flow()
                            await manager.exec_flow(json_data["message"])
                    except json.JSONDecodeError:
                        await websocket.send_text("Error: Invalid JSON data.")
                        continue

            elif message.get("bytes", False):
                audio_chunk: bytes = message["bytes"]
                manager.add_chunk(audio_chunk)

    except WebSocketDisconnect:
        print(f"Client {websocket.client} disconnected")
