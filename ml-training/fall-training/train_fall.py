import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
from sklearn.model_selection import train_test_split
import os

# ================= CONFIGURATION =================
# Must match your C++ settings EXACTLY
TIME_STEPS = 200    
NUM_FEATURES = 6
EPOCHS = 20         # Increased slightly for better accuracy
BATCH_SIZE = 64
# =================================================

def save_c_header(tflite_model_content, variable_name="fall_model"):
    hex_array = [f"0x{b:02x}" for b in tflite_model_content]
    
    # Calculate size in KB for verification
    size_kb = len(tflite_model_content) / 1024
    print(f"\n[INFO] Generated Model Size: {size_kb:.2f} KB")
    
    if size_kb < 100:
        print("⚠️  WARNING: FILE IS TOO SMALL (<100KB).")
        print("    This likely means it is still QUANTIZED (Hybrid).")
        print("    The ESP32 will REJECT this file.")
    else:
        print("✅  SIZE LOOKS GOOD (>200KB). This is a Float32 model.")

    # Write file
    c_str = f"/* Auto-generated Float32 Model */\n"
    c_str += f"#ifndef {variable_name.upper()}_H\n"
    c_str += f"#define {variable_name.upper()}_H\n\n"
    c_str += f"const unsigned char {variable_name}[] = {{\n  "
    
    # Write hex data in lines of 12
    lines = []
    for i in range(0, len(hex_array), 12):
        lines.append(", ".join(hex_array[i:i+12]))
    c_str += ",\n  ".join(lines)
    
    c_str += f"\n}};\n\n"
    c_str += f"const int {variable_name}_len = {len(tflite_model_content)};\n"
    c_str += f"#endif // {variable_name.upper()}_H\n"
    
    with open(f"{variable_name}.h", "w") as f:
        f.write(c_str)
    print(f"[SUCCESS] Saved to {variable_name}.h")

def create_windows(data, time_steps, step):
    xs, ys = [], []
    for i in range(0, len(data) - time_steps, step):
        v = data.iloc[i:(i + time_steps)].values
        features = v[:, :6] 
        # Label is the 7th column (index 6)
        label = float(max(set(v[:, 6]), key=list(v[:, 6]).count))
        xs.append(features)
        ys.append(label)
    return np.array(xs), np.array(ys).reshape(-1, 1)

# --- 1. LOAD & NORMALIZE DATA ---
print("--- 1. LOADING & NORMALIZING ---")

# UPDATE THESE PATHS IF NEEDED
df_falls = pd.read_csv("processed_data/training_falls.csv")
df_adls = pd.read_csv("processed_data/training_adls.csv")

# Normalization (Matches C++ Code)
# Accel -> Divided by 20 (assuming m/s^2)
# Gyro  -> Divided by 500
for df in [df_falls, df_adls]:
    df['accX'] = df['accX'] / 20.0
    df['accY'] = df['accY'] / 20.0
    df['accZ'] = df['accZ'] / 20.0
    df['gyroX'] = df['gyroX'] / 500.0
    df['gyroY'] = df['gyroY'] / 500.0
    df['gyroZ'] = df['gyroZ'] / 500.0

# Balance classes (Optional but recommended)
if len(df_adls) > len(df_falls) * 2:
    print("Trimming ADL data to balance classes...")
    df_adls = df_adls.sample(n=len(df_falls) * 2, random_state=42)

print(f"Falls: {len(df_falls)} | ADLs: {len(df_adls)}")

# --- 2. CREATE WINDOWS ---
X_falls, y_falls = create_windows(df_falls, TIME_STEPS, 100) # 50% Overlap
X_adls, y_adls = create_windows(df_adls, TIME_STEPS, 100)

X = np.concatenate([X_falls, X_adls])
y = np.concatenate([y_falls, y_adls])

X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)
print(f"Training Input Shape: {X_train.shape}")

# --- 3. BUILD MODEL ---
print("--- 3. TRAINING ---")
model = models.Sequential([
    layers.Input(shape=(TIME_STEPS, NUM_FEATURES)),
    layers.Conv1D(16, 3, activation='relu', padding='same'),
    layers.MaxPooling1D(2),
    layers.Dropout(0.2),
    layers.Conv1D(32, 3, activation='relu', padding='same'),
    layers.MaxPooling1D(2),
    layers.Flatten(),
    layers.Dense(32, activation='relu'),
    layers.Dense(1, activation='sigmoid') # Logistic
])

model.compile(optimizer='adam', loss='binary_crossentropy', metrics=['accuracy'])
model.fit(X_train, y_train, epochs=EPOCHS, batch_size=BATCH_SIZE, validation_data=(X_test, y_test))

# --- 4. CONVERT TO FLOAT32 (CRITICAL STEP) ---
print("\n--- 4. CONVERTING TO TFLITE (FLOAT32) ---")

converter = tf.lite.TFLiteConverter.from_keras_model(model)
# ---------------------------------------------------------
# 🛑 CRITICAL: NO OPTIMIZATIONS ENABLED
# Do NOT uncomment the optimizations line.
# converter.optimizations = [tf.lite.Optimize.DEFAULT]  <-- KEPT OFF
# ---------------------------------------------------------

tflite_model = converter.convert()

# --- 5. SAVE ---
save_c_header(tflite_model, "fall_model")