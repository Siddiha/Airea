# ml-training/fall-detection/4_train_fall_model.py

import os
import numpy as np
import joblib
from sklearn.ensemble import RandomForestClassifier
from sklearn.preprocessing import StandardScaler
from sklearn.metrics import accuracy_score, classification_report

def train_fall_model():
    """Train Random Forest model"""
    
    print("="*70)
    print("🤖 Training Fall Detection Model")
    print("="*70)
    print()
    
    processed_dir = '../data/processed'
    
    try:
        X_train = np.load(f'{processed_dir}/X_train.npy')
        y_train = np.load(f'{processed_dir}/y_train.npy')
        X_val = np.load(f'{processed_dir}/X_val.npy')
        y_val = np.load(f'{processed_dir}/y_val.npy')
    except FileNotFoundError:
        print("❌ Dataset files not found!")
        print("   Run: python 3_create_balanced_dataset.py")
        return
    
    print(f"📊 Training data:")
    print(f"   Train: {X_train.shape}")
    print(f"   Val:   {X_val.shape}")
    print()
    
    print("🔧 Standardizing features...")
    scaler = StandardScaler()
    X_train_scaled = scaler.fit_transform(X_train)
    X_val_scaled = scaler.transform(X_val)
    print("   ✅ Complete")
    print()
    
    print("🌲 Training Random Forest...")
    
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
    print("\n   ✅ Training complete!")
    print()
    
    y_train_pred = model.predict(X_train_scaled)
    y_val_pred = model.predict(X_val_scaled)
    
    train_acc = accuracy_score(y_train, y_train_pred)
    val_acc = accuracy_score(y_val, y_val_pred)
    
    print(f"📊 Results:")
    print(f"   Train Accuracy: {train_acc*100:.2f}%")
    print(f"   Val Accuracy:   {val_acc*100:.2f}%")
    print()
    
    print("📋 Classification Report:")
    print(classification_report(y_val, y_val_pred, 
                                target_names=['ADL', 'Fall'],
                                digits=4))
    
    models_dir = '../models/fall'
    os.makedirs(models_dir, exist_ok=True)
    
    joblib.dump(model, f'{models_dir}/fall_model.pkl')
    joblib.dump(scaler, f'{models_dir}/scaler.pkl')
    
    print("="*70)
    print("✅ MODEL TRAINING COMPLETE!")
    print("="*70)
    print()
    print("🎯 Next: python 5_evaluate_fall_model.py")

if __name__ == "__main__":
    train_fall_model()