from typing import final
from dotenv import load_dotenv
from elevenlabs.client import ElevenLabs
import os

_ = load_dotenv()


@final
class TTSManager:
    def __init__(self):
        api_key = os.environ.get("ELEVENLABS_API_KEY")
        if not api_key:
            raise ValueError("ELEVENLABS_API_KEY environment variable not set.")
        self.client = ElevenLabs(api_key=api_key)

    def text_to_speech(self, text: str):
        result = self.client.generate(
            text=text,
            # optimize_streaming_latency=1,
            model="eleven_flash_v2_5",
            output_format="mp3_22050_32",
        )
        return result


if __name__ == "__main__":
    tts_manager = TTSManager()
    result = tts_manager.text_to_speech("Это так, да это так, сосать - это талант!")
    audio_bytes = b"".join(result)
    with open("/tmp/audio.mp3", "wb") as f:
        f.write(audio_bytes)
