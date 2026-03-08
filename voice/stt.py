#sst - Speech-to-Text module using Vosk
import json
import sounddevice as sd
from vosk import Model, KaldiRecognizer

class SpeechRecognizer:

    def __init__(self):

        self.model = Model("vosk-model-small-en-us-0.15")

    def listen(self):

        rec = KaldiRecognizer(self.model, 16000)

        with sd.RawInputStream(
            samplerate=16000,
            blocksize=8000,
            dtype="int16",
            channels=1
        ) as stream:

            data = stream.read(4000)[0]

            if rec.AcceptWaveform(data):

                result = json.loads(rec.Result())

                return result["text"]