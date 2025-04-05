"""
Manages interactions with the Groq API, specifically for audio transcription.
"""

import os
import io
from groq import Groq, AsyncGroq
from dotenv import load_dotenv

# Load environment variables from .env file if it exists
load_dotenv()

class GroqManager:
    """
    Handles audio transcription using the Groq API.
    """
    def __init__(self):
        """
        Initializes the GroqManager with an AsyncGroq client.
        Requires the GROQ_API_KEY environment variable to be set.
        """
        api_key = os.environ.get("GROQ_API_KEY")
        if not api_key:
            raise ValueError("GROQ_API_KEY environment variable not set.")
        self._client = AsyncGroq(api_key=api_key)
        self._transcription_model = "whisper-large-v3"

    async def transcribe_audio(self, audio_bytes: bytes, file_format: str = "wav") -> str:
        print(f"Transcribing {len(audio_bytes)} bytes of audio using Groq ({self._transcription_model})...")
        file_tuple = (f"audio.{file_format}", audio_bytes, f"audio/{file_format}")

        try:
            transcription = await self._client.audio.transcriptions.create(
                model=self._transcription_model,
                file=file_tuple,
            )
            print("Transcription successful.")
            return transcription.text
        except Exception as e:
            print(f"Error during Groq transcription: {e}")
            # Re-raise or handle specific exceptions as needed
            raise

# Example usage (optional, for testing)
async def main():
    # This requires a sample audio file named 'sample.wav' in the same directory
    # and the GROQ_API_KEY environment variable set.
    try:
        with open("sample.wav", "rb") as audio_file:
            audio_data = audio_file.read()

        manager = GroqManager()
        transcript = await manager.transcribe_audio(audio_data, file_format="wav")
        print("\nTranscription:")
        print(transcript)
    except FileNotFoundError:
        print("Error: sample.wav not found. Cannot run example usage.")
    except ValueError as ve:
        print(f"Configuration Error: {ve}")
    except Exception as ex:
        print(f"An unexpected error occurred: {ex}")

if __name__ == "__main__":
    import asyncio
    # To run this example:
    # 1. Make sure you have a 'sample.wav' file.
    # 2. Set the GROQ_API_KEY environment variable (e.g., in a .env file).
    # 3. Run `python -m src.groq_manager` from the `todo_server` directory.
    # asyncio.run(main())
    # Commented out by default to avoid running on import or without setup.
    pass
