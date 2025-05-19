import os
import requests
import subprocess
from dotenv import load_dotenv, find_dotenv

# Install dependencies: pip install requests python-dotenv
"""
Reference frequencies for sound design:
INHALE: Closest to G♯3 / A♭3 (octave 3), about 40 cents sharp of equal-tempered G♯3 (184.99 Hz). It's a perfect fifth (3:2 ratio) above 136.1 Hz in just intonation.
EXHALE: Closest to C♯3 / D♭3 (octave 3), about 30 cents flat of equal-tempered C♯3 (138.59 Hz). Often called the “Om” tone.
"""

# You can adjust these values:
DEFAULT_DURATION = 10.0         # seconds (min 0.5, max 22) ([elevenlabs.io](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert?utm_source=chatgpt.com))
DEFAULT_PROMPT_INFLUENCE = .30  # between 0 and 1 (0 = freeform, 1 = follows prompt exactly) ([elevenlabs.io](https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert?utm_source=chatgpt.com))


def convert_mp3_to_wav(mp3_path, wav_path):
    """
    Uses ffmpeg CLI to convert an MP3 file to a WAV file.
    """
    cmd = [
        "ffmpeg", "-y",  # overwrite output if exists
        "-i", mp3_path,
        wav_path
    ]
    try:
        subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        print(f"Converted {mp3_path} → {wav_path}")
    except subprocess.CalledProcessError as e:
        print(f"❌ ffmpeg conversion failed for {mp3_path}: {e}")


