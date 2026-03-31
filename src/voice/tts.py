import threading

try:
    import pyttsx3
except ImportError as exc:
    raise RuntimeError(
        "Voice support requires optional dependencies. "
        "Install with `pip install -r requirements.txt`."
    ) from exc

class Speaker:
    def __init__(self):
        self.engine = pyttsx3.init()
        self.engine.setProperty('rate', 150)      
        self.engine.setProperty('volume', 1.0)     
        voices = self.engine.getProperty('voices')
        self.engine.setProperty('voice', voices[0].id)  

    def _speak(self, text):
        self.engine.say(text)
        self.engine.runAndWait()

    def speak(self, text):
        threading.Thread(target=self._speak, args=(text,), daemon=True).start()
