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
cd frontend

# Install dependencies
flutter pub get

# Configure API (edit lib/config/api_config.dart)
# Set backendHost = 'localhost' for local testing
# Set backendHost = '192.168.x.x' for mobile device testing

# Run app
flutter run -d chrome     # Web
flutter run -d android    # Mobile
```

---

## 3️⃣ ESP32 Firmware Setup

### Hardware Connections

```
INMP441 Microphone (I2S):
  SCK  → GPIO 14
  WS   → GPIO 15
  SD   → GPIO 32
  VDD  → 3.3V
  GND  → GND

MAX30102 (I2C) [Optional]:
  SCL  → GPIO 22
  SDA  → GPIO 21
  VIN  → 3.3V
  GND  → GND
```

### Upload Firmware

```bash
cd esp32_firmware

# Edit src/main.cpp - Configure WiFi and Backend URL
# #define WIFI_SSID "Your_WiFi_Name"
# #define WIFI_PASSWORD "Your_Password"
# #define BACKEND_URL "http://192.168.x.x:8080/api/cough/event"

# Install PlatformIO
pip install platformio

# Upload to ESP32
pio run -t upload
pio device monitor
```

---

## 📖 Usage

### Quick Start

1. **Power on ESP32** with connected sensors
2. **Open mobile app** (or web browser)
3. **Enter device ID:** `ESP32_HEALTH_01`
4. **Click "Connect"**
5. **View real-time health data!**

### Test Manually

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