def main():
    # Load environment variables from .env or env
    load_dotenv(find_dotenv())
    api_key = os.getenv("ELEVENLABS_API_KEY")
    if not api_key:
        raise ValueError("Please set the ELEVENLABS_API_KEY environment variable.")

    # ElevenLabs Sound-Generation endpoint for MP3 output
    api_url = "https://api.elevenlabs.io/v1/sound-generation?output_format=mp3_44100_128"
    headers = {
        "xi-api-key": api_key,
        "Content-Type": "application/json"
    }

    prompts = [
        # Sound design prompts for ElevenLabs API
        # {
        #     "name": "exhale_gong",
        #     "prompt": (
        #         "Soft Tibetan singing-bowl strike tuned precisely to note C♯3, very gentle mallet, "
        #         "2-second silky sustain, warm room tone, no reverb, studio dry."
        #     )
        # },
        # {
        #     "name": "inhale_gong",
        #     "prompt": (
        #         "Soft Tibetan singing-bowl strike tuned precisely to note G♯3, very gentle mallet, "
        #         "2-second silky sustain, warm room tone, no reverb, studio dry."
        #     )
        # # },
        # {
        #     "name": "inhale_gong_v2",
        #     "prompt": (
        #         "Very soft Tibetan singing‐bowl strike tuned to G♯3, "
        #         "felt mallet with ultra-soft attack, 8-second velvet sustain, "
        #         "rich low harmonic resonance, minimal metallic overtones, "
        #         "subtle spa-style room ambience, warm and round tone."
        #     )
        # },
        # {
        #     "name": "exhale_gong_v2",
        #     "prompt": (
        #         "Very soft Tibetan singing‐bowl strike tuned to C♯3, "
        #         "felt mallet with ultra-soft attack, 8-second velvet sustain, "
        #         "rich low harmonic resonance, minimal metallic overtones, "
        #         "subtle spa-style room ambience, warm and round tone."
        #     )
        # },
        # {
        # "name": "inhale_gong_ultrasoft",
        # "prompt": (
        #     "Gentle crystal bowl tap tuned to G♯3 note, soft brushed mallet, immediate plush "
        #     "sustain lasting 6 seconds, whisper-damped edges, **no reverb**, ultra-dry airy warmth, "
        #     "minimal high-frequency content."
        # )
        # },
        # {
        # "name": "exhale_gong_ultrasoft",
        # "prompt": (
        #     "Whisper-soft Tibetan singing-bowl strike tuned to C♯3, felt-wrapped mallet "
        #     "with an ultra-gentle touch, 8-second muffled sustain, damped resonance with muted "
        #     "overtones, **no reverb or room ambience**, warm velvety body, **close-mic dry recording**."
        # )
        # },
        # Add more prompts as needed...
#     {
#         "name": "inhale_synth_swell",
#         "prompt": (
#             "Warm analog synth pad swell tuned exactly to 204.2 Hz (just-intonation G♯3 perfect fifth), "
#             "pure sine-wave core with gentle low-pass filtering, 4-second smooth crescendo from silence "
#             "to full amplitude, soft plush sustain at peak, intimate close-mic dry recording, "
#             "no reverb or room ambience, velvety mellow texture."
#         )
#     },
#     {
#         "name": "exhale_synth_swell",
#         "prompt": (
#             "Warm analog synth pad swell tuned exactly to 136.1 Hz (just-intonation C♯3 Om tone), "
#             "pure sine-wave core with gentle low-pass filtering, immediate full amplitude then "
#             "4-second smooth fade-out decrescendo to silence, soft plush tail, intimate close-mic dry recording, "
#             "no reverb or room ambience, velvety mellow texture."
#         )
#     },
#     {
#         "name": "inhale_american_flute",
#         "prompt": (
#             "Straight-tone American concert flute tuned exactly to 204.2 Hz (just-intonation G♯3), "
#             "close-mic dry recording, **no vibrato**, smooth legato, 4-second gentle crescendo from silence "
#             "into full flute body, airy underlay for breath realism, no reverb or room ambience, soft and calming."
#         )
#     },
#     {
#         "name": "exhale_american_flute",
#         "prompt": (
#             "Straight-tone American concert flute tuned exactly to 136.1 Hz (just-intonation C♯3 Om tone), "
#             "close-mic dry recording, **no vibrato**, smooth legato, start at full tone then 4-second slow "
#             "decrescendo into breath whisper, airy underlay for breath realism, no reverb or room ambience, "
#             "soft and settling."
#         )
#     },
#     {
#   "name": "exhale_smooth_unison_pad",
#   "prompt": (
#     "Ultra-warm analog unison pad tuned exactly to 136.1 Hz (just-intonation C♯3 Om tone), "
#     "8-voice slight-detune under 5 cents for gentle thickness, intimate close-mic dry recording, "
#     "smooth linear 4-second fade-out from full amplitude to silence, minimal high frequencies, "
#     "no reverb, no delay, no chorus or modulation effects, soft low-mid resonance, perfectly natural and calming."
#   )
# },
# {
#   "name": "inhale_smooth_unison_pad",
#   "prompt": (
#     "Ultra-warm analog unison pad tuned exactly to 204.2 Hz (just-intonation G♯3), "
#     "8-voice slight-detune under 5 cents for gentle thickness, intimate close-mic dry recording, "
#     "smooth linear 4-second fade-in from silence to full amplitude, minimal high frequencies, "
#     "no reverb, no delay, no chorus or modulation effects, soft low-mid resonance, perfectly natural and calming."
#   )
# },
    {
        "name": "inhale_violin",
        "prompt": (
            "Soft bowed violin note at G♯3, close-mic dry recording, no vibrato, smooth legato, "
            "4-second gentle crescendo from silence to full tone."
        )
    },
    {
        "name": "exhale_violin",
        "prompt": (
            "Soft bowed violin note at C♯3, close-mic dry recording, no vibrato, smooth legato, "
            "4-second smooth decay from full tone to silence."
        )
    },
    {
  "name": "inhale_violin_precise",
  "prompt": (
    "Soft legato sustain on a solo violin at G♯3 (204.2 Hz). "
    "Play sul-tasto (over the fingerboard) with the bow held very lightly, "
    "straight-tone only—**no vibrato**, **no portamento**—using a slow bow speed "
    "and light bow pressure. Begin at zero volume and apply a **linear 4-second "
    "crescendo** to full tone. Close-mic dry recording, **no reverb**, intimate, warm, and calm."
  )
},
    ]

    for item in prompts:
        payload = {
            "text": item["prompt"],
            "duration_seconds": DEFAULT_DURATION,
            "prompt_influence": DEFAULT_PROMPT_INFLUENCE
        }
        print(f"Requesting '{item['name']}' MP3 with duration {DEFAULT_DURATION}s and influence {DEFAULT_PROMPT_INFLUENCE * 100:.0f}%…")
        resp = requests.post(api_url, json=payload, headers=headers)
        if resp.status_code == 200:
            mp3_filename = f"{item['name']}.mp3"
            with open(mp3_filename, "wb") as f:
                f.write(resp.content)
            print(f"✔ Saved {mp3_filename}")

            # Convert to WAV using ffmpeg
            wav_filename = f"{item['name']}.wav"
            convert_mp3_to_wav(mp3_filename, wav_filename)
        else:
            print(f"‼ Error {resp.status_code} for {item['name']}: {resp.text}")

if __name__ == "__main__":
    main()
