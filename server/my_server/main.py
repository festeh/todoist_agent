"""
Basic FastAPI server with a health check endpoint and a WebSocket endpoint.
"""

from fastapi import FastAPI
from fastapi.responses import JSONResponse
from .websocket import websocket_endpoint # Import the websocket handler

# Create a FastAPI app instance
app = FastAPI(
    title="Todoist AI Server",
    description="A server that converts user queries to Todoist tasks.",
    version="0.1.0",
)

@app.get("/healthy", tags=["Health Check"])
async def health_check():
    """
    Health check endpoint. Returns status 'ok'.
    """
    return JSONResponse(content={"status": "ok"})


# Register the WebSocket endpoint using the imported handler
app.websocket("/connect")(websocket_endpoint)


# To run the server locally using uvicorn:
# uvicorn server.main:app --reload --port 8000
