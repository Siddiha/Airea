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
history = model.fit(X_train, y_train, epochs=EPOCHS, batch_size=BATCH_SIZE, validation_data=(X_test, y_test))

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

# --- 6. EVALUATION ---
import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, classification_report, roc_curve, auc, precision_recall_curve, average_precision_score

# --- CREATE OUTPUT FOLDER ---
OUTPUT_FOLDER = "evaluation_results"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)
print(f"\n📂 Saving evaluation results to: {OUTPUT_FOLDER}/")

print("\n--- Running Post-Training Evaluation ---")

# 0. Plot Training History (Loss & Accuracy)
plt.figure(figsize=(12, 4))

# Loss Plot
plt.subplot(1, 2, 1)
plt.plot(history.history['loss'], label='Training Loss')
plt.plot(history.history['val_loss'], label='Validation Loss')
plt.title('Model Loss Over Epochs')
plt.xlabel('Epoch')
plt.ylabel('Loss')
plt.legend()
plt.grid(True)

# Accuracy Plot
plt.subplot(1, 2, 2)
plt.plot(history.history['accuracy'], label='Training Accuracy')
plt.plot(history.history['val_accuracy'], label='Validation Accuracy')
plt.title('Model Accuracy Over Epochs')
plt.xlabel('Epoch')
plt.ylabel('Accuracy')
plt.legend()
plt.grid(True)

plt.tight_layout()
plt.savefig(f'{OUTPUT_FOLDER}/training_history.png', dpi=150)
plt.close()
print(f"✅ Saved: {OUTPUT_FOLDER}/training_history.png")

# 1. Get predictions on test set
y_pred_probs = model.predict(X_test).flatten()
y_pred_classes = (y_pred_probs > 0.5).astype(int)
y_true = y_test.flatten().astype(int)

# 2. Print Classification Report (Precision, Recall, F1)
print("\nClassification Report:")
report = classification_report(y_true, y_pred_classes, target_names=['ADL (No Fall)', 'Fall Detected'])
print(report)

# Save classification report to file
with open(f'{OUTPUT_FOLDER}/classification_report.txt', 'w') as f:
    f.write("Classification Report - Fall Detection Model\n")
    f.write("=" * 50 + "\n")
    f.write(report)
print(f"✅ Saved: {OUTPUT_FOLDER}/classification_report.txt")

# 3. Generate Confusion Matrix
cm = confusion_matrix(y_true, y_pred_classes)
plt.figure(figsize=(6, 5))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=['ADL', 'Fall'], yticklabels=['ADL', 'Fall'])
plt.title('Confusion Matrix - Fall Detection')
plt.ylabel('Actual True Label')
plt.xlabel('Model Prediction')
plt.savefig(f'{OUTPUT_FOLDER}/confusion_matrix.png', dpi=150)
plt.close()
print(f"✅ Saved: {OUTPUT_FOLDER}/confusion_matrix.png")

# 4. Generate ROC Curve
fpr, tpr, thresholds = roc_curve(y_true, y_pred_probs)
roc_auc = auc(fpr, tpr)

plt.figure(figsize=(6, 5))
plt.plot(fpr, tpr, color='darkorange', lw=2, label=f'ROC curve (AUC = {roc_auc:.2f})')
plt.plot([0, 1], [0, 1], color='navy', lw=2, linestyle='--')
plt.xlim([0.0, 1.0])
plt.ylim([0.0, 1.05])
plt.xlabel('False Positive Rate')
plt.ylabel('True Positive Rate (Recall)')
plt.title('ROC Curve - Fall Detection')
plt.legend(loc="lower right")
plt.savefig(f'{OUTPUT_FOLDER}/roc_curve.png', dpi=150)
plt.close()
print(f"✅ Saved: {OUTPUT_FOLDER}/roc_curve.png")

# 5. Generate Precision-Recall Curve
precision, recall, pr_thresholds = precision_recall_curve(y_true, y_pred_probs)
avg_precision = average_precision_score(y_true, y_pred_probs)

plt.figure(figsize=(6, 5))
plt.plot(recall, precision, color='green', lw=2, label=f'PR curve (AP = {avg_precision:.2f})')
plt.xlabel('Recall')
plt.ylabel('Precision')
plt.title('Precision-Recall Curve - Fall Detection')
plt.legend(loc="lower left")
plt.grid(True)
plt.savefig(f'{OUTPUT_FOLDER}/precision_recall_curve.png', dpi=150)
plt.close()
print(f"✅ Saved: {OUTPUT_FOLDER}/precision_recall_curve.png")

# 6. Generate Prediction Distribution Histogram
plt.figure(figsize=(8, 5))
plt.hist(y_pred_probs[y_true == 0], bins=50, alpha=0.7, label='ADL (No Fall)', color='blue')
plt.hist(y_pred_probs[y_true == 1], bins=50, alpha=0.7, label='Fall Events', color='red')
plt.xlabel('Predicted Probability')
plt.ylabel('Count')
plt.title('Prediction Probability Distribution')
plt.legend()
plt.grid(True)
plt.savefig(f'{OUTPUT_FOLDER}/prediction_distribution.png', dpi=150)
plt.close()
print(f"✅ Saved: {OUTPUT_FOLDER}/prediction_distribution.png")

print(f"\n✅ All evaluation complete! AUC Score: {roc_auc:.4f} | Avg Precision: {avg_precision:.4f}")
print(f"📂 All results saved to: {OUTPUT_FOLDER}/")