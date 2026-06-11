import os
import glob
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import sys

# --- CONFIGURATION (S3 ULTIMATE EDITION) ---
DATASET_PATH = "dataset"

# 2.0 Seconds * 16000 Hz = 32000 Raw Samples
# Downsample by 2 = 16000 Inputs (High Quality)
MODEL_INPUT_LEN = 16000   
EPOCHS = 60
BATCH_SIZE = 64

print(f"TRAINING MODE: ESP32-S3 N16R8 (High Fidelity - {MODEL_INPUT_LEN} inputs)")

# --- LOAD DATA ---
print("Loading Data...")
files_neg = glob.glob(os.path.join(DATASET_PATH, "negative_class", "*.wav"))
files_pos = glob.glob(os.path.join(DATASET_PATH, "cough_dataset", "*.wav"))

files = files_neg + files_pos
labels = [0] * len(files_neg) + [1] * len(files_pos)

# Initial shuffle of file list
indices = np.arange(len(files))
np.random.shuffle(indices)
files = np.array(files)[indices]
labels = np.array(labels)[indices]

if len(files) == 0:
    print("Error: No files found!")
    sys.exit()

# --- PREPROCESSING ---
def load_wav_16k_mono(filename):
    file_contents = tf.io.read_file(filename)
    wav, sample_rate = tf.audio.decode_wav(file_contents, desired_channels=1)
    wav = tf.squeeze(wav, axis=-1)
    return wav

