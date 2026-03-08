# sst - Speech-to-Text module using Vosk
import json
import sounddevice as sd
from vosk import Model, KaldiRecognizer

class SpeechRecognizer:

    def __init__(self, model_path="vosk-model-small-en-us-0.15"):
        self.model = Model(model_path)

    def listen(self):
        """
        Listen using microphone if available.
        If no microphone is detected, fall back to text input.
        """
        try:
            # Try using microphone
            rec = KaldiRecognizer(self.model, 16000)
            with sd.RawInputStream(samplerate=16000, blocksize=8000, dtype="int16", channels=1) as stream:
                print("Listening... Speak now!")
                data = stream.read(4000)[0]
                if rec.AcceptWaveform(data):
                    result = json.loads(rec.Result())
                    return result["text"]
        except Exception as e:
            # Microphone not available: fallback to text input
            print("No microphone detected or cannot access audio device:", e)
            return input("Type your input instead: ")