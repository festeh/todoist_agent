"""
Basic FastAPI server with a health check endpoint.
"""

from fastapi import FastAPI
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

# To run the server locally using uvicorn:
# uvicorn server.main:app --reload --port 8000