def preprocess(file_path, label):
    wav = load_wav_16k_mono(file_path)
    
    # 1. Tinny Mic Sim (High Pass Filter)
    wav_expanded = tf.expand_dims(tf.expand_dims(wav, 0), -1)
    kernel_size = 30 
    kernel = tf.ones([kernel_size, 1, 1]) / kernel_size
    low_freq = tf.nn.conv1d(wav_expanded, kernel, stride=1, padding='SAME')
    low_freq = tf.squeeze(low_freq)
    wav = wav - low_freq
    
    # 2. 2-SECOND WINDOW (Full Duration)
    WINDOW_SIZE = 32000 
    
    abs_wav = tf.math.abs(wav)
    mask = tf.cast(abs_wav > 0.05, tf.int32)
    indices = tf.where(mask)
    
    if tf.shape(indices)[0] > 0:
        # [IMPROVEMENT APPLIED]: Increased look-back from 500 to 1600 (0.1s)
        # This ensures we don't cut off the very start of the cough sound
        start_index = tf.cast(indices[0][0] - 1600, tf.int32)
    else:
        # If no sound, center the window
        start_index = tf.cast((tf.shape(wav)[0] // 2) - (WINDOW_SIZE // 2), tf.int32)

    if start_index < 0: start_index = tf.cast(0, tf.int32)

    wav_window = wav[start_index : start_index + WINDOW_SIZE]
    
    required_padding = WINDOW_SIZE - tf.shape(wav_window)[0]
    if required_padding > 0:
        zero_padding = tf.zeros([required_padding], dtype=tf.float32)
        wav_window = tf.concat([wav_window, zero_padding], 0)

    # 3. HIGH QUALITY DOWNSAMPLE (Only by 2)
    wav_downsampled = wav_window[::2] 
    
    # Noise & Norm
    noise_level = tf.random.uniform([], minval=0.01, maxval=0.1)
    noise = tf.random.normal(shape=tf.shape(wav_downsampled), mean=0.0, stddev=noise_level, dtype=tf.float32)
    wav_final = wav_downsampled + noise
    
    # Normalization (Crucial for INT8 model stability)
    wav_final = wav_final / (tf.math.reduce_max(tf.math.abs(wav_final)) + 0.0001)
    wav_final = tf.reshape(wav_final, [MODEL_INPUT_LEN, 1]) 
    return wav_final, label

# --- DATASET PIPELINE (FIXED) ---
ds = tf.data.Dataset.from_tensor_slices((files, labels))
ds = ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
ds = ds.cache()
ds = ds.shuffle(buffer_size=1000) # Added shuffle buffer for better training distribution

# [CRITICAL FIX]: Manual Train/Validation Split
# tf.data.Dataset doesn't support 'validation_split' argument in fit()
total_count = len(files)
val_size = int(total_count * 0.2)
train_size = total_count - val_size

train_ds = ds.skip(val_size).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)
val_ds = ds.take(val_size).batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

print(f"📊 Dataset Ready: {train_size} Training samples | {val_size} Validation samples")

# --- MODEL (S3 POWER) ---
print("🏗️ Building 'S3 Ultimate' Model...")
model = models.Sequential([
    layers.Input(shape=(MODEL_INPUT_LEN, 1)),
    
    # First Block
    layers.Conv1D(8, 5, strides=2, activation='relu', padding='same'), 
    layers.MaxPooling1D(4),
    
    # Second Block
    layers.Conv1D(16, 3, activation='relu', padding='same'),
    layers.MaxPooling1D(4),
    
    # Feature Aggregation
    layers.GlobalAveragePooling1D(),
    
    # Classifier
    layers.Dense(32, activation='relu'),
    layers.Dense(2, activation='softmax')
])

model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

# Weights Logic
total_files = len(files)
total_pos = len(files_pos)
total_neg = len(files_neg)
weight_for_0 = (1 / total_neg) * (total_files / 2.0)
weight_for_1 = (1 / total_pos) * (total_files / 2.0)
class_weight = {0: weight_for_0, 1: weight_for_1}

print("Starting Training...")

# [CRITICAL FIX]: Usage of validation_data instead of validation_split
history = model.fit(
    train_ds, 
    validation_data=val_ds, 
    epochs=EPOCHS, 
    class_weight=class_weight
)

# --- CONVERT ---
print("Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]

def representative_dataset_gen():
    # Take 100 samples from train_ds for calibration
    # Note: train_ds is already batched, so we unbatch slightly or iterate batch-by-batch
    for batch_data, batch_labels in train_ds.take(5): 
        # Iterate through the batch to feed single inputs
        for i in range(tf.shape(batch_data)[0]):
            yield [tf.expand_dims(batch_data[i], 0)]

converter.representative_dataset = representative_dataset_gen
converter.target_spec.supported_ops = [tf.lite.OpsSet.TFLITE_BUILTINS_INT8]
converter.inference_input_type = tf.int8
converter.inference_output_type = tf.int8
tflite_model = converter.convert()

with open("model.h", "w") as f:
    f.write("const unsigned char model_data[] = {\n")
    for i, byte in enumerate(tflite_model):
        f.write(f"0x{byte:02x}, ")
        if (i + 1) % 12 == 0:
            f.write("\n")
    f.write("\n};\n")
    f.write(f"const int model_data_len = {len(tflite_model)};")

print(f"SUCCESS! S3 Model Size: {len(tflite_model) / 1024:.2f} KB")


import matplotlib.pyplot as plt
import seaborn as sns
from sklearn.metrics import confusion_matrix, classification_report, roc_curve, auc, precision_recall_curve, average_precision_score

# --- CREATE OUTPUT FOLDER ---
OUTPUT_FOLDER = "evaluation_results"
os.makedirs(OUTPUT_FOLDER, exist_ok=True)
print(f"\n📂 Saving evaluation results to: {OUTPUT_FOLDER}/")

# --- POST-TRAINING EVALUATION ---
print("\n--- Running Post-Training Tests ---")

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

# 1. Extract data from validation dataset
y_true = []
y_pred_probs = []

for batch_data, batch_labels in val_ds:
    predictions = model.predict(batch_data, verbose=0)
    y_pred_probs.extend(predictions[:, 1])  # Probability of class 1 (cough)
    y_true.extend(batch_labels.numpy())

y_true = np.array(y_true)
y_pred_probs = np.array(y_pred_probs)

# Convert probabilities to binary classes (0.5 threshold)
y_pred_classes = (y_pred_probs > 0.5).astype(int)

# 2. Print Classification Report (Precision, Recall, F1)
print("\nClassification Report:")
report = classification_report(y_true, y_pred_classes, target_names=['Negative/ADL', 'Positive/Event'])
print(report)

# Save classification report to file
with open(f'{OUTPUT_FOLDER}/classification_report.txt', 'w') as f:
    f.write("Classification Report\n")
    f.write("=" * 50 + "\n")
    f.write(report)
print(f"✅ Saved: {OUTPUT_FOLDER}/classification_report.txt")

# 3. Generate Confusion Matrix
cm = confusion_matrix(y_true, y_pred_classes)
plt.figure(figsize=(6, 5))
sns.heatmap(cm, annot=True, fmt='d', cmap='Blues', xticklabels=['Negative', 'Positive'], yticklabels=['Negative', 'Positive'])
plt.title('Confusion Matrix')
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
plt.title('Receiver Operating Characteristic (ROC)')
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
plt.title('Precision-Recall Curve')
plt.legend(loc="lower left")
plt.grid(True)
plt.savefig(f'{OUTPUT_FOLDER}/precision_recall_curve.png', dpi=150)
plt.close()
print(f"✅ Saved: {OUTPUT_FOLDER}/precision_recall_curve.png")

# 6. Generate Prediction Distribution Histogram
plt.figure(figsize=(8, 5))
plt.hist(y_pred_probs[y_true == 0], bins=50, alpha=0.7, label='Negative Class', color='blue')
plt.hist(y_pred_probs[y_true == 1], bins=50, alpha=0.7, label='Positive Class (Cough)', color='red')
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