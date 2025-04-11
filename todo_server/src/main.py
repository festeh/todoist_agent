import os
from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.responses import JSONResponse
from src.websocket import websocket_endpoint  # Import the websocket handler

# Load environment variables from .env file
_ = load_dotenv()

# Load and validate the agent access key
TODOIST_AGENT_ACCESS_KEY = os.getenv("TODOIST_AGENT_ACCESS_KEY")
if not TODOIST_AGENT_ACCESS_KEY:
    raise ValueError("TODOIST_AGENT_ACCESS_KEY environment variable not set.")


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

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000)
