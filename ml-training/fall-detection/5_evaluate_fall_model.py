# ml-training/fall-detection/5_evaluate_fall_model.py

import os
import numpy as np
import joblib
import matplotlib.pyplot as plt
from sklearn.metrics import (
    accuracy_score, precision_score, recall_score, f1_score,
    confusion_matrix, roc_curve, roc_auc_score
)
import seaborn as sns

def evaluate_fall_model():
    """Evaluate model on test set"""
    
    print("="*70)
    print("📊 Fall Detection Model Evaluation")
    print("="*70)
    print()
    
    processed_dir = '../data/processed'
    models_dir = '../models/fall'
    
    try:
        X_test = np.load(f'{processed_dir}/X_test.npy')
        y_test = np.load(f'{processed_dir}/y_test.npy')
        model = joblib.load(f'{models_dir}/fall_model.pkl')
        scaler = joblib.load(f'{models_dir}/scaler.pkl')
    except FileNotFoundError as e:
        print(f"❌ File not found: {e}")
        return
    
    print(f"📊 Test set: {X_test.shape[0]} samples")
    print()
    
    X_test_scaled = scaler.transform(X_test)
    
    y_pred = model.predict(X_test_scaled)
    y_pred_proba = model.predict_proba(X_test_scaled)[:, 1]
    
    accuracy = accuracy_score(y_test, y_pred)
    precision = precision_score(y_test, y_pred)
    recall = recall_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred)
    
    tn, fp, fn, tp = confusion_matrix(y_test, y_pred).ravel()
    specificity = tn / (tn + fp)
    
    roc_auc = roc_auc_score(y_test, y_pred_proba)
    
    print("="*70)
    print("📊 TEST RESULTS")
    print("="*70)
    print()
    print(f"✅ Accuracy:    {accuracy*100:.2f}%")
    print(f"🎯 Precision:   {precision*100:.2f}%")
    print(f"🔍 Sensitivity: {recall*100:.2f}%")
    print(f"🛡️  Specificity: {specificity*100:.2f}%")
    print(f"⚖️  F1-Score:    {f1*100:.2f}%")
    print(f"📈 ROC-AUC:     {roc_auc:.4f}")
    print()
    
    cm = confusion_matrix(y_test, y_pred)
    
    print("🔢 Confusion Matrix:")
    print(f"              Predicted")
    print(f"              ADL   Fall")
    print(f"Actual ADL   {cm[0,0]:4d}  {cm[0,1]:4d}")
    print(f"       Fall  {cm[1,0]:4d}  {cm[1,1]:4d}")
    print()
    
    # Plots
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['ADL', 'Fall'],
                yticklabels=['ADL', 'Fall'])
    plt.title('Confusion Matrix')
    plt.ylabel('Actual')
    plt.xlabel('Predicted')
    plt.tight_layout()
    plt.savefig(f'{models_dir}/confusion_matrix.png', dpi=300)
    print(f"💾 Saved: confusion_matrix.png")
    
    fpr, tpr, _ = roc_curve(y_test, y_pred_proba)
    
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color='darkorange', lw=2, 
             label=f'ROC (AUC = {roc_auc:.4f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate')
    plt.ylabel('True Positive Rate')
    plt.title('ROC Curve')
    plt.legend(loc="lower right")
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(f'{models_dir}/roc_curve.png', dpi=300)
    print(f"💾 Saved: roc_curve.png")
    
    plt.close('all')
    
    print()
    print("="*70)
    print("✅ EVALUATION COMPLETE!")
    print("="*70)
    print()
    print("🎯 Next: python 6_convert_to_tflite.py")

if __name__ == "__main__":
    evaluate_fall_model()