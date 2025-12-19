# ml-training/fall-detection/3_train_fall_model.py

import numpy as np
from sklearn.ensemble import RandomForestClassifier
import joblib
import os

def main():
    print("🚀 Training Fall Detection Model...\n")
    
    # Load features
    X = np.load('../data/processed/fall_features.npy')
    y = np.load('../data/processed/fall_labels.npy')
    
    # Train model (Random Forest for fall detection)
    model = RandomForestClassifier(n_estimators=100, random_state=42)
    model.fit(X, y)
    
    # Save model
    os.makedirs('../models/fall', exist_ok=True)
    joblib.dump(model, '../models/fall/fall_model.pkl')
    
    print("✅ Model trained and saved")

if __name__ == "__main__":
    main()

