"""
WebSocket endpoint logic for handling real-time communication,
including text messages and chunked audio data transfer.
"""

from dataclasses import dataclass
import json
from typing import Union
from fastapi import WebSocket, WebSocketDisconnect
import asyncio

from .groq_manager import GroqManager
from .todoist_manager import TodoistManager


@dataclass
class Error:
    desc: str

    def to_msg(self):
        return json.dumps({"type": "error", "message": self.desc})


@dataclass
class Info:
    desc: str

    def to_msg(self):
        return json.dumps({"type": "info", "message": self.desc})


@dataclass
class Asr:
    desc: str

    def to_msg(self):
        return json.dumps({"type": "asr", "message": self.desc})


async def audio_finished(
    websocket: WebSocket,
    audio_buffer: bytearray,
    groq_manager: GroqManager,
    todoist_coro: asyncio.Task[str],
):
    print(f"Finished receiving audio: {len(audio_buffer)} bytes")
    await websocket.send_text(
        Info(
            "Audio transmission finished. Received {} bytes.".format(len(audio_buffer))
        ).to_msg()
    )
    transcription: str | None = None
    try:
        transcription = await groq_manager.transcribe_audio(
            bytes(audio_buffer), file_format="opus"
        )
        await websocket.send_text(Asr(transcription).to_msg())
    except Exception as e:
        error_message = f"Transcription failed: {e}"
        print(error_message)
        await websocket.send_text(Error(error_message).to_msg())

    if transcription is None:
        return

    tasks = await todoist_coro


async def websocket_endpoint(websocket: WebSocket):
    await websocket.accept()
    audio_buffer = bytearray()
    receiving_audio = False
    groq_manager = GroqManager()
    transcription = None

    todoist_manager = TodoistManager()
    todoist_coro = None
    try:
        while True:
            message = await websocket.receive()
            if message.get("text", False):
                data: str = message["text"]
                print(f"Received text message: {data}")
                if data == "START_AUDIO":
                    todoist_coro = todoist_manager.get_tasks()
                    audio_buffer = bytearray()
                    await websocket.send_text(
                        Info("Audio transmission started.").to_msg()
                    )
                    print("Started receiving audio.")
                elif data == "END_AUDIO":
                    await audio_finished(
                        websocket, audio_buffer, groq_manager, todoist_coro
                    )

                    # cleanup
                    audio_buffer = bytearray()
                    todoist_coro = None
                    transcription = None
                elif data == "ping":
                    if receiving_audio:
                        await websocket.send_text(
                            "Error: Cannot process 'ping' while receiving audio."
                        )
                    else:
                        await websocket.send_text("pong")

            elif message.get("bytes", False):
                audio_chunk: bytes = message["bytes"]
                audio_buffer.extend(audio_chunk)
                print(
                    f"Received audio chunk: {len(audio_chunk)} bytes. Total: {len(audio_buffer)} bytes."
                )

    except WebSocketDisconnect:
        print(f"Client {websocket.client} disconnected")
