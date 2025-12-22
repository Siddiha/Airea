# ml-training/fall-detection/2_extract_features.py

import os
import numpy as np
from tqdm import tqdm
import sys

# Add utils to path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))
from utils.motion_features import extract_sisfall_features

def process_sisfall_dataset():
    """
    Process all SisFall recordings and extract motion features
    """
    print("="*70)
    print("🔧 SisFall Feature Extraction")
    print("="*70)
    print()
    
    # Find SisFall directory
    sisfall_paths = [
        '../data/raw/fall/SisFall',
        '../data/raw/fall/SisFall_dataset',
    ]
    
    sisfall_dir = None
    for path in sisfall_paths:
        if os.path.exists(path):
            sisfall_dir = path
            break
    
    if not sisfall_dir:
        print("❌ SisFall dataset not found!")
        print()
        print("Expected location:")
        for path in sisfall_paths:
            print(f"   {os.path.abspath(path)}")
        print()
        print("Please run: python extract_manual.py")
        return
    
    print(f"✅ Found dataset: {os.path.abspath(sisfall_dir)}\n")
    
    # Collect all recording files
    fall_files = []
    adl_files = []
    
    print("📂 Scanning for recordings...")
    for root, dirs, files in os.walk(sisfall_dir):
        for file in files:
            if file.endswith('.txt'):
                filepath = os.path.join(root, file)
                
                # Falls: D01-D19
                if any(f'D{i:02d}' in file for i in range(1, 20)):
                    fall_files.append(filepath)
                # ADLs: F01-F15
                elif any(f'F{i:02d}' in file for i in range(1, 16)):
                    adl_files.append(filepath)
    
    print(f"✅ Found {len(fall_files)} fall recordings")
    print(f"✅ Found {len(adl_files)} ADL recordings\n")
    
    if len(fall_files) == 0 or len(adl_files) == 0:
        print("❌ No recordings found!")
        print("   Please verify dataset structure")
        return
    
    # Extract features
    fall_features = []
    adl_features = []
    
    print("1️⃣ Processing FALL events...")
    for filepath in tqdm(fall_files, desc="Falls", unit="file"):
        features = extract_sisfall_features(filepath, label=1)
        if features is not None:
            fall_features.append(features)
    
    print(f"\n   Processed: {len(fall_features)} fall events")
    
    print("\n2️⃣ Processing ADL events...")
    for filepath in tqdm(adl_files, desc="ADLs", unit="file"):
        features = extract_sisfall_features(filepath, label=0)
        if features is not None:
            adl_features.append(features)
    
    print(f"\n   Processed: {len(adl_features)} ADL events")
    
    # Convert to numpy
    fall_features = np.array(fall_features)
    adl_features = np.array(adl_features)
    
    # Save
    os.makedirs('../data/processed', exist_ok=True)
    
    print("\n💾 Saving processed features...")
    np.save('../data/processed/fall_features.npy', fall_features[:, :-1])
    np.save('../data/processed/fall_labels.npy', fall_features[:, -1])
    np.save('../data/processed/adl_features.npy', adl_features[:, :-1])
    np.save('../data/processed/adl_labels.npy', adl_features[:, -1])
    
    print("\n" + "="*70)
    print("✅ FEATURE EXTRACTION COMPLETE!")
    print("="*70)
    print(f"\n📦 Fall features: {fall_features.shape}")
    print(f"📦 ADL features: {adl_features.shape}")
    print(f"📐 Feature vector size: {fall_features.shape[1] - 1}")
    print()
    print("🎯 Next step: python 3_create_balanced_dataset.py")

if __name__ == "__main__":
    process_sisfall_dataset()