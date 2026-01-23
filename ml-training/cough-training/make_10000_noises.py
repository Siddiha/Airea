import os
import librosa
import soundfile as sf

# --- CONFIGURATION ---
NOISE_DIR = './dataset/negative_class' 
TARGET_TOTAL = 10000

def finalize_noise_balance():
    # 1. Identify existing files
    existing_noise = [f for f in os.listdir(NOISE_DIR) if f.endswith(('.wav', '.mp3'))]
    current_count = len(existing_noise)
    needed = TARGET_TOTAL - current_count
    
    print(f"📊 Current Noise: {current_count}")
    print(f"🎯 Need: {needed} more to match your 10k coughs.")

    if needed <= 0:
        print("✅ You already have enough noise samples!")
        return

    # 2. Generate only what is needed
    count = 0
    while count < needed:
        for file_name in existing_noise:
            if count >= needed:
                break
                
            file_path = os.path.join(NOISE_DIR, file_name)
            try:
                # Load the audio
                y, sr = librosa.load(file_path, sr=None)
                
                # Variation: Time Stretch (0.9 is 10% slower)
                # This creates a new 'rhythm' for the noise
                y_stretched = librosa.effects.time_stretch(y, rate=0.9)
                
                output_name = f"final_aug_noise_{count}.wav"
                sf.write(os.path.join(NOISE_DIR, output_name), y_stretched, sr)
                
                count += 1
                if count % 500 == 0:
                    print(f"✅ Created {count}/{needed} additional samples...")

            except Exception as e:
                continue

    print(f"🚀 SUCCESS! Dataset is now perfectly balanced: 10,000 Coughs vs 10,000 Noises.")

if __name__ == "__main__":
    finalize_noise_balance()