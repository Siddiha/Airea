# ml-training/fall-detection/utils/motion_features.py

import numpy as np
from scipy.signal import butter, filtfilt

def lowpass_filter(signal, cutoff=5, fs=200, order=4):
    """4th-order Butterworth low-pass filter"""
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return filtfilt(b, a, signal)

def extract_kfall_features(accel_data, gyro_data, label):
    """
    Extract 18 motion features from accelerometer and gyroscope data
    
    Args:
        accel_data: (N, 3) array - [x, y, z] accelerometer
        gyro_data: (N, 3) array - [x, y, z] gyroscope
        label: 1 for fall, 0 for ADL
    
    Returns:
        19-element array (18 features + label)
    """
    try:
        # Apply low-pass filter
        accel_filtered = np.zeros_like(accel_data)
        gyro_filtered = np.zeros_like(gyro_data)
        
        for i in range(3):
            if len(accel_data) > 10:
                accel_filtered[:, i] = lowpass_filter(accel_data[:, i])
                gyro_filtered[:, i] = lowpass_filter(gyro_data[:, i])
            else:
                accel_filtered[:, i] = accel_data[:, i]
                gyro_filtered[:, i] = gyro_data[:, i]
        
        features = []
        
        # Horizontal magnitude (x, z)
        accel_horiz = np.sqrt(accel_filtered[:, 0]**2 + accel_filtered[:, 2]**2)
        features.extend([
            np.mean(accel_horiz),                          # F1
            np.std(accel_horiz),                           # F2
            np.max(accel_horiz),                           # F3
            np.min(accel_horiz),                           # F4
            np.max(accel_horiz) - np.min(accel_horiz),    # F5
        ])
        
        # 3D magnitude
        accel_3d = np.sqrt(np.sum(accel_filtered**2, axis=1))
        features.extend([
            np.mean(accel_3d),                             # F6
            np.std(accel_3d),                              # F7
            np.max(accel_3d),                              # F8
            np.min(accel_3d),                              # F9
        ])
        
        # Gyroscope magnitude
        gyro_mag = np.sqrt(np.sum(gyro_filtered**2, axis=1))
        features.extend([
            np.mean(gyro_mag),                             # F10
            np.std(gyro_mag),                              # F11
            np.max(gyro_mag),                              # F12
            np.min(gyro_mag),                              # F13
        ])
        
        # Time features
        peak_idx = np.argmax(accel_3d)
        features.append(peak_idx / len(accel_3d))         # F14
        
        jerk = np.diff(accel_3d)
        features.extend([
            np.mean(np.abs(jerk)),                         # F15
            np.max(np.abs(jerk)),                          # F16
        ])
        
        # Additional statistics
        features.append(np.std(accel_horiz))               # F17
        features.append(np.var(accel_3d))                  # F18
        
        # Add label
        features.append(label)
        
        return np.array(features)
    
    except Exception as e:
        return None