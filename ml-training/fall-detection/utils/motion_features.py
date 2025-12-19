# ml-training/fall-detection/utils/motion_features.py

import numpy as np

def extract_motion_features(accel_data, gyro_data):
    """
    Extract features from accelerometer and gyroscope data
    
    Args:
        accel_data: numpy array of shape (n_samples, 3) - accelerometer readings
        gyro_data: numpy array of shape (n_samples, 3) - gyroscope readings
    
    Returns:
        features: numpy array of extracted features
    """
    features = []
    
    # Acceleration magnitude
    accel_mag = np.sqrt(np.sum(accel_data**2, axis=1))
    features.extend([
        np.mean(accel_mag),
        np.std(accel_mag),
        np.max(accel_mag),
        np.min(accel_mag)
    ])
    
    # Gyroscope magnitude
    gyro_mag = np.sqrt(np.sum(gyro_data**2, axis=1))
    features.extend([
        np.mean(gyro_mag),
        np.std(gyro_mag),
        np.max(gyro_mag),
        np.min(gyro_mag)
    ])
    
    return np.array(features)

