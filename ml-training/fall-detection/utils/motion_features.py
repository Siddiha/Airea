import numpy as np
import pandas as pd
from scipy.signal import butter, filtfilt

def lowpass_filter(signal, cutoff=5, fs=200, order=4):
    """
    4th-order Butterworth low-pass filter
    As specified in SisFall paper and your project report
    """
    nyq = 0.5 * fs
    normal_cutoff = cutoff / nyq
    b, a = butter(order, normal_cutoff, btype='low', analog=False)
    return filtfilt(b, a, signal)

def extract_sisfall_features(filepath, label):
    """
    Extract motion features from SisFall .txt file
    
    SisFall columns:
    0-2: ADXL345 (x, y, z) - accelerometer ±16g
    3-5: MMA8451Q (x, y, z) - accelerometer ±8g  
    6-8: ITG3200 (x, y, z) - gyroscope ±2000°/s
    
    Sampling rate: 200 Hz
    """
    try:
        # Load SisFall recording
        data = pd.read_csv(filepath, header=None,
                          names=['ADXL345_x', 'ADXL345_y', 'ADXL345_z',
                                'MMA8451Q_x', 'MMA8451Q_y', 'MMA8451Q_z',
                                'ITG3200_x', 'ITG3200_y', 'ITG3200_z'])
        
        # Apply low-pass filter to all channels
        for col in data.columns:
            data[col] = lowpass_filter(data[col].values)
        
        features = []
        
        # === Feature Set 1: Horizontal Plane Magnitude (C2 from report) ===
        # Using ADXL345 (primary accelerometer)
        accel_horizontal = np.sqrt(data['ADXL345_x']**2 + data['ADXL345_z']**2)
        
        features.extend([
            np.mean(accel_horizontal),
            np.std(accel_horizontal),
            np.max(accel_horizontal),
            np.min(accel_horizontal),
            np.max(accel_horizontal) - np.min(accel_horizontal),  # Range
        ])
        
        # === Feature Set 2: 3D Acceleration Magnitude ===
        accel_3d = np.sqrt(data['ADXL345_x']**2 + 
                          data['ADXL345_y']**2 + 
                          data['ADXL345_z']**2)
        
        features.extend([
            np.mean(accel_3d),
            np.std(accel_3d),
            np.max(accel_3d),
            np.min(accel_3d),
        ])
        
        # === Feature Set 3: Gyroscope Magnitude ===
        gyro_mag = np.sqrt(data['ITG3200_x']**2 + 
                          data['ITG3200_y']**2 + 
                          data['ITG3200_z']**2)
        
        features.extend([
            np.mean(gyro_mag),
            np.std(gyro_mag),
            np.max(gyro_mag),
            np.min(gyro_mag),
        ])
        
        # === Feature Set 4: Time-Domain Features ===
        # Peak timing (normalized)
        peak_idx = np.argmax(accel_3d)
        features.append(peak_idx / len(accel_3d))
        
        # Jerk (rate of acceleration change)
        jerk = np.diff(accel_3d)
        features.extend([
            np.mean(np.abs(jerk)),
            np.max(np.abs(jerk)),
        ])
        
        # === Feature Set 5: Standard Deviation of Horizontal (C8) ===
        features.append(np.std(accel_horizontal))
        
        # Add label at the end
        features.append(label)
        
        return np.array(features)
    
    except Exception as e:
        print(f"❌ Error processing {filepath}: {e}")
        return None


def extract_motion_features_realtime(accel_data, gyro_data):
    """
    Extract features from real-time ESP32 sensor data
    
    Args:
        accel_data: numpy array shape (N, 3) - accelerometer readings
        gyro_data: numpy array shape (N, 3) - gyroscope readings
    
    Returns:
        features: numpy array of 18 features (without label)
    """
    features = []
    
    # Horizontal magnitude (x and z axes)
    accel_horizontal = np.sqrt(accel_data[:, 0]**2 + accel_data[:, 2]**2)
    
    features.extend([
        np.mean(accel_horizontal),
        np.std(accel_horizontal),
        np.max(accel_horizontal),
        np.min(accel_horizontal),
        np.max(accel_horizontal) - np.min(accel_horizontal),
    ])
    
    # 3D magnitude
    accel_3d = np.sqrt(np.sum(accel_data**2, axis=1))
    
    features.extend([
        np.mean(accel_3d),
        np.std(accel_3d),
        np.max(accel_3d),
        np.min(accel_3d),
    ])
    
    # Gyroscope magnitude
    gyro_mag = np.sqrt(np.sum(gyro_data**2, axis=1))
    
    features.extend([
        np.mean(gyro_mag),
        np.std(gyro_mag),
        np.max(gyro_mag),
        np.min(gyro_mag),
    ])
    
    # Peak timing
    peak_idx = np.argmax(accel_3d)
    features.append(peak_idx / len(accel_3d))
    
    # Jerk
    jerk = np.diff(accel_3d)
    features.extend([
        np.mean(np.abs(jerk)),
        np.max(np.abs(jerk)),
    ])
    
    # Horizontal std (C8)
    features.append(np.std(accel_horizontal))
    
    return np.array(features)
