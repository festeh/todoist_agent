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
    Accepts connections and echoes back received text messages.
    """
    await websocket.accept()
    try:
        while True:
            data = await websocket.receive_text()
            if data == "ping":
                await websocket.send_text("pong")
            else:
                await websocket.send_text(f"Message text was: {data}")
    except WebSocketDisconnect:
        print(f"Client {websocket.client} disconnected")


# To run the server locally using uvicorn:
# uvicorn server.main:app --reload --port 8000
