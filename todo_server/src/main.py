from fastapi import FastAPI
from fastapi.responses import JSONResponse
from src.websocket import websocket_endpoint # Import the websocket handler

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


app.websocket("/connect")(websocket_endpoint)
