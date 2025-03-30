# My Server

A simple FastAPI server implementation.

## Setup

It's recommended to use a virtual environment. This project uses `uv` for dependency management, but you can use `pip` as well.

1.  **Create and activate a virtual environment:**
    ```bash
    python -m venv .venv
    source .venv/bin/activate # On Windows use `.venv\Scripts\activate`
    ```

2.  **Install dependencies using `uv` (recommended) or `pip`:**
    ```bash
    # Using uv
    uv pip install -r requirements.txt # Or install directly from pyproject.toml if uv supports it fully
    # OR using pip
    pip install -r requirements.txt
    # OR install directly
    pip install "fastapi>=0.100.0" "uvicorn[standard]>=0.20.0"
    ```
    *Note: You might need to generate a `requirements.txt` from `pyproject.toml` first if using standard pip workflows.*
    ```bash
    # Example using pip-tools (install it first: pip install pip-tools)
    # pip-compile server/pyproject.toml --output-file server/requirements.txt
    # pip install -r server/requirements.txt
    ```


## Running the Server

To run the development server with auto-reload:

```bash
uvicorn server.main:app --reload --host 0.0.0.0 --port 8000
```

-   `--reload`: Enables auto-reloading when code changes are detected.
-   `--host 0.0.0.0`: Makes the server accessible from other devices on your network.
-   `--port 8000`: Specifies the port to run on.

## Endpoints

-   **`/health`**: Returns `{"status": "ok"}`. Use this to check if the server is running.
-   **`/`**: Returns a simple welcome message.
-   **`/docs`**: Provides interactive API documentation (Swagger UI).
-   **`/redoc`**: Provides alternative API documentation (ReDoc).

## Project Structure

```
.
├── server/
│   ├── main.py         # FastAPI application code
│   ├── pyproject.toml  # Project metadata and dependencies
│   └── README.md       # This file
└── ... (other project files)
```
