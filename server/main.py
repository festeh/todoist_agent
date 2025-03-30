"""
Basic FastAPI server with a health check endpoint and a WebSocket endpoint.
"""

from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.responses import JSONResponse

# Create a FastAPI app instance
app = FastAPI(
    title="My Server",
    description="A simple FastAPI server.",
    version="0.1.0",
)

@app.get("/health", tags=["Health Check"])
async def health_check():
    """
    Health check endpoint. Returns status 'ok'.
    """
    return JSONResponse(content={"status": "ok"})

# Optional: Add a root endpoint for basic info
@app.get("/", tags=["Root"])
async def read_root():
    """
    Root endpoint providing basic server information.
    """
    return {"message": "Server is running"}


@app.websocket("/connect")
async def websocket_endpoint(websocket: WebSocket):
    """
    WebSocket endpoint for real-time communication.
    Accepts connections, handles 'ping' text messages, echoes other text messages,
    and accumulates binary (audio) data chunks framed by 'START_AUDIO' and 'END_AUDIO' messages.
    """
    await websocket.accept()
    audio_buffer = bytearray()
    receiving_audio = False
    try:
        while True:
            message = await websocket.receive()

            if "text" in message:
                data = message["text"]
                if data == "START_AUDIO":
                    if receiving_audio:
                        # Handle error: Already receiving audio
                        await websocket.send_text("Error: Already receiving audio.")
                    else:
                        receiving_audio = True
                        audio_buffer = bytearray() # Reset buffer
                        await websocket.send_text("Ready to receive audio chunks.")
                        print("Started receiving audio.")
                elif data == "END_AUDIO":
                    if receiving_audio:
                        receiving_audio = False
                        # Process the complete audio data
                        print(f"Finished receiving audio: {len(audio_buffer)} bytes")
                        # TODO: Add actual audio processing logic here (save, transcribe, etc.)
                        await websocket.send_text(f"Received {len(audio_buffer)} bytes of audio data.")
                        audio_buffer = bytearray() # Clear buffer after processing
                    else:
                        # Handle error: Received END_AUDIO without START_AUDIO
                        await websocket.send_text("Error: Received END_AUDIO without START_AUDIO.")
                elif data == "ping":
                    if receiving_audio:
                         await websocket.send_text("Error: Cannot process 'ping' while receiving audio.")
                    else:
                        await websocket.send_text("pong")
                else:
                     if receiving_audio:
                         await websocket.send_text("Error: Cannot process other text messages while receiving audio.")
                     else:
                        await websocket.send_text(f"Message text was: {data}")

            elif "bytes" in message:
                if receiving_audio:
                    audio_chunk = message["bytes"]
                    audio_buffer.extend(audio_chunk)
                    print(f"Received audio chunk: {len(audio_chunk)} bytes. Total: {len(audio_buffer)} bytes.")
                    # Optional: Send acknowledgment for each chunk if needed
                    # await websocket.send_text(f"Received chunk: {len(audio_chunk)} bytes")
                else:
                    # Handle error: Received bytes without START_AUDIO
                    await websocket.send_text("Error: Received unexpected binary data. Send 'START_AUDIO' first.")

    except WebSocketDisconnect:
        print(f"Client {websocket.client} disconnected")
        # Clean up if client disconnects mid-stream
        if receiving_audio:
            print("Client disconnected during audio transmission.")
            # Optionally process the incomplete audio_buffer or discard it


# To run the server locally using uvicorn:
# uvicorn server.main:app --reload --port 8000
