# scripts/2_preprocess_audio.py

import librosa
import numpy as np
import os
from tqdm import tqdm
import warnings
warnings.filterwarnings('ignore')

def extract_mfcc(audio_path, sr=16000, n_mfcc=13, max_len=16000):
    """
    Extract MFCC features from audio file
    
    Args:
        audio_path: Path to audio file
        sr: Sample rate (16kHz for ESP32)
        n_mfcc: Number of MFCC coefficients
        max_len: Maximum length (samples) = 1 second at 16kHz
    
    Returns:
        mfcc: numpy array of shape (n_mfcc, time_steps)
    """
    try:
        # Load audio
        y, sr = librosa.load(audio_path, sr=sr, mono=True)
        
        # Pad or trim to exactly 1 second
        if len(y) < max_len:
            y = np.pad(y, (0, max_len - len(y)), mode='constant')
        else:
            y = y[:max_len]
        
        # Extract MFCCs
        mfcc = librosa.feature.mfcc(
            y=y, 
            sr=sr, 
            n_mfcc=n_mfcc,
            n_fft=512,
            hop_length=160  # 10ms hop
        )
        
        # Normalize to zero mean and unit variance
        mfcc = (mfcc - np.mean(mfcc, axis=1, keepdims=True)) / (np.std(mfcc, axis=1, keepdims=True) + 1e-10)
        
        return mfcc.T  # Transpose to (time_steps, n_mfcc)
    
    except Exception as e:
        print(f"❌ Error processing {audio_path}: {e}")
        return None

def process_dataset(input_folder, label, max_samples=None):
    """
    Process all audio files in a folder
    
    Args:
        input_folder: Path to folder with audio files
        label: 1 for cough, 0 for noise
        max_samples: Limit number of samples (for balancing)
    
    Returns:
        features: List of MFCC arrays
        labels: List of labels
    """
    audio_files = [f for f in os.listdir(input_folder) 
                   if f.endswith(('.wav', '.mp3', '.ogg'))]
    
    if max_samples:
        audio_files = audio_files[:max_samples]
    
    features = []
    labels = []
    
    label_name = "COUGH" if label == 1 else "NOISE"
    
    for audio_file in tqdm(audio_files, desc=f"Processing {label_name}"):
        audio_path = os.path.join(input_folder, audio_file)
        mfcc = extract_mfcc(audio_path)
        
        if mfcc is not None:
            features.append(mfcc)
            labels.append(label)
    
    return features, labels

def main():
    print("🎵 Starting Audio Preprocessing...\n")
    
    # Process cough sounds (label = 1)
    print("1️⃣ Processing COUGH samples...")
    cough_features, cough_labels = process_dataset('data/raw/cough/', label=1)
    
    # Process noise sounds (label = 0)
    print("\n2️⃣ Processing NOISE samples...")
    noise_features, noise_labels = process_dataset('data/raw/noise/', label=0)
    
    # Balance dataset (50/50 rule from your report)
    min_samples = min(len(cough_features), len(noise_features))
    print(f"\n⚖️  Balancing dataset to {min_samples} samples per class...")
    
    cough_features = cough_features[:min_samples]
    cough_labels = cough_labels[:min_samples]
    noise_features = noise_features[:min_samples]
    noise_labels = noise_labels[:min_samples]
    
    # Save processed features
    print("\n💾 Saving processed features...")
    np.save('data/processed/cough_features.npy', cough_features)
    np.save('data/processed/cough_labels.npy', cough_labels)
    np.save('data/processed/noise_features.npy', noise_features)
    np.save('data/processed/noise_labels.npy', noise_labels)
    
    print("\n" + "=" * 60)
    print("✅ Preprocessing Complete!")
    print("=" * 60)
    print(f"📊 Cough samples: {len(cough_features)}")
    print(f"📊 Noise samples: {len(noise_features)}")
    print(f"📐 Feature shape: {cough_features[0].shape}")

if __name__ == "__main__":
    main()