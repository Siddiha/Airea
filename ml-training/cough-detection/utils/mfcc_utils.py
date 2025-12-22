# ml-training/cough-detection/utils/mfcc_utils.py

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
        mfcc: numpy array of shape (time_steps, n_mfcc)
    """
    try:
        # Load audio - librosa handles .webm, .ogg, .wav, .mp3
        y, sr = librosa.load(audio_path, sr=sr, mono=True, duration=None)
        
        # Skip if audio is too short (less than 0.1 seconds)
        if len(y) < sr * 0.1:
            return None
        
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
        # Silently skip problematic files
        return None

def process_dataset(input_folder, label, max_samples=None):
    """
    Process all audio files in a folder (including subdirectories)
    
    Args:
        input_folder: Path to folder with audio files
        label: 1 for cough, 0 for noise
        max_samples: Limit number of samples (for balancing)
    
    Returns:
        features: List of MFCC arrays
        labels: List of labels
    """
    audio_files = []
    
    # Search in folder and subdirectories
    for root, dirs, files in os.walk(input_folder):
        for file in files:
            if file.endswith(('.wav', '.mp3', '.ogg', '.webm')):
                audio_files.append(os.path.join(root, file))
    
    if max_samples:
        audio_files = audio_files[:max_samples]
    
    features = []
    labels = []
    
    label_name = "COUGH" if label == 1 else "NOISE"
    
    if len(audio_files) == 0:
        print(f"⚠️  Warning: No audio files found in {input_folder}")
        return features, labels
    
    for audio_path in tqdm(audio_files, desc=f"Processing {label_name}"):
        mfcc = extract_mfcc(audio_path)
        
        if mfcc is not None:
            features.append(mfcc)
            labels.append(label)
    
    return features, labels

def extract_mfcc_features(audio_samples, sample_rate=16000, n_mfcc=13, n_fft=512, hop_length=160):
    """
    Extract MFCC features from raw audio samples (for ESP32 compatibility)
    
    Args:
        audio_samples: numpy array of audio samples (1 second = 16000 samples at 16kHz)
        sample_rate: Sample rate in Hz (default: 16000)
        n_mfcc: Number of MFCC coefficients (default: 13)
        n_fft: FFT window size (default: 512)
        hop_length: Hop length in samples (default: 160 = 10ms)
    
    Returns:
        mfcc: numpy array of shape (time_steps, n_mfcc)
    """
    # Ensure audio is exactly 1 second
    max_len = sample_rate
    if len(audio_samples) < max_len:
        audio_samples = np.pad(audio_samples, (0, max_len - len(audio_samples)), mode='constant')
    else:
        audio_samples = audio_samples[:max_len]
    
    # For ESP32 compatibility, this would use a lightweight MFCC implementation
    # For training, we use librosa
    # This is a placeholder for the ESP32 C++ implementation
    
    return audio_samples  # Placeholder


