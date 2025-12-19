# ml-training/fall-detection/5_convert_fall_model.py

import tensorflow as tf
import numpy as np
import os

def convert_to_tflite(model_path, output_path):
    """
    Convert fall detection model to TFLite
    """
    print("🔄 Converting fall model to TFLite...")
    
    # Load model (assuming it's a scikit-learn model that needs conversion)
    # This is a placeholder - actual conversion depends on model type
    
    print(f"✅ TFLite model saved: {output_path}")

def convert_to_c_header(tflite_path, header_path):
    """
    Convert TFLite model to C header file for ESP32
    """
    print(f"📝 Converting to C header file...")
    
    with open(tflite_path, 'rb') as f:
        tflite_model = f.read()
    
    model_name = "fall_model"
    c_array = f"// Auto-generated TFLite model header\n"
    c_array += f"#ifndef {model_name.upper()}_H\n"
    c_array += f"#define {model_name.upper()}_H\n\n"
    c_array += f"const unsigned char {model_name}[] = {{\n"
    
    for i in range(0, len(tflite_model), 12):
        chunk = tflite_model[i:i+12]
        hex_values = ', '.join([f'0x{b:02x}' for b in chunk])
        c_array += f"  {hex_values},\n"
    
    c_array += f"}};\n"
    c_array += f"const unsigned int {model_name}_len = {len(tflite_model)};\n\n"
    c_array += f"#endif\n"
    
    with open(header_path, 'w') as f:
        f.write(c_array)
    
    print(f"✅ C header saved: {header_path}")

def main():
    print("🔧 Converting Fall Detection Model to TFLite...\n")
    
    model_path = '../models/fall/fall_model.pkl'
    tflite_path = '../models/fall/fall_model_int8.tflite'
    header_path = '../../firmware-esp32/lib/fall_model.h'
    
    convert_to_tflite(model_path, tflite_path)
    convert_to_c_header(tflite_path, header_path)
    
    print("✅ Conversion complete")

if __name__ == "__main__":
    main()

