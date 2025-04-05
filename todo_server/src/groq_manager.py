"""
Manages interactions with the Groq API, specifically for audio transcription.
"""

import os
from groq import AsyncGroq
from dotenv import load_dotenv


_ = load_dotenv()


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
        self._client: AsyncGroq = AsyncGroq(api_key=api_key)
        self._transcription_model: str = "whisper-large-v3"

    async def transcribe_audio(
        self, audio_bytes: bytes, file_format: str = "wav"
    ) -> str:
        print(
            f"Transcribing {len(audio_bytes)} bytes of audio using Groq ({self._transcription_model})..."
        )
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
            raise
