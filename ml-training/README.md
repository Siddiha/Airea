# ML Training Guide

This directory contains all machine learning training pipelines for the Airea health monitoring system.

## Structure

- `cough-detection/` - Audio-based cough detection ML pipeline
- `fall-detection/` - IMU-based fall detection ML pipeline
- `data/` - Training datasets (raw and processed)
- `models/` - Trained model outputs

## Setup

1. Install dependencies:
```bash
pip install -r requirements.txt
```

2. Download datasets:
```bash
cd cough-detection
python 1_download_datasets.py
```

3. Train models:
```bash
python 2_preprocess_audio.py
python 3_create_balanced_dataset.py
python 4_train_model.py
python 5_evaluate_model.py
python 6_convert_to_tflite.py
```

## Data Structure

- `data/raw/` - Raw datasets (COUGHVID, ESC-50, KFall)
- `data/processed/` - Preprocessed features (MFCC, motion features)

## Models

Trained models are saved in `models/cough/` and `models/fall/` with:
- `.h5` or `.pkl` - Original trained models
- `.tflite` - TensorFlow Lite models for ESP32
- `evaluation_metrics.json` - Model performance metrics


