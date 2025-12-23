import os
import glob
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import matplotlib.pyplot as plt
import sys

# --- CONFIGURATION (HIGH ACCURACY MODE) ---
DATASET_PATH = "dataset"
# 1.5 sec * 16000 = 24000 raw.
# 24000 / 2 (Downsample) = 12000 inputs. <--- CHANGED TO 2 FOR BETTER QUALITY
MODEL_INPUT_LEN = 12000   
EPOCHS = 60
BATCH_SIZE = 32

# --- LOAD DATA ---
print("📂 Loading Data...")
files_neg = glob.glob(os.path.join(DATASET_PATH, "negative_class", "*.wav"))
files_pos = glob.glob(os.path.join(DATASET_PATH, "positive_class", "*.wav"))

# Combine
files = files_neg + files_pos
labels = [0] * len(files_neg) + [1] * len(files_pos)

files = np.array(files)
labels = np.array(labels)

# Shuffle
indices = np.arange(len(files))
np.random.shuffle(indices)
files = files[indices]
labels = labels[indices]

# Split 80/20
split_idx = int(len(files) * 0.8)
train_files, val_files = files[:split_idx], files[split_idx:]
train_labels, val_labels = labels[:split_idx], labels[split_idx:]

print(f"📊 Training on {len(train_files)} samples, Validating on {len(val_files)} samples")

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
    
    # 2. 🔴 SMARTER WINDOWING: Center on the LOUDEST point
    WINDOW_SIZE = 24000 
    
    abs_wav = tf.math.abs(wav)
    # Find the index of the absolute loudest sound
    peak_index = tf.argmax(abs_wav)
    peak_index = tf.cast(peak_index, tf.int32)
    
    # Start the window 12000 samples BEFORE the peak (centering it)
    start_index = peak_index - (WINDOW_SIZE // 2)
    
    # Safety Check: Don't go below 0
    if start_index < 0: 
        start_index = tf.cast(0, tf.int32)

    wav_window = wav[start_index : start_index + WINDOW_SIZE]
    
    # Pad with zeros if the window goes past the end of the file
    required_padding = WINDOW_SIZE - tf.shape(wav_window)[0]
    if required_padding > 0:
        zero_padding = tf.zeros([required_padding], dtype=tf.float32)
        wav_window = tf.concat([wav_window, zero_padding], 0)

    # 3. 🔴 DOWNSAMPLE BY 2 (Better Quality)
    wav_downsampled = wav_window[::2] 
    
    # 4. Noise Augmentation
    noise_level = tf.random.uniform([], minval=0.01, maxval=0.1)
    noise = tf.random.normal(shape=tf.shape(wav_downsampled), mean=0.0, stddev=noise_level, dtype=tf.float32)
    wav_final = wav_downsampled + noise
    
    # Normalize
    wav_final = wav_final / (tf.math.reduce_max(tf.math.abs(wav_final)) + 0.0001)
    wav_final = tf.reshape(wav_final, [MODEL_INPUT_LEN, 1]) 
    return wav_final, label

# Create Datasets
train_ds = tf.data.Dataset.from_tensor_slices((train_files, train_labels))
train_ds = train_ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
train_ds = train_ds.cache().batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

val_ds = tf.data.Dataset.from_tensor_slices((val_files, val_labels))
val_ds = val_ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
val_ds = val_ds.cache().batch(BATCH_SIZE).prefetch(tf.data.AUTOTUNE)

# --- MODEL (BIGGER & DEEPER) ---
print("🏗️ Building 'High Accuracy' Model...")
model = models.Sequential([
    layers.Input(shape=(MODEL_INPUT_LEN, 1)),
    
    # Layer 1
    layers.Conv1D(16, 5, strides=2, activation='relu', padding='same'), 
    layers.MaxPooling1D(4),
    
    # Layer 2 (Doubled filters)
    layers.Conv1D(32, 3, activation='relu', padding='same'),
    layers.MaxPooling1D(4),
    
    # Layer 3 (NEW LAYER for complexity)
    layers.Conv1D(64, 3, activation='relu', padding='same'), 
    layers.MaxPooling1D(4),
    
    layers.GlobalAveragePooling1D(),
    
    # Larger Dense Layer
    layers.Dense(64, activation='relu'),
    layers.Dense(2, activation='softmax')
])

model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

print("🚀 Starting Training...")
history = model.fit(train_ds, validation_data=val_ds, epochs=EPOCHS)

# --- VISUALIZATION ---
print("📈 Plotting Results...")
acc = history.history['accuracy']
val_acc = history.history['val_accuracy']
loss = history.history['loss']
val_loss = history.history['val_loss']
epochs_range = range(len(acc))

plt.figure(figsize=(12, 4))
plt.subplot(1, 2, 1)
plt.plot(epochs_range, acc, label='Training Accuracy')
plt.plot(epochs_range, val_acc, label='Validation Accuracy')
plt.legend(loc='lower right')
plt.title('Training and Validation Accuracy')

plt.subplot(1, 2, 2)
plt.plot(epochs_range, loss, label='Training Loss')
plt.plot(epochs_range, val_loss, label='Validation Loss')
plt.legend(loc='upper right')
plt.title('Training and Validation Loss')

print("⚠️ Close the graph window to continue to file conversion...")
plt.show() 

# --- CONVERT TO TFLITE ---
print("📦 Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
def representative_dataset_gen():
    for data, label in train_ds.take(100):
        yield [data]
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

print(f"✅ SUCCESS! Model Size: {len(tflite_model) / 1024:.2f} KB")