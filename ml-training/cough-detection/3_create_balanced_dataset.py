# ml-training/cough-detection/3_create_balanced_dataset.py

import numpy as np
from sklearn.model_selection import train_test_split

def main():
    print("🔀 Creating balanced dataset with train/val/test split...\n")
    
    # Ensure output directory exists
    import os
    os.makedirs('../data/processed', exist_ok=True)
    
    # Load processed features
    cough_features = np.load('../data/processed/cough_features.npy', allow_pickle=True)
    cough_labels = np.load('../data/processed/cough_labels.npy', allow_pickle=True)
    
    noise_features = np.load('../data/processed/noise_features.npy', allow_pickle=True)
    noise_labels = np.load('../data/processed/noise_labels.npy', allow_pickle=True)
    
    # Combine all data
    X = np.concatenate([cough_features, noise_features])
    y = np.concatenate([cough_labels, noise_labels])
    
    print(f"Total samples: {len(X)}")
    print(f"Feature shape: {X[0].shape}")
    
    # Split: 70% train, 15% validation, 15% test
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.3, random_state=42, stratify=y
    )
    
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, random_state=42, stratify=y_temp
    )
    
    # Convert to proper numpy arrays
    # Shape will be (samples, time_steps, n_mfcc) which is correct for Conv1D
    X_train = np.array([x for x in X_train])
    X_val = np.array([x for x in X_val])
    X_test = np.array([x for x in X_test])
    
    # Save splits
    print("\n💾 Saving train/val/test splits...")
    np.save('../data/processed/X_train.npy', X_train)
    np.save('../data/processed/y_train.npy', y_train)
    np.save('../data/processed/X_val.npy', X_val)
    np.save('../data/processed/y_val.npy', y_val)
    np.save('../data/processed/X_test.npy', X_test)
    np.save('../data/processed/y_test.npy', y_test)
    
    print("\n" + "=" * 60)
    print("✅ Dataset splits created!")
    print("=" * 60)
    print(f"📦 Training samples:   {len(X_train)} (shape: {X_train.shape})")
    print(f"📦 Validation samples: {len(X_val)} (shape: {X_val.shape})")
    print(f"📦 Test samples:       {len(X_test)} (shape: {X_test.shape})")
    
    # Class distribution
    print(f"\n🎯 Class balance:")
    print(f"   Train - Cough: {np.sum(y_train)}, Noise: {len(y_train) - np.sum(y_train)}")
    print(f"   Val   - Cough: {np.sum(y_val)}, Noise: {len(y_val) - np.sum(y_val)}")
    print(f"   Test  - Cough: {np.sum(y_test)}, Noise: {len(y_test) - np.sum(y_test)}")

if __name__ == "__main__":
    main()


