import json
import shutil
import os
import glob

# --- CONFIGURATION ---
# We point to the folder containing the thousands of mixed json/wav files
SOURCE_FOLDER = './public_dataset'   
TARGET_FOLDER = './positive_class'   
MIN_CONFIDENCE = 0.85                # Strict filter: Only keep if > 85% sure it's a cough
MAX_FILES_NEEDED = 3000              # Stop after we have enough

def run_sorting_flow():
    # 1. Create destination if missing
    if not os.path.exists(TARGET_FOLDER):
        os.makedirs(TARGET_FOLDER)
        print(f"✅ Created target folder: {TARGET_FOLDER}")

    count = 0
    # 2. Grab all JSON report cards
    json_files = glob.glob(os.path.join(SOURCE_FOLDER, "*.json"))
    print(f"🔍 Found {len(json_files)} files to scan...")

    for json_path in json_files:
        if count >= MAX_FILES_NEEDED:
            print("🎉 Target reached! Stopping.")
            break

        try:
            # 3. Read the JSON Report Card
            with open(json_path, 'r') as f:
                data = json.load(f)
            
            # 4. Check the Score (Convert string "0.98" to float 0.98)
            score = float(data.get('cough_detected', 0))
            
            # 5. DECISION TIME: Is it a good cough?
            if score >= MIN_CONFIDENCE:
                # Find the matching audio file (it has the same name as the json)
                base_name = os.path.splitext(json_path)[0]
                
                # Check for .webm or .wav (Dataset has both)
                if os.path.exists(base_name + ".webm"):
                    src_audio = base_name + ".webm"
                elif os.path.exists(base_name + ".wav"):
                    src_audio = base_name + ".wav"
                else:
                    continue # Skip if audio is missing

                # 6. Copy valid file to the clean folder
                dst_audio = os.path.join(TARGET_FOLDER, os.path.basename(src_audio))
                shutil.copy(src_audio, dst_audio)
                
                count += 1
                if count % 100 == 0:
                    print(f"   [Progress] Collected {count} clean coughs...")

        except Exception as e:
            # Skip corrupt files silently
            continue

    print(f"🚀 DONE! You now have {count} high-quality files in '{TARGET_FOLDER}'.")

if __name__ == "__main__":
    run_sorting_flow()