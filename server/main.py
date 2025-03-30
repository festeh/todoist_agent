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
    and acknowledges received binary (audio) data.
    """
    await websocket.accept()
    try:
        while True:
            message = await websocket.receive()
            if "text" in message:
                data = message["text"]
                if data == "ping":
                    await websocket.send_text("pong")
                else:
                    await websocket.send_text(f"Message text was: {data}")
            elif "bytes" in message:
                audio_data = message["bytes"]
                # Process audio data here (e.g., save to file, transcribe, etc.)
                # For now, just acknowledge receipt and log the size.
                print(f"Received audio data: {len(audio_data)} bytes")
                await websocket.send_text(f"Received {len(audio_data)} bytes of audio data.")

    except WebSocketDisconnect:
        print(f"Client {websocket.client} disconnected")


# To run the server locally using uvicorn:
# uvicorn server.main:app --reload --port 8000
