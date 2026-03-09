from voice.stt import SpeechRecognizer
from voice.tts import Speaker

from runtime.tokenizer import Tokenizer
from model.model import EdgeLLM
from runtime.config import ModelConfig
import torch

class VoiceAssistant:
    def __init__(self):
        self.recognizer = SpeechRecognizer()
        self.speaker = Speaker()
        self.tokenizer = Tokenizer()
        self.model = EdgeLLM(ModelConfig())

    def run(self):
        while True:
            print("Listening... Speak now!")
            try:
                text = self.recognizer.listen()
            except Exception as e:
                print("No microphone detected, using text input.")
                text = input("User (type here): ")

            if not text.strip():
                continue

            print("User:", text)

            tokens = self.tokenizer.encode(text)
            import torch

            input_ids = torch.tensor([tokens], dtype=torch.long)  # important: long
            logits = self.model(input_ids)
            token = logits[0][-1].argmax()
            response = self.tokenizer.decode([int(token)])

            print("AI:", response)
            try:
                self.speaker.speak(response)
            except Exception as e:
                print("TTS error:", e)

if __name__ == "__main__":
    assistant = VoiceAssistant()
    assistant.run()