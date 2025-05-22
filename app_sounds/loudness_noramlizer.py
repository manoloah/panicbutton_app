import os
import subprocess
import warnings
import soundfile as sf
import pyloudnorm as pyln
import numpy as np

# Filter out UserWarnings from pyloudnorm
warnings.filterwarnings("ignore", category=UserWarning, module="pyloudnorm")

INPUT_DIR = "input_sounds"
OUTPUT_DIR = "normalized_sounds"
TARGET_LUFS = -12.0
PEAK_LIMIT = 0.95  # Prevent clipping by ensuring peaks don't exceed this value

# Create output directory if it doesn't exist
os.makedirs(OUTPUT_DIR, exist_ok=True)

def convert_to_mp3(wav_path, mp3_path):
    """Convert WAV to MP3 using ffmpeg (must be installed)"""
    try:
        # Check if ffmpeg is available
        subprocess.run(["ffmpeg", "-version"], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        
        # Convert WAV to MP3 (192kbps)
        subprocess.run([
            "ffmpeg", "-y", "-i", wav_path, 
            "-codec:a", "libmp3lame", "-qscale:a", "2", 
            mp3_path
        ], stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=True)
        return True
    except (subprocess.SubprocessError, FileNotFoundError) as e:
        print(f"Error converting to MP3: {e}")
        print("Make sure ffmpeg is installed (brew install ffmpeg)")
        return False

def normalize_and_limit_audio(input_path, output_wav_path, output_mp3_path):
    """Normalize audio file to target LUFS with peak limiting and save as both WAV and MP3."""
    try:
        # Load audio using soundfile
        data, sample_rate = sf.read(input_path, always_2d=True)
        
        # Create meter for loudness measurement
        meter = pyln.Meter(sample_rate)
        
        # Measure original loudness
        original_loudness = meter.integrated_loudness(data)
        
        # Calculate gain needed for normalization
        gain_db = TARGET_LUFS - original_loudness
        gain_linear = 10 ** (gain_db / 20)
        
        # Apply gain and limit peaks in one step to prevent clipping
        max_peak_possible = np.max(np.abs(data)) * gain_linear
        
        if max_peak_possible > PEAK_LIMIT:
            # Scale down the gain to prevent clipping
            gain_linear = gain_linear * (PEAK_LIMIT / max_peak_possible)
            print(f"  Applied peak limiting (gain adjusted to {gain_linear:.3f})")
        
        # Apply the gain
        normalized = data * gain_linear
        
        # Measure the actual resulting loudness
        final_loudness = meter.integrated_loudness(normalized)
        
        # Save as 24-bit WAV
        sf.write(output_wav_path, normalized, sample_rate, subtype="PCM_24")
        
        # Convert to MP3
        mp3_success = convert_to_mp3(output_wav_path, output_mp3_path)
        
        return original_loudness, final_loudness, mp3_success
    except Exception as e:
        print(f"Error processing {input_path}: {e}")
        return None, None, False

# Process all audio files in the input directory
for filename in os.listdir(INPUT_DIR):
    if not filename.lower().endswith((".wav", ".mp3", ".ogg", ".flac")):
        continue
    
    input_path = os.path.join(INPUT_DIR, filename)
    base_name = os.path.splitext(filename)[0]
    output_wav_path = os.path.join(OUTPUT_DIR, f"{base_name}.wav")
    output_mp3_path = os.path.join(OUTPUT_DIR, f"{base_name}.mp3")
    
    print(f"Processing {filename}...")
    
    # Normalize and save in both formats
    original_loudness, final_loudness, mp3_success = normalize_and_limit_audio(
        input_path, output_wav_path, output_mp3_path)
    
    if original_loudness is not None:
        print(f"  {original_loudness:.1f} LUFS → normalized to {final_loudness:.1f} LUFS")
        print(f"  Saved as {base_name}.wav" + (f" and {base_name}.mp3" if mp3_success else ""))

file_count = sum(1 for f in os.listdir(OUTPUT_DIR) if f.endswith((".wav", ".mp3")))
wav_count = sum(1 for f in os.listdir(OUTPUT_DIR) if f.endswith(".wav"))
mp3_count = sum(1 for f in os.listdir(OUTPUT_DIR) if f.endswith(".mp3"))

print(f"\n✅ Processed {wav_count} files to approximately {TARGET_LUFS} LUFS")
print(f"  • {wav_count} WAV files created")
print(f"  • {mp3_count} MP3 files created")
print(f"  • All files in {os.path.abspath(OUTPUT_DIR)}")
