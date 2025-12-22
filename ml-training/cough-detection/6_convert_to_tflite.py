# ml-training/cough-detection/6_convert_to_tflite.py

import tensorflow as tf
import numpy as np
import os

def convert_to_tflite_float32(model_path, output_path):
    """
    Convert Keras model to TFLite (Float32 - no quantization)
    Best accuracy, larger file size
    """
    print("\n🔄 Converting to TFLite (Float32)...")
    
    # Load model
    model = tf.keras.models.load_model(model_path)
    
    # Convert to TFLite
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    tflite_model = converter.convert()
    
    # Save
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    file_size = os.path.getsize(output_path) / 1024  # KB
    print(f"✅ Float32 model saved: {output_path}")
    print(f"   File size: {file_size:.2f} KB")
    
    return file_size

def convert_to_tflite_dynamic_range(model_path, output_path):
    """
    Convert with dynamic range quantization (INT8 weights, Float32 activations)
    Good balance: 4x smaller, minimal accuracy loss
    """
    print("\n🔄 Converting to TFLite (Dynamic Range Quantization)...")
    
    model = tf.keras.models.load_model(model_path)
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    file_size = os.path.getsize(output_path) / 1024
    print(f"✅ Dynamic range model saved: {output_path}")
    print(f"   File size: {file_size:.2f} KB")
    
    return file_size

def convert_to_tflite_int8(model_path, output_path, X_train):
    """
    Convert with full integer quantization (INT8 everything)
    Smallest size, fastest on ESP32, slight accuracy loss
    """
    print("\n🔄 Converting to TFLite (Full INT8 Quantization)...")
    
    model = tf.keras.models.load_model(model_path)
    
    # Representative dataset generator for calibration
    def representative_dataset():
        for i in range(min(100, len(X_train))):
            yield [X_train[i:i+1].astype(np.float32)]
    
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]
    converter.representative_dataset = representative_dataset
    converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
    converter.inference_input_type = tf.int8  # INT8 input
    converter.inference_output_type = tf.int8  # INT8 output
    
    tflite_model = converter.convert()
    
    with open(output_path, 'wb') as f:
        f.write(tflite_model)
    
    file_size = os.path.getsize(output_path) / 1024
    print(f"✅ INT8 model saved: {output_path}")
    print(f"   File size: {file_size:.2f} KB")
    
    return file_size

def evaluate_tflite_model(tflite_path, X_test, y_test, is_quantized=False):
    """
    Test TFLite model accuracy
    """
    print(f"\n🧪 Evaluating TFLite model: {os.path.basename(tflite_path)}")
    
    # Load TFLite model
    interpreter = tf.lite.Interpreter(model_path=tflite_path)
    interpreter.allocate_tensors()
    
    # Get input/output details
    input_details = interpreter.get_input_details()
    output_details = interpreter.get_output_details()
    
    input_scale, input_zero_point = input_details[0].get('quantization', (0, 0))
    output_scale, output_zero_point = output_details[0].get('quantization', (0, 0))
    
    # Run inference on test set
    correct = 0
    for i in range(len(X_test)):
        test_input = X_test[i:i+1].astype(np.float32)
        
        # Quantize input if needed
        if is_quantized and input_scale > 0:
            test_input = test_input / input_scale + input_zero_point
            test_input = test_input.astype(np.int8)
        
        interpreter.set_tensor(input_details[0]['index'], test_input)
        interpreter.invoke()
        output = interpreter.get_tensor(output_details[0]['index'])
        
        # Dequantize output if needed
        if is_quantized and output_scale > 0:
            output = (output.astype(np.float32) - output_zero_point) * output_scale
        
        prediction = 1 if output[0][0] > 0.5 else 0
        if prediction == y_test[i]:
            correct += 1
    
    accuracy = correct / len(X_test)
    print(f"   Accuracy: {accuracy*100:.2f}% ({correct}/{len(X_test)} correct)")
    
    return accuracy

