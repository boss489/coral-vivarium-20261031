"""Generate an original short two-tone button chime (16-bit mono WAV)."""
import math
import struct
import wave
from pathlib import Path

path = Path(__file__).resolve().parents[1] / 'assets' / 'chime.wav'
with wave.open(str(path), 'wb') as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(22050)
    frames = bytearray()
    for index in range(11025):
        seconds = index / 22050
        envelope = (1 - seconds / 0.5) ** 2 * min(1, seconds * 150)
        signal = (math.sin(2 * math.pi * 660 * seconds) +
                  0.4 * math.sin(2 * math.pi * 990 * seconds)) * 0.32 * envelope
        frames.extend(struct.pack('<h', int(32767 * signal)))
    output.writeframes(frames)
print(path)
