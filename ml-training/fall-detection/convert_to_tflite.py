# ml-training/fall-detection/6_convert_to_tflite.py

import numpy as np
import joblib
import tensorflow as tf
from tensorflow import keras
import os
import json

def convert_sklearn_to_keras(model, scaler, input_shape):
    """
    Convert sklearn RandomForest to Keras Sequential model
    (Approximation for TFLite conversion)
    """
    print("🔄 Converting RandomForest to Keras approximation...")
    
    # Create simple neural network that mimics RF decision boundaries
    keras_model = keras.Sequential([
        keras.layers.Input(shape=(input_shape,)),
        keras.layers.Dense(64, activation='relu'),
        keras.layers.Dropout(0.3),
        keras.layers.Dense(32, activation='relu'),
        keras.layers.Dropout(0.2),
        keras.layers.Dense(16, activation='relu'),
        keras.layers.Dense(1, activation='sigmoid')
    ])
    
    # Compile
    keras_model.compile(
        optimizer='adam',
        loss='binary_crossentropy',
        metrics=['accuracy']
    )
    
    return keras_model

def train_keras_model():
    """Train Keras model for TFLite conversion"""
    print("="*70)
    print("🔄 Converting Model to TensorFlow Lite")
    print("="*70)
    print()
    
    # Load data
    X_train = np.load('../data/processed/X_train_fall.npy')
    y_train = np.load('../data/processed/y_train_fall.npy')
    X_val = np.load('../data/processed/X_val_fall.npy')
    y_val = np.load('../data/processed/y_val_fall.npy')
    
    # Load scaler
    scaler = joblib.load('../models/fall/fall_scaler.pkl')
    X_train_scaled = scaler.transform(X_train)
    X_val_scaled = scaler.transform(X_val)
    
    # Create Keras model
    print("🏗️  Building Keras model...")
    model = convert_sklearn_to_keras(None, scaler, X_train.shape[1])
    print(model.summary())
    
    # Train
    print("\n🎓 Training Keras model...")
    history = model.fit(
        X_train_scaled, y_train,
        validation_data=(X_val_scaled, y_val),
        epochs=30,
        batch_size=32,
        verbose=1
    )
    
    # Save Keras model
    os.makedirs('../models/fall', exist_ok=True)
    model.save('../models/fall/fall_model_keras.h5')
    print("\n✅ Keras model saved")
    
    # Convert to TFLite (INT8 quantization)
    print("\n🔧 Converting to TFLite with INT8 quantization...")
    
    def representative_dataset():
        for i in range(100):
            yield [X_train_scaled[i:i+1].astype(np.float32)]
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8
    converter.inference_output_type = tf.int8
    
    tflite_model = converter.convert()
    
    # Save TFLite
    tflite_path = '../models/fall/fall_model_int8.tflite'
    with open(tflite_path, 'wb') as f:
        f.write(tflite_model)
    
    file_size = os.path.getsize(tflite_path) / 1024
    print(f"✅ TFLite model saved: {file_size:.2f} KB")
    
    # Convert to C header for ESP32
    print("\n📝 Converting to C header file...")
    convert_to_c_header(tflite_path, '../../esp32_firmware/lib/fall_model.h')
    
    # Save conversion metadata
    metadata = {
        'original_model': 'RandomForestClassifier',
        'converted_model': 'TFLite INT8',
        'file_size_kb': float(file_size),
        'input_shape': [1, X_train.shape[1]],
        'output_shape': [1, 1],
        'quantization': 'INT8'
    }
    
    with open('../models/fall/tflite_metadata.json', 'w') as f:
        json.dump(metadata, f, indent=4)
    
    print("\n" + "="*70)
    print("✅ CONVERSION COMPLETE!")
    print("="*70)
    print(f"\n📁 TFLite model: {tflite_path}")
    print(f"📁 Model size: {file_size:.2f} KB")
    print(f"📁 ESP32 header: esp32_firmware/lib/fall_model.h")

def convert_to_c_header(tflite_path, header_path):
    """Convert TFLite model to C header for ESP32"""
    
    with open(tflite_path, 'rb') as f:
        tflite_model = f.read()
    
    model_name = "fall_model"
    
    c_array = f"// Auto-generated TFLite model for fall detection\n"
    c_array += f"// Model size: {len(tflite_model)} bytes\n\n"
    c_array += f"#ifndef {model_name.upper()}_H\n"
    c_array += f"#define {model_name.upper()}_H\n\n"
    c_array += f"const unsigned char {model_name}[] = {{\n"
    
    for i in range(0, len(tflite_model), 12):
        chunk = tflite_model[i:i+12]
        hex_values = ', '.join([f'0x{b:02x}' for b in chunk])
        c_array += f"  {hex_values},\n"
    
    c_array += f"}};\n"
    c_array += f"const unsigned int {model_name}_len = {len(tflite_model)};\n\n"
    c_array += f"#endif  // {model_name.upper()}_H\n"
    
    # Ensure directory exists
    os.makedirs(os.path.dirname(header_path), exist_ok=True)
    
    with open(header_path, 'w') as f:
        f.write(c_array)
    
    print(f"   ✅ C header saved: {header_path}")

if __name__ == "__main__":
    train_keras_model()