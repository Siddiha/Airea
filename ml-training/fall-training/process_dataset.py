import os
import pandas as pd
import glob
import math

# ================= CONFIGURATION =================
# If your folders are inside "IMU-Dataset", change this to "./IMU-Dataset"
# Based on your error log, it looks like they are inside "IMU-Dataset"
DATASET_ROOT = "./IMU-Dataset" 
OUTPUT_FOLDER = "processed_data"

# EXACT COLUMN NAMES
COLUMN_MAPPING = {
    'sternum Acceleration X (m/s^2)': 'accX',
    'sternum Acceleration Y (m/s^2)': 'accY',
    'sternum Acceleration Z (m/s^2)': 'accZ',
    'sternum Angular Velocity X (rad/s)': 'gyroX',
    'sternum Angular Velocity Y (rad/s)': 'gyroY',
    'sternum Angular Velocity Z (rad/s)': 'gyroZ'
}
# =================================================

def process_category(category_folder, label_value):
    all_data = []
    
    # Search path
    search_path = os.path.join(DATASET_ROOT, "sub*", category_folder, "*.xlsx")
    files = glob.glob(search_path)
    
    print(f"Found {len(files)} files for {category_folder}...")

    for file_path in files:
        # --- FIX: SKIP TEMPORARY FILES ---
        filename = os.path.basename(file_path)
        if filename.startswith("~$"):
            continue # Skip this ghost file
        # ---------------------------------

        try:
            # Read Excel file
            df = pd.read_excel(file_path, engine='openpyxl')
            
            # Check columns
            available_cols = [c for c in COLUMN_MAPPING.keys() if c in df.columns]
            
            if len(available_cols) < 6:
                # Silent skip for cleaner logs
                continue

            # Extract and Rename
            df = df[available_cols]
            df = df.rename(columns=COLUMN_MAPPING)
            
            # Unit Conversion (Rad/s -> Deg/s)
            df['gyroX'] = df['gyroX'] * 57.2958
            df['gyroY'] = df['gyroY'] * 57.2958
            df['gyroZ'] = df['gyroZ'] * 57.2958
            
            # Add Label
            df['label'] = label_value
            
            all_data.append(df)
            
            # Print progress every 50 files so you know it's working
            if len(all_data) % 50 == 0:
                print(f"Processed {len(all_data)} files...")
            
        except Exception as e:
            print(f"Error reading {filename}: {e}")

    if all_data:
        return pd.concat(all_data, ignore_index=True)
    return pd.DataFrame()

if __name__ == "__main__":
    if not os.path.exists(OUTPUT_FOLDER):
        os.makedirs(OUTPUT_FOLDER)

    print("--- PROCESSING FALLS (Label 1) ---")
    df_falls = process_category("Falls", 1)
    if not df_falls.empty:
        df_falls.to_csv(os.path.join(OUTPUT_FOLDER, "training_falls.csv"), index=False)
        print(f"SUCCESS: Saved {len(df_falls)} rows to training_falls.csv")

    print("\n--- PROCESSING ADLs (Label 0) ---")
    df_adls = process_category("ADLs", 0)
    if not df_adls.empty:
        df_adls.to_csv(os.path.join(OUTPUT_FOLDER, "training_adls.csv"), index=False)
        print(f"SUCCESS: Saved {len(df_adls)} rows to training_adls.csv")