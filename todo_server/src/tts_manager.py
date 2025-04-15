import os
import sys
from typing import final
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
from loguru import logger

_ = load_dotenv()

# Configure Loguru logger for standalone script usage
logger.remove()
logger.add(
    sys.stderr,
    format="{time:YYYY-MM-DD HH:mm:ss.S} | {level: <8} | {name}:{function}:{line} - {message}",
    level="DEBUG"
)


@final
class TTSManager:
    def __init__(self):
        api_key = os.environ.get("ELEVENLABS_API_KEY")
        if not api_key:
            logger.error("ELEVENLABS_API_KEY environment variable not set.")
            raise ValueError("ELEVENLABS_API_KEY environment variable not set.")
        self.client = ElevenLabs(api_key=api_key)

    def text_to_speech(self, text: str):
        logger.info(f"Generating speech for text: '{text[:50]}...'")
        try:
            result = self.client.generate(
                text=text,
                # optimize_streaming_latency=1,
                model="eleven_flash_v2_5",
                output_format="mp3_22050_32",
            )
            audio_bytes = b"".join(result)
            logger.info(f"Generated {len(audio_bytes)} bytes of audio.")
            return audio_bytes
        except Exception as e:
            logger.error(f"Failed to generate audio: {e}")
            return ""


if __name__ == "__main__":
    logger.info("Running TTSManager standalone test.")
    tts_manager = TTSManager()
    test_text = "Это так, да это так, сосать - это талант!"
    try:
        result = tts_manager.text_to_speech(test_text)
        output_path = "/tmp/audio.mp3"
        with open(output_path, "wb") as f:
            f.write(result)
        logger.success(f"Successfully wrote test audio to {output_path}")
    except Exception as e:
        logger.error(f"Standalone test failed: {e}")
