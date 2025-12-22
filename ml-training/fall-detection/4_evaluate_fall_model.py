# ml-training/fall-detection/5_evaluate_fall_model.py

import numpy as np
import joblib
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os

def plot_confusion_matrix(y_true, y_pred, save_path):
    """Plot and save confusion matrix"""
    cm = confusion_matrix(y_true, y_pred)
    
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues',
                xticklabels=['ADL', 'Fall'],
                yticklabels=['ADL', 'Fall'],
                cbar_kws={'label': 'Count'})
    plt.title('Fall Detection Confusion Matrix', fontsize=16)
    plt.ylabel('True Label', fontsize=12)
    plt.xlabel('Predicted Label', fontsize=12)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    print(f"   ✅ Confusion matrix saved: {save_path}")

def plot_roc_curve(y_true, y_pred_proba, save_path):
    """Plot and save ROC curve"""
    fpr, tpr, _ = roc_curve(y_true, y_pred_proba)
    roc_auc = auc(fpr, tpr)
    
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color='darkorange', lw=2, 
             label=f'ROC curve (AUC = {roc_auc:.3f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Random')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate', fontsize=12)
    plt.ylabel('True Positive Rate (Sensitivity)', fontsize=12)
    plt.title('Receiver Operating Characteristic (ROC)', fontsize=16)
    plt.legend(loc="lower right")
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    print(f"   ✅ ROC curve saved: {save_path}")
    
    return roc_auc

def main():
    print("="*70)
    print("🔬 Evaluating Fall Detection Model")
    print("="*70)
    print()
    
    # Load model and scaler
    try:
        model = joblib.load('../models/fall/fall_model.pkl')
        scaler = joblib.load('../models/fall/fall_scaler.pkl')
        X_test = np.load('../data/processed/X_test_fall.npy')
        y_test = np.load('../data/processed/y_test_fall.npy')
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        print()
        print("Please train the model first:")
        print("   python 4_train_fall_model.py")
        return
    
    print(f"📊 Test data: {X_test.shape}")
    print()
    
    # Standardize
    X_test_scaled = scaler.transform(X_test)
    
    # Predictions
    y_pred = model.predict(X_test_scaled)
    y_pred_proba = model.predict_proba(X_test_scaled)[:, 1]
    
    test_acc = model.score(X_test_scaled, y_test)
    
    print("="*70)
    print("📋 CLASSIFICATION REPORT")
    print("="*70)
    print()
    print(classification_report(y_test, y_pred, 
                                target_names=['ADL', 'Fall'],
                                digits=4))
    
    # Confusion matrix
    os.makedirs('../models/fall', exist_ok=True)
    
    print("\n📊 Generating plots...")
    plot_confusion_matrix(y_test, y_pred, '../models/fall/confusion_matrix.png')
    roc_auc = plot_roc_curve(y_test, y_pred_proba, '../models/fall/roc_curve.png')
    
    # Calculate metrics
    cm = confusion_matrix(y_test, y_pred)
    tn, fp, fn, tp = cm.ravel()
    
    sensitivity = tp / (tp + fn)
    specificity = tn / (tn + fp)
    precision = tp / (tp + fp) if (tp + fp) > 0 else 0
    f1_score = 2 * (precision * sensitivity) / (precision + sensitivity) if (precision + sensitivity) > 0 else 0
    
    metrics = {
        'test_accuracy': float(test_acc),
        'sensitivity_recall': float(sensitivity),
        'specificity': float(specificity),
        'precision': float(precision),
        'f1_score': float(f1_score),
        'roc_auc': float(roc_auc),
        'confusion_matrix': {
            'true_positives': int(tp),
            'true_negatives': int(tn),
            'false_positives': int(fp),
            'false_negatives': int(fn)
        }
    }
    
    with open('../models/fall/evaluation_metrics.json', 'w') as f:
        json.dump(metrics, f, indent=4)
    
    print()
    print("="*70)
    print("✅ EVALUATION RESULTS")
    print("="*70)
    print(f"\n🎯 Test Accuracy: {test_acc*100:.2f}%")
    print(f"🎯 Sensitivity (Recall): {sensitivity*100:.2f}%")
    print(f"🎯 Specificity: {specificity*100:.2f}%")
    print(f"🎯 Precision: {precision*100:.2f}%")
    print(f"🎯 F1-Score: {f1_score:.4f}")
    print(f"🎯 ROC AUC: {roc_auc:.4f}")
    print()
    print("📊 Confusion Matrix:")
    print(f"   True Positives (Falls detected): {tp}")
    print(f"   True Negatives (ADLs correct): {tn}")
    print(f"   False Positives (ADLs as falls): {fp}")
    print(f"   False Negatives (Falls missed): {fn}")
    print()
    print(f"📁 Results saved to: models/fall/")
    print()
    print("🎯 Next step: python 6_convert_to_tflite.py")

if __name__ == "__main__":
    main()