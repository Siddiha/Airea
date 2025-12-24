# ml-training/fall-detection/3_create_balanced_dataset.py

import os
import numpy as np
from sklearn.model_selection import train_test_split

def create_balanced_dataset():
    """Create balanced train/val/test splits"""
    
    print("="*70)
    print("⚖️  Creating Balanced Dataset")
    print("="*70)
    print()
    
    processed_dir = '../data/processed'
    
    try:
        fall_features = np.load(f'{processed_dir}/fall_features.npy')
        fall_labels = np.load(f'{processed_dir}/fall_labels.npy')
        adl_features = np.load(f'{processed_dir}/adl_features.npy')
        adl_labels = np.load(f'{processed_dir}/adl_labels.npy')
    except FileNotFoundError:
        print("❌ Feature files not found!")
        print("   Run: python 2_extract_features.py")
        return
    
    print(f"📊 Loaded data:")
    print(f"   Falls: {len(fall_features)} samples")
    print(f"   ADLs: {len(adl_features)} samples")
    print()
    
    min_samples = min(len(fall_features), len(adl_features))
    print(f"⚖️  Balancing to {min_samples} samples per class")
    
    fall_indices = np.random.choice(len(fall_features), min_samples, replace=False)
    adl_indices = np.random.choice(len(adl_features), min_samples, replace=False)
    
    fall_features_balanced = fall_features[fall_indices]
    fall_labels_balanced = fall_labels[fall_indices]
    adl_features_balanced = adl_features[adl_indices]
    adl_labels_balanced = adl_labels[adl_indices]
    
    X = np.vstack([fall_features_balanced, adl_features_balanced])
    y = np.hstack([fall_labels_balanced, adl_labels_balanced])
    
    print(f"📦 Combined: {X.shape}")
    print(f"   Falls: {np.sum(y == 1)} ({100*np.mean(y == 1):.1f}%)")
    print(f"   ADLs: {np.sum(y == 0)} ({100*np.mean(y == 0):.1f}%)")
    print()
    
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.30, random_state=42, stratify=y
    )
    
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.50, random_state=42, stratify=y_temp
    )
    
    print("📊 Dataset splits:")
    print(f"   Train: {len(X_train)} ({100*len(X_train)/len(X):.1f}%)")
    print(f"   Val:   {len(X_val)} ({100*len(X_val)/len(X):.1f}%)")
    print(f"   Test:  {len(X_test)} ({100*len(X_test)/len(X):.1f}%)")
    print()
    
    np.save(f'{processed_dir}/X_train.npy', X_train)
    np.save(f'{processed_dir}/y_train.npy', y_train)
    np.save(f'{processed_dir}/X_val.npy', X_val)
    np.save(f'{processed_dir}/y_val.npy', y_val)
    np.save(f'{processed_dir}/X_test.npy', X_test)
    np.save(f'{processed_dir}/y_test.npy', y_test)
    
    print("="*70)
    print("✅ BALANCED DATASET CREATED!")
    print("="*70)
    print()
    print("🎯 Next: python 4_train_fall_model.py")

if __name__ == "__main__":
    np.random.seed(42)
    create_balanced_dataset()