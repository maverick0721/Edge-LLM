from voice.stt import SpeechRecognizer
from voice.tts import Speaker

from runtime.tokenizer import Tokenizer
from model.model import EdgeLLM
from runtime.config import ModelConfig

class VoiceAssistant:

    def __init__(self):

        self.recognizer = SpeechRecognizer()

        self.speaker = Speaker()

        self.tokenizer = Tokenizer()

        self.model = EdgeLLM(ModelConfig())

    def run(self):

        while True:

            print("Listening...")

            text = self.recognizer.listen()

            print("User:", text)

            tokens = self.tokenizer.encode(text)

            import torch

            input_ids = torch.tensor([tokens])

            logits = self.model(input_ids)

            token = logits[0][-1].argmax()

            response = self.tokenizer.decode([int(token)])

            print("AI:", response)

            self.speaker.speak(response)