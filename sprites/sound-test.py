import numpy as np
import sounddevice as sd

def generate_square_wave(frequency, duration, sample_rate=44100):
    """
    Generate a square wave of a given frequency and duration.
    """
    t = np.linspace(0, duration, int(sample_rate * duration), endpoint=False)
    wave = 0.5 * (1 + np.sign(np.sin(2 * np.pi * frequency * t)))  # Square wave
    return wave

def play_sequence(sequence, sample_rate=44100):
    """
    Play a sequence of (frequency, duration) tuples as square waves.
    """
    audio = np.concatenate([
        generate_square_wave(freq, dur, sample_rate)
        for freq, dur in sequence
    ])
    sd.play(audio, samplerate=sample_rate)
    sd.wait()

# (frequency in Hz, duration in seconds)
sequence = [
    (440, 0.08), 
    (555, 0.08), 
    (660, 0.08), 
]


play_sequence(sequence)