import os
from pydub import AudioSegment

#source!!!
# https://github.com/mdeff/fma?tab=readme-ov-file
# --- CONFIGURATION ---
FMA_SMALL_PATH = './dataset/fma_small'       # Path to the unzipped fma_small folder
TARGET_NOISE_DIR = './dataset/negative_class'
TARGET_COUNT = 3000                   
SEGMENT_MS = 1000                     # 1 second segments

def process_fma_noise():
    if not os.path.exists(TARGET_NOISE_DIR):
        os.makedirs(TARGET_NOISE_DIR)

    current_count = 0
    
    # FMA small has folders like 000, 001, 002...
    # We walk through them until we hit our target count
    for root, dirs, files in os.walk(FMA_SMALL_PATH):
        for file in files:
            if file.endswith('.mp3'):
                if current_count >= TARGET_COUNT:
                    return

                file_path = os.path.join(root, file)
                try:
                    # FMA files are usually 30 seconds
                    audio = AudioSegment.from_mp3(file_path)
                    
                    # Grab first 10 seconds to get 10 segments per track
                    for i in range(10): 
                        if current_count >= TARGET_COUNT:
                            break
                        
                        start = i * SEGMENT_MS
                        end = start + SEGMENT_MS
                        chunk = audio[start:end]
                        
                        output_name = f"fma_noise_{current_count}.wav"
                        chunk.export(os.path.join(TARGET_NOISE_DIR, output_name), format="wav")
                        current_count += 1
                        
                        if current_count % 100 == 0:
                            print(f"✅ Processed {current_count}/{TARGET_COUNT} samples...")
                            
                except Exception as e:
                    continue # Skip corrupt files

    print(f"🚀 Success! {current_count} noise samples ready in {TARGET_NOISE_DIR}")

if __name__ == "__main__":
    process_fma_noise()