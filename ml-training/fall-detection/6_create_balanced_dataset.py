import numpy as np
from sklearn.model_selection import train_test_split

def main():
    print("🔀 Creating balanced fall detection dataset...\n")
    
    # Load features
    fall_features = np.load('../data/processed/fall_features.npy')
    fall_labels = np.load('../data/processed/fall_labels.npy')
    adl_features = np.load('../data/processed/adl_features.npy')
    adl_labels = np.load('../data/processed/adl_labels.npy')
    
    print(f"Raw data:")
    print(f"  Falls: {len(fall_features)}")
    print(f"  ADLs: {len(adl_features)}\n")
    
    # Balance dataset (50/50)
    min_samples = min(len(fall_features), len(adl_features))
    print(f"⚖️  Balancing to {min_samples} samples per class...")
    
    fall_features = fall_features[:min_samples]
    fall_labels = fall_labels[:min_samples]
    adl_features = adl_features[:min_samples]
    adl_labels = adl_labels[:min_samples]
    
    # Combine
    X = np.concatenate([fall_features, adl_features])
    y = np.concatenate([fall_labels, adl_labels])
    
    print(f"Total samples: {len(X)}")
    print(f"Feature vector size: {X.shape[1]}\n")
    
    # Split: 70% train, 15% val, 15% test
    X_train, X_temp, y_train, y_temp = train_test_split(
        X, y, test_size=0.3, random_state=42, stratify=y
    )
    
    X_val, X_test, y_val, y_test = train_test_split(
        X_temp, y_temp, test_size=0.5, random_state=42, stratify=y_temp
    )
    
    # Save splits
    print("💾 Saving train/val/test splits...")
    np.save('../data/processed/X_train_fall.npy', X_train)
    np.save('../data/processed/y_train_fall.npy', y_train)
    np.save('../data/processed/X_val_fall.npy', X_val)
    np.save('../data/processed/y_val_fall.npy', y_val)
    np.save('../data/processed/X_test_fall.npy', X_test)
    np.save('../data/processed/y_test_fall.npy', y_test)
    
    print("\n" + "="*60)
    print("✅ Dataset splits created!")
    print("="*60)
    print(f"📦 Training: {len(X_train)} samples")
    print(f"📦 Validation: {len(X_val)} samples")
    print(f"📦 Test: {len(X_test)} samples")
    
    print(f"\n🎯 Class balance:")
    print(f"   Train - Fall: {np.sum(y_train==1)}, ADL: {np.sum(y_train==0)}")
    print(f"   Val   - Fall: {np.sum(y_val==1)}, ADL: {np.sum(y_val==0)}")
    print(f"   Test  - Fall: {np.sum(y_test==1)}, ADL: {np.sum(y_test==0)}")

if __name__ == "__main__":
    main()