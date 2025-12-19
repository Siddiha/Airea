# ml-training/fall-detection/4_evaluate_fall_model.py

import numpy as np
import joblib
from sklearn.metrics import classification_report, confusion_matrix
import json
import os

def main():
    print("🔬 Evaluating Fall Detection Model...\n")
    
    # Load model and test data
    model = joblib.load('../models/fall/fall_model.pkl')
    X_test = np.load('../data/processed/X_test_fall.npy')
    y_test = np.load('../data/processed/y_test_fall.npy')
    
    # Evaluate
    y_pred = model.predict(X_test)
    accuracy = model.score(X_test, y_test)
    
    # Save metrics
    metrics = {
        'accuracy': float(accuracy),
        'classification_report': classification_report(y_test, y_pred, output_dict=True)
    }
    
    with open('../models/fall/evaluation_metrics.json', 'w') as f:
        json.dump(metrics, f, indent=4)
    
    print("✅ Evaluation complete")

if __name__ == "__main__":
    main()

