import os
import glob
import numpy as np
import tensorflow as tf
from tensorflow.keras import layers, models
import sys

# --- CONFIGURATION (1.5 SECONDS - SAFE MODE) ---
DATASET_PATH = "dataset"
# 1.5 sec * 16000 = 24000 raw.
# 24000 / 4 (Downsample) = 6000 inputs.
MODEL_INPUT_LEN = 6000   
EPOCHS = 60
BATCH_SIZE = 32

# --- LOAD DATA ---
print("📂 Loading Data...")
files_neg = glob.glob(os.path.join(DATASET_PATH, "negative_class", "*.wav"))
files_pos = glob.glob(os.path.join(DATASET_PATH, "positive_class", "*.wav"))

files = files_neg + files_pos
labels = [0] * len(files_neg) + [1] * len(files_pos)

indices = np.arange(len(files))
np.random.shuffle(indices)
files = np.array(files)[indices]
labels = np.array(labels)[indices]

# --- PREPROCESSING ---
def load_wav_16k_mono(filename):
    file_contents = tf.io.read_file(filename)
    wav, sample_rate = tf.audio.decode_wav(file_contents, desired_channels=1)
    wav = tf.squeeze(wav, axis=-1)
    return wav

def preprocess(file_path, label):
    wav = load_wav_16k_mono(file_path)
    
    # Tinny Mic Sim
    wav_expanded = tf.expand_dims(tf.expand_dims(wav, 0), -1)
    kernel_size = 30 
    kernel = tf.ones([kernel_size, 1, 1]) / kernel_size
    low_freq = tf.nn.conv1d(wav_expanded, kernel, stride=1, padding='SAME')
    low_freq = tf.squeeze(low_freq)
    wav = wav - low_freq
    
    # 🔴 1.5 SECOND WINDOW
    WINDOW_SIZE = 24000 
    
    abs_wav = tf.math.abs(wav)
    mask = tf.cast(abs_wav > 0.05, tf.int32)
    indices = tf.where(mask)
    if tf.shape(indices)[0] > 0:
        start_index = tf.cast(indices[0][0] - 500, tf.int32)
    else:
        start_index = tf.cast((tf.shape(wav)[0] // 2) - (WINDOW_SIZE // 2), tf.int32)
    if start_index < 0: start_index = tf.cast(0, tf.int32)

    wav_window = wav[start_index : start_index + WINDOW_SIZE]
    
    required_padding = WINDOW_SIZE - tf.shape(wav_window)[0]
    if required_padding > 0:
        zero_padding = tf.zeros([required_padding], dtype=tf.float32)
        wav_window = tf.concat([wav_window, zero_padding], 0)

    # 🔴 DOWNSAMPLE BY 4 (The Sunglasses Effect)
    # This blurs the wind noise so the AI ignores it.
    wav_downsampled = wav_window[::4] 
    
    noise_level = tf.random.uniform([], minval=0.01, maxval=0.1)
    noise = tf.random.normal(shape=tf.shape(wav_downsampled), mean=0.0, stddev=noise_level, dtype=tf.float32)
    wav_final = wav_downsampled + noise
    wav_final = wav_final / (tf.math.reduce_max(tf.math.abs(wav_final)) + 0.0001)
    wav_final = tf.reshape(wav_final, [MODEL_INPUT_LEN, 1]) 
    return wav_final, label

ds = tf.data.Dataset.from_tensor_slices((files, labels))
ds = ds.map(preprocess, num_parallel_calls=tf.data.AUTOTUNE)
ds = ds.cache()
ds = ds.batch(BATCH_SIZE)
ds = ds.prefetch(tf.data.AUTOTUNE)

# --- MODEL ---
print("🏗️ Building 'Safe Mode' Model...")
model = models.Sequential([
    layers.Input(shape=(MODEL_INPUT_LEN, 1)),
    layers.Conv1D(8, 5, strides=2, activation='relu', padding='same'), 
    layers.MaxPooling1D(4),
    layers.Conv1D(16, 3, activation='relu', padding='same'),
    layers.MaxPooling1D(4),
    layers.GlobalAveragePooling1D(),
    layers.Dense(32, activation='relu'),
    layers.Dense(2, activation='softmax')
])

model.compile(optimizer='adam', loss='sparse_categorical_crossentropy', metrics=['accuracy'])

# 🔴 REMOVED CLASS WEIGHTS 
# We want the model to rely on the natural imbalance to reject wind.
print("🚀 Starting Training (No Weights)...")
model.fit(ds, epochs=EPOCHS)

# --- CONVERT ---
print("📦 Converting to TFLite...")
converter = tf.lite.TFLiteConverter.from_keras_model(model)
converter.optimizations = [tf.lite.Optimize.DEFAULT]
def representative_dataset_gen():
    for data, label in ds.take(100):
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