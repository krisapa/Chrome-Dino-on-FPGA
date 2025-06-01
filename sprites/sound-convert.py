CLOCK_FREQUENCY = 100_000_000  # 100 MHz

# Frequencies of the notes in Hz
note_frequencies = [440, 555, 660]

note_cycles = [round(CLOCK_FREQUENCY / freq) for freq in note_frequencies]

for freq, cycles in zip(note_frequencies, note_cycles):
    print(f"Frequency: {freq} Hz -> Cycles: {cycles}")