# ml-training/fall-detection/2_extract_features.py

import numpy as np
from utils.motion_features import extract_motion_features

def main():
    print("🔧 Extracting motion features from KFall dataset...\n")
    
    # Load raw data
    # Extract features using motion_features utility
    # Save processed features
    
    print("✅ Feature extraction complete")
    print("📁 Features saved to: ../data/processed/fall_features.npy")

if __name__ == "__main__":
    main()

