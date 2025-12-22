# ml-training/cough-detection/5_evaluate_model.py

import numpy as np
import tensorflow as tf
from tensorflow import keras
from sklearn.metrics import classification_report, confusion_matrix, roc_curve, auc
import matplotlib.pyplot as plt
import seaborn as sns
import json
import os

def plot_confusion_matrix(y_true, y_pred, save_path='../models/cough/confusion_matrix.png'):
    """Plot and save confusion matrix"""
    cm = confusion_matrix(y_true, y_pred)
    
    plt.figure(figsize=(8, 6))
    sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', 
                xticklabels=['Noise', 'Cough'],
                yticklabels=['Noise', 'Cough'])
    plt.title('Confusion Matrix', fontsize=16)
    plt.ylabel('True Label', fontsize=12)
    plt.xlabel('Predicted Label', fontsize=12)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    print(f"📊 Confusion matrix saved to {save_path}")

def plot_roc_curve(y_true, y_pred_proba, save_path='../models/cough/roc_curve.png'):
    """Plot and save ROC curve"""
    fpr, tpr, thresholds = roc_curve(y_true, y_pred_proba)
    roc_auc = auc(fpr, tpr)
    
    plt.figure(figsize=(8, 6))
    plt.plot(fpr, tpr, color='darkorange', lw=2, 
             label=f'ROC curve (AUC = {roc_auc:.2f})')
    plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--', label='Random Guess')
    plt.xlim([0.0, 1.0])
    plt.ylim([0.0, 1.05])
    plt.xlabel('False Positive Rate', fontsize=12)
    plt.ylabel('True Positive Rate', fontsize=12)
    plt.title('Receiver Operating Characteristic (ROC) Curve', fontsize=16)
    plt.legend(loc="lower right")
    plt.grid(alpha=0.3)
    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    print(f"📈 ROC curve saved to {save_path}")
    
    return roc_auc

def evaluate_model_performance(model, X_test, y_test):
    """Comprehensive model evaluation"""
    
    print("\n" + "="*60)
    print("🧪 MODEL EVALUATION ON TEST SET")
    print("="*60)
    
    # Get predictions
    y_pred_proba = model.predict(X_test, verbose=0).flatten()
    y_pred = (y_pred_proba > 0.5).astype(int)
    
    # Overall metrics
    eval_results = model.evaluate(X_test, y_test, verbose=0)
    test_loss = eval_results[0]
    test_acc = eval_results[1]
    
    # If precision and recall are available
    if len(eval_results) > 2:
        test_precision = eval_results[2]
        test_recall = eval_results[3]
    
    print(f"\n📊 Overall Performance:")
    print(f"   Test Loss:     {test_loss:.4f}")
    print(f"   Test Accuracy: {test_acc:.4f} ({test_acc*100:.2f}%)")
    if len(eval_results) > 2:
        print(f"   Test Precision: {test_precision:.4f} ({test_precision*100:.2f}%)")
        print(f"   Test Recall:    {test_recall:.4f} ({test_recall*100:.2f}%)")
    
    # Detailed classification report
    print(f"\n📋 Detailed Classification Report:")
    print(classification_report(y_test, y_pred, 
                                target_names=['Noise', 'Cough'],
                                digits=4))
    
    # Plot confusion matrix
    plot_confusion_matrix(y_test, y_pred)
    
    # Plot ROC curve
    roc_auc = plot_roc_curve(y_test, y_pred_proba)
    
    # Calculate additional metrics
    cm = confusion_matrix(y_test, y_pred)
    tn, fp, fn, tp = cm.ravel()
    
    specificity = tn / (tn + fp)
    sensitivity = tp / (tp + fn)  # Same as recall
    false_positive_rate = fp / (fp + tn)
    false_negative_rate = fn / (fn + tp)
    
    print(f"\n🎯 Additional Metrics:")
    print(f"   True Positives:  {tp}")
    print(f"   True Negatives:  {tn}")
    print(f"   False Positives: {fp}")
    print(f"   False Negatives: {fn}")
    print(f"   Sensitivity (Recall):    {sensitivity:.4f}")
    print(f"   Specificity:             {specificity:.4f}")
    print(f"   False Positive Rate:     {false_positive_rate:.4f}")
    print(f"   False Negative Rate:     {false_negative_rate:.4f}")
    print(f"   ROC AUC Score:           {roc_auc:.4f}")
    
    # Save evaluation metrics
    eval_metrics = {
        'test_loss': float(test_loss),
        'test_accuracy': float(test_acc),
        'sensitivity': float(sensitivity),
        'specificity': float(specificity),
        'false_positive_rate': float(false_positive_rate),
        'false_negative_rate': float(false_negative_rate),
        'roc_auc': float(roc_auc),
        'confusion_matrix': {
            'true_positives': int(tp),
            'true_negatives': int(tn),
            'false_positives': int(fp),
            'false_negatives': int(fn)
        }
    }
    
    with open('../models/cough/evaluation_metrics.json', 'w') as f:
        json.dump(eval_metrics, f, indent=4)
    
    print(f"\n💾 Evaluation metrics saved to models/cough/evaluation_metrics.json")
    
    return eval_metrics

def test_inference_speed(model, X_test):
    """Test model inference speed"""
    import time
    
    print("\n" + "="*60)
    print("⚡ INFERENCE SPEED TEST")
    print("="*60)
    
    # Single sample inference (like ESP32 will do)
    single_sample = X_test[0:1]
    
    # Warm up
    for _ in range(10):
        model.predict(single_sample, verbose=0)
    
    # Measure time
    num_iterations = 100
    start_time = time.time()
    for _ in range(num_iterations):
        model.predict(single_sample, verbose=0)
    end_time = time.time()
    
    avg_time = (end_time - start_time) / num_iterations
    
    print(f"\n⏱️  Average Inference Time (Single Sample):")
    print(f"   {avg_time*1000:.2f} ms per prediction")
    print(f"   {1/avg_time:.2f} predictions per second")
    
    # Batch inference
    start_time = time.time()
    model.predict(X_test, verbose=0)
    end_time = time.time()
    
    batch_time = (end_time - start_time) / len(X_test)
    
    print(f"\n📦 Batch Inference Time:")
    print(f"   {batch_time*1000:.2f} ms per sample (in batch of {len(X_test)})")
    
    return avg_time

def main():
    print("🔬 Starting Model Evaluation...\n")
    
    # Ensure output directory exists
    os.makedirs('../../ml-training/models/cough', exist_ok=True)
    
    # Load test data
    print("📂 Loading test data...")
    X_test = np.load('../data/processed/X_test.npy')
    y_test = np.load('../data/processed/y_test.npy')
    print(f"✅ Test data loaded: {X_test.shape}")
    
    # Load trained model
    print("\n📥 Loading trained model...")
    model = keras.models.load_model('../models/cough/cough_model.h5')
    print(f"✅ Model loaded: {model.count_params():,} parameters")
    
    # Evaluate performance
    eval_metrics = evaluate_model_performance(model, X_test, y_test)
    
    # Test inference speed
    inference_time = test_inference_speed(model, X_test)
    
    print("\n" + "="*60)
    print("✅ EVALUATION COMPLETE!")
    print("=" * 60)
    print(f"📊 Test Accuracy: {eval_metrics['test_accuracy']*100:.2f}%")
    print(f"🎯 ROC AUC Score: {eval_metrics['roc_auc']:.4f}")
    print(f"⚡ Inference Time: {inference_time*1000:.2f} ms")
    print(f"\n📁 Results saved to models/cough/")

if __name__ == "__main__":
    main()


