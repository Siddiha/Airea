# ml-training/fall-detection/4_train_fall_model.py

import numpy as np
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
import joblib
import json
import os
from datetime import datetime

def main():
    print("="*70)
    print("🚀 Training Fall Detection Model")
    print("="*70)
    print()
    
    # Load data
    try:
        X_train = np.load('../data/processed/X_train_fall.npy')
        y_train = np.load('../data/processed/y_train_fall.npy')
        X_val = np.load('../data/processed/X_val_fall.npy')
        y_val = np.load('../data/processed/y_val_fall.npy')
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        print()
        print("Please run dataset creation first:")
        print("   python 3_create_balanced_dataset.py")
        return
    
    print(f"📊 Training data: {X_train.shape}")
    print(f"📊 Validation data: {X_val.shape}")
    print()
    
    # Standardize features
    print("🔧 Standardizing features...")
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_val_scaled = scaler.transform(X_val)
    
    # Train Random Forest
    print("\n🌲 Training Random Forest Classifier...")
    print("   Hyperparameters:")
    print("   - n_estimators: 100")
    print("   - max_depth: 15")
    print("   - min_samples_split: 5")
    print("   - min_samples_leaf: 2")
    print()
    
    model = RandomForestClassifier(
        n_estimators=100,
        max_depth=15,
        min_samples_split=5,
        min_samples_leaf=2,
        random_state=42,
        n_jobs=-1,
        verbose=1
    )
    
    model.fit(X_train_scaled, y_train)
    
    # Evaluate
    train_acc = model.score(X_train_scaled, y_train)
    val_acc = model.score(X_val_scaled, y_val)
    
    print(f"\n📈 Training Accuracy: {train_acc*100:.2f}%")
    print(f"📈 Validation Accuracy: {val_acc*100:.2f}%")
    
    # Save model and scaler
    os.makedirs('../models/fall', exist_ok=True)
    
    print("\n💾 Saving model and scaler...")
    joblib.dump(model, '../models/fall/fall_model.pkl')
    joblib.dump(scaler, '../models/fall/fall_scaler.pkl')
    
    # Save metadata
    metadata = {
        'model_type': 'RandomForestClassifier',
        'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'n_features': X_train.shape[1],
        'feature_names': [
            'mean_horiz', 'std_horiz', 'max_horiz', 'min_horiz', 'range_horiz',
            'mean_3d', 'std_3d', 'max_3d', 'min_3d',
            'mean_gyro', 'std_gyro', 'max_gyro', 'min_gyro',
            'peak_timing', 'mean_jerk', 'max_jerk',
            'std_horiz_c8', 'var_3d'
        ],
        'train_samples': len(X_train),
        'val_samples': len(X_val),
        'train_accuracy': float(train_acc),
        'val_accuracy': float(val_acc),
        'hyperparameters': {
            'n_estimators': 100,
            'max_depth': 15,
            'min_samples_split': 5,
            'min_samples_leaf': 2
        }
    }
    
    with open('../models/fall/model_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=4)
    
    # Feature importance
    import matplotlib.pyplot as plt
    
    feature_names = metadata['feature_names']
    importances = model.feature_importances_
    indices = np.argsort(importances)[::-1]
    
    plt.figure(figsize=(10, 6))
    plt.title('Feature Importance - Fall Detection')
    plt.bar(range(len(importances)), importances[indices])
    plt.xticks(range(len(importances)), [feature_names[i] for i in indices], rotation=90)
    plt.tight_layout()
    plt.savefig('../models/fall/feature_importance.png', dpi=150)
    print("   ✅ Feature importance plot saved")
    
    print("\n" + "="*70)
    print("✅ TRAINING COMPLETE!")
    print("="*70)
    print(f"\n📁 Model saved to: models/fall/fall_model.pkl")
    print(f"📁 Scaler saved to: models/fall/fall_scaler.pkl")
    print()
    print("🎯 Next step: python 5_evaluate_fall_model.py")

if __name__ == "__main__":
    main()