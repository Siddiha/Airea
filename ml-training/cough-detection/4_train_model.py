# ml-training/cough-detection/4_train_model.py

import tensorflow as tf
from tensorflow import keras
import numpy as np
import matplotlib.pyplot as plt
import json
from datetime import datetime
import os

def build_cough_model(input_shape):
    """
    Build 1D-CNN model for cough detection
    Optimized for ESP32 deployment
    """
    model = keras.Sequential([
        # Block 1
        keras.layers.Conv1D(32, kernel_size=3, activation='relu', 
                        padding='same', input_shape=input_shape),
        keras.layers.BatchNormalization(),
        keras.layers.MaxPooling1D(pool_size=2),
        keras.layers.Dropout(0.2),
        
        # Block 2
        keras.layers.Conv1D(64, kernel_size=3, activation='relu', padding='same'),
        keras.layers.BatchNormalization(),
        keras.layers.MaxPooling1D(pool_size=2),
        keras.layers.Dropout(0.3),
        
        # Block 3
        keras.layers.Conv1D(128, kernel_size=3, activation='relu', padding='same'),
        keras.layers.BatchNormalization(),
        keras.layers.GlobalAveragePooling1D(),
        
        # Dense layers
        keras.layers.Dense(64, activation='relu'),
        keras.layers.Dropout(0.4),
        keras.layers.Dense(1, activation='sigmoid')  # Binary: cough vs noise
    ], name='CoughDetectorCNN')
    
    return model

def plot_training_history(history, save_path='../models/cough/training_history.png'):
    """Plot and save training curves"""
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 4))
    
    # Accuracy
    ax1.plot(history.history['accuracy'], label='Train Accuracy')
    ax1.plot(history.history['val_accuracy'], label='Val Accuracy')
    ax1.set_title('Model Accuracy')
    ax1.set_xlabel('Epoch')
    ax1.set_ylabel('Accuracy')
    ax1.legend()
    ax1.grid(True)
    
    # Loss
    ax2.plot(history.history['loss'], label='Train Loss')
    ax2.plot(history.history['val_loss'], label='Val Loss')
    ax2.set_title('Model Loss')
    ax2.set_xlabel('Epoch')
    ax2.set_ylabel('Loss')
    ax2.legend()
    ax2.grid(True)
    
    plt.tight_layout()
    plt.savefig(save_path, dpi=150)
    print(f"📊 Training curves saved to {save_path}")

def main():
    print("🚀 Starting Model Training...\n")
    
    # Ensure output directories exist
    os.makedirs('../../ml-training/models/cough', exist_ok=True)
    
    # Load data
    print("📂 Loading preprocessed data...")
    X_train = np.load('../data/processed/X_train.npy')
    y_train = np.load('../data/processed/y_train.npy')
    X_val = np.load('../data/processed/X_val.npy')
    y_val = np.load('../data/processed/y_val.npy')
    
    print(f"✅ Data loaded:")
    print(f"   Train: {X_train.shape}, Val: {X_val.shape}")
    
    # Build model
    # Input shape: (time_steps, n_mfcc) - Conv1D treats n_mfcc as channels
    input_shape = (X_train.shape[1], X_train.shape[2])  # (time_steps, n_mfcc)
    print(f"\n🏗️  Building model with input shape: {input_shape}")
    
    model = build_cough_model(input_shape)
    model.summary()
    
    # Compile model
    model.compile(
        optimizer=keras.optimizers.Adam(learning_rate=0.001),
        loss='binary_crossentropy',
        metrics=['accuracy', 
                 keras.metrics.Precision(name='precision'),
                 keras.metrics.Recall(name='recall')]
    )
    
    # Callbacks
    callbacks = [
        keras.callbacks.ModelCheckpoint(
            '../models/cough/cough_model.h5',
            monitor='val_accuracy',
            save_best_only=True,
            verbose=1
        ),
        keras.callbacks.EarlyStopping(
            monitor='val_loss',
            patience=10,
            restore_best_weights=True,
            verbose=1
        ),
        keras.callbacks.ReduceLROnPlateau(
            monitor='val_loss',
            factor=0.5,
            patience=5,
            min_lr=1e-7,
            verbose=1
        )
    ]
    
    # Train
    print("\n🎓 Training model...")
    history = model.fit(
        X_train, y_train,
        validation_data=(X_val, y_val),
        epochs=50,
        batch_size=32,
        callbacks=callbacks,
        verbose=1
    )
    
    # Save final model
    print("\n💾 Saving final model...")
    model.save('../models/cough/cough_model.h5')
    
    # Plot training curves
    plot_training_history(history, save_path='../models/cough/training_history.png')
    
    # Save metadata
    metadata = {
        'model_name': 'cough_detector_v1',
        'training_date': datetime.now().strftime('%Y-%m-%d %H:%M:%S'),
        'input_shape': input_shape,
        'total_params': model.count_params(),
        'train_samples': len(X_train),
        'val_samples': len(X_val),
        'final_train_accuracy': float(history.history['accuracy'][-1]),
        'final_val_accuracy': float(history.history['val_accuracy'][-1]),
        'best_val_accuracy': float(max(history.history['val_accuracy']))
    }
    
    with open('../models/cough/model_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=4)
    
    print("\n" + "=" * 60)
    print("✅ Training Complete!")
    print("=" * 60)
    print(f"📈 Final Training Accuracy:   {metadata['final_train_accuracy']:.4f}")
    print(f"📈 Final Validation Accuracy: {metadata['final_val_accuracy']:.4f}")
    print(f"🏆 Best Validation Accuracy:  {metadata['best_val_accuracy']:.4f}")
    print(f"💾 Model saved to: models/cough/cough_model.h5")

if __name__ == "__main__":
    main()


