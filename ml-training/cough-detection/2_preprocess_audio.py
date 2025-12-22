# ml-training/cough-detection/2_preprocess_audio.py

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

import numpy as np
from utils.mfcc_utils import process_dataset

def main():
    print("🎵 Starting Audio Preprocessing...\n")
    
    # Ensure output directory exists (relative to project root)
    os.makedirs('../../data/processed', exist_ok=True)
    
    # Process cough sounds (label = 1)
    print("1️⃣ Processing COUGH samples...")
    cough_features, cough_labels = process_dataset('../../data/raw/cough/', label=1)
    
    # Process noise sounds (label = 0)
    print("\n2️⃣ Processing NOISE samples...")
    noise_features, noise_labels = process_dataset('../../data/raw/noise/', label=0)
    
    # Balance dataset (50/50 rule from your report)
    min_samples = min(len(cough_features), len(noise_features))
    print(f"\n⚖️  Balancing dataset to {min_samples} samples per class...")
    
    cough_features = cough_features[:min_samples]
    cough_labels = cough_labels[:min_samples]
    noise_features = noise_features[:min_samples]
    noise_labels = noise_labels[:min_samples]
    
    # Save processed features
    print("\n💾 Saving processed features...")
    np.save('../data/processed/cough_features.npy', cough_features)
    np.save('../data/processed/cough_labels.npy', cough_labels)
    np.save('../data/processed/noise_features.npy', noise_features)
    np.save('../data/processed/noise_labels.npy', noise_labels)
    
    print("\n" + "=" * 60)
    print("✅ Preprocessing Complete!")
    print("=" * 60)
    print(f"📊 Cough samples: {len(cough_features)}")
    print(f"📊 Noise samples: {len(noise_features)}")
    
    if len(cough_features) > 0:
        print(f"📐 Feature shape: {cough_features[0].shape}")
    else:
        print("⚠️  Warning: No cough samples processed. Please check data/raw/cough/ folder.")
        print("   Make sure you've downloaded the datasets first:")
        print("   python 1_download_datasets.py")

if __name__ == "__main__":
    main()