def convert_to_c_header(tflite_path, header_path):
    """
    Convert TFLite model to C header file for ESP32
    """
    print(f"\n📝 Converting to C header file...")
    
    # Read TFLite model
    with open(tflite_path, 'rb') as f:
        tflite_model = f.read()
    
    # Convert to C array
    model_name = os.path.basename(tflite_path).replace('.', '_')
    
    c_array = f"// Auto-generated TFLite model header\n"
    c_array += f"// Model: {os.path.basename(tflite_path)}\n"
    c_array += f"// Size: {len(tflite_model)} bytes\n\n"
    c_array += f"#ifndef {model_name.upper()}_H\n"
    c_array += f"#define {model_name.upper()}_H\n\n"
    c_array += f"const unsigned char {model_name}[] = {{\n"
    
    # Write bytes in rows of 12
    for i in range(0, len(tflite_model), 12):
        chunk = tflite_model[i:i+12]
        hex_values = ', '.join([f'0x{b:02x}' for b in chunk])
        c_array += f"  {hex_values},\n"
    
    c_array += f"}};\n"
    c_array += f"const unsigned int {model_name}_len = {len(tflite_model)};\n\n"
    c_array += f"#endif  // {model_name.upper()}_H\n"
    
    # Save header file
    with open(header_path, 'w') as f:
        f.write(c_array)
    
    print(f"✅ C header saved: {header_path}")
    print(f"   Model size: {len(tflite_model):,} bytes")

def main():
    print("🔧 Starting TensorFlow Lite Conversion...\n")
    
    # Load training data for INT8 calibration
    print("📂 Loading training data for quantization...")
    X_train = np.load('../data/processed/X_train.npy')
    X_test = np.load('../data/processed/X_test.npy')
    y_test = np.load('../data/processed/y_test.npy')
    print(f"✅ Data loaded: Train={X_train.shape}, Test={X_test.shape}")
    
    model_path = '../models/cough/cough_model.h5'
    
    # Create output directory
    os.makedirs('../models/cough', exist_ok=True)
    
    print("\n" + "="*60)
    print("CONVERSION PROCESS")
    print("="*60)
    
    # 1. Float32 conversion
    float32_path = '../models/cough/cough_model_float32.tflite'
    float32_size = convert_to_tflite_float32(model_path, float32_path)
    float32_acc = evaluate_tflite_model(float32_path, X_test, y_test, is_quantized=False)
    
    # 2. Dynamic range quantization
    dynamic_path = '../models/cough/cough_model_dynamic.tflite'
    dynamic_size = convert_to_tflite_dynamic_range(model_path, dynamic_path)
    dynamic_acc = evaluate_tflite_model(dynamic_path, X_test, y_test, is_quantized=False)
    
    # 3. Full INT8 quantization (recommended for ESP32)
    int8_path = '../models/cough/cough_model_int8.tflite'
    int8_size = convert_to_tflite_int8(model_path, int8_path, X_train)
    int8_acc = evaluate_tflite_model(int8_path, X_test, y_test, is_quantized=True)
    
    # Convert INT8 model to C header (for ESP32)
    header_path = '../../firmware-esp32/lib/cough_model.h'
    convert_to_c_header(int8_path, header_path)
    
    # Summary table
    print("\n" + "="*60)
    print("CONVERSION SUMMARY")
    print("="*60)
    print(f"\n{'Model Type':<25} {'Size (KB)':<12} {'Accuracy':<12} {'Compression'}")
    print("-" * 60)
    print(f"{'Float32 (original)':<25} {float32_size:<12.2f} {float32_acc*100:<11.2f}% {'1.00x'}")
    print(f"{'Dynamic Range':<25} {dynamic_size:<12.2f} {dynamic_acc*100:<11.2f}% {float32_size/dynamic_size:.2f}x")
    print(f"{'INT8 (quantized)':<25} {int8_size:<12.2f} {int8_acc*100:<11.2f}% {float32_size/int8_size:.2f}x")
    
    print("\n" + "="*60)
    print("✅ CONVERSION COMPLETE!")
    print("="*60)
    print(f"📁 TFLite models saved to: ml-training/models/cough/")
    print(f"📁 ESP32 header saved to: {header_path}")
    print(f"\n🎯 Recommended for ESP32: {os.path.basename(int8_path)}")
    print(f"   Size: {int8_size:.2f} KB")
    print(f"   Accuracy: {int8_acc*100:.2f}%")

if __name__ == "__main__":
    main()


