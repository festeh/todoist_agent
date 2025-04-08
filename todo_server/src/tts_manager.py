from dotenv import load_dotenv
import os

_ = load_dotenv()


class TTSManager:
    def __init__(self):
        api_key = os.environ.get("ELEVENLABS_API_KEY")
        if not api_key:
            raise ValueError("ELEVENLABS_API_KEY environment variable not set.")

    def text_to_speech(self, text):
        pass
