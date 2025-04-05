"""
Tests for the GroqManager class.
"""

import os
import pytest
from pathlib import Path
import asyncio

from todo_server.src.groq_manager import GroqManager

# Path to the test audio file
ASSETS_DIR = Path(__file__).parent.parent / "assets"
TEST_AUDIO_FILE = ASSETS_DIR / "recording.wav"

@pytest.mark.asyncio
async def test_audio_transcription():
    """
    Test that the GroqManager correctly transcribes the test audio file.
    The test audio file should contain the phrase "Hello World".
    """
    # Skip test if GROQ_API_KEY is not set
    if not os.environ.get("GROQ_API_KEY"):
        pytest.skip("GROQ_API_KEY environment variable not set")
    
    # Skip test if the test audio file doesn't exist
    if not TEST_AUDIO_FILE.exists():
        pytest.skip(f"Test audio file not found: {TEST_AUDIO_FILE}")
    
    # Read the test audio file
    with open(TEST_AUDIO_FILE, "rb") as audio_file:
        audio_data = audio_file.read()
    
    # Initialize the GroqManager and transcribe the audio
    manager = GroqManager()
    transcript = await manager.transcribe_audio(audio_data, file_format="wav")
    
    # Check that the transcription contains "Hello World"
    # Using a case-insensitive comparison and allowing for some flexibility
    assert "hello world" in transcript.lower(), f"Expected 'Hello World' in transcript, got: {transcript}"
