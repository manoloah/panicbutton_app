import os
import soundfile as sf
import pyloudnorm as pyln

INPUT_DIR   = "input_sounds"
OUTPUT_DIR  = "normalized_sounds"
TARGET_LUFS = -12.0

os.makedirs(OUTPUT_DIR, exist_ok=True)
meter = None

for fname in os.listdir(INPUT_DIR):
    if not fname.lower().endswith((".wav", ".mp3")):
        continue

    in_path = os.path.join(INPUT_DIR,  fname)
    out_name = os.path.splitext(fname)[0] + ".wav"
    out_path = os.path.join(OUTPUT_DIR, out_name)

    data, rate = sf.read(in_path, always_2d=True)
    if meter is None:
        meter = pyln.Meter(rate)

    # measure & normalize loudness
    loudness = meter.integrated_loudness(data)
    normalized = pyln.normalize.loudness(data, loudness, TARGET_LUFS)

    # write 24-bit WAV
    sf.write(out_path, normalized, rate, subtype="PCM_24")
    print(f"{fname}: {loudness:.1f} LUFS → normalized to {TARGET_LUFS} LUFS as {out_name}")

print("✅ All done.")
