# ml-training/fall-detection/6_convert_to_tflite.py

import os
import numpy as np
import joblib
import tensorflow as tf
from tensorflow import keras

def convert_to_tflite():
    """Convert to TFLite INT8"""
    
    print("="*70)
    print("📱 Converting to TensorFlow Lite (INT8)")
    print("="*70)
    print()
    
    models_dir = '../models/fall'
    processed_dir = '../data/processed'
    
    try:
        sklearn_model = joblib.load(f'{models_dir}/fall_model.pkl')
        scaler = joblib.load(f'{models_dir}/scaler.pkl')
        X_train = np.load(f'{processed_dir}/X_train.npy')
    except FileNotFoundError as e:
        print(f"❌ File not found: {e}")
        return
    
    print("✅ Loaded model")
    print()
    
    input_dim = X_train.shape[1]
    
    model = keras.Sequential([
        keras.layers.InputLayer(input_shape=(input_dim,)),
        keras.layers.Dense(64, activation='relu'),
        keras.layers.Dropout(0.3),
        keras.layers.Dense(32, activation='relu'),
        keras.layers.Dropout(0.3),
        keras.layers.Dense(16, activation='relu'),
        keras.layers.Dense(1, activation='sigmoid')
    ])
    
    model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    print("🎓 Training Keras model...")
    X_train_scaled = scaler.transform(X_train)
    y_train_pred = sklearn_model.predict(X_train)
    
    model.fit(X_train_scaled, y_train_pred, epochs=50, batch_size=32, verbose=0)
    print("✅ Complete")
    print()
    
    def representative_dataset():
        for i in range(min(100, len(X_train))):
            yield [X_train_scaled[i:i+1].astype(np.float32)]
    
    print("🔧 Converting to TFLite INT8...")
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8
    
    tflite_model = converter.convert()
    
    print("✅ Complete!")
    print()
    
    tflite_path = f'{models_dir}/fall_model_int8.tflite'
    
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    
    model_size_kb = len(tflite_model) / 1024
    
    print("="*70)
    print("✅ TFLite MODEL READY!")
    print("="*70)
    print()
    print(f"💾 Saved: {tflite_path}")
    print(f"📊 Size: {model_size_kb:.2f} KB")
    print()
    print("🎉 ALL DONE!")

if __name__ == "__main__":
    convert_to_tflite()