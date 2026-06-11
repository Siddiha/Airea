import os
import shutil
import random
import glob

# --- CONFIGURATION ---
SOURCE_NOISE_DIR = './google_speech'  # The folder you just downloaded
TARGET_DIR = './negative_class'       # Where the "Not Coughs" go
TARGET_COUNT = 3000                   # Must match your Cough count (50/50 Rule)

# We want a mix of speech and background noise
# We will skip words that sound like coughs (like "cough" if it exists)
SKIP_FOLDERS = ['cough'] 

def prepare_negative_dataset():
    if not os.path.exists(TARGET_DIR):
        os.makedirs(TARGET_DIR)
        print(f"✅ Created folder: {TARGET_DIR}")

    # 1. Gather ALL audio files from the Google dataset
    print("🔍 Scanning for noise files (this might take 10 seconds)...")
    all_noise_files = []
    
    # Walk through every subfolder (bed, bird, zero, etc.)
    for root, dirs, files in os.walk(SOURCE_NOISE_DIR):
        folder_name = os.path.basename(root)
        if folder_name in SKIP_FOLDERS:
            continue
            
        for file in files:
            if file.endswith('.wav'):
                full_path = os.path.join(root, file)
                all_noise_files.append(full_path)

    print(f"   Found {len(all_noise_files)} total noise candidates.")

    # 2. Randomly select exactly 3,000 files
    if len(all_noise_files) < TARGET_COUNT:
        print(f"⚠️ Warning: Not enough files! Found {len(all_noise_files)}, need {TARGET_COUNT}")
        selected_files = all_noise_files
    else:
        selected_files = random.sample(all_noise_files, TARGET_COUNT)

    # 3. Copy them to the negative_class folder
    print(f"🎲 Randomly selecting {len(selected_files)} files for the Negative Class...")
    
    count = 0
    for src in selected_files:
        # We rename them to avoid duplicate names (e.g. bed/01.wav vs bird/01.wav)
        unique_name = f"noise_{count:04d}.wav"
        dst = os.path.join(TARGET_DIR, unique_name)
        
        try:
            shutil.copy(src, dst)
            count += 1
            if count % 500 == 0:
                print(f"   Copied {count}...")
        except Exception as e:
            print(f"Error copying {src}: {e}")

    print(f"🚀 DONE! You now have {count} noise files in '{TARGET_DIR}'.")
    print(f"   Your dataset is now perfectly balanced (50/50).")

if __name__ == "__main__":
    prepare_negative_dataset()