<div align="center">

# Airea - AI-Powered Health Monitoring System

### Intelligent Real-time Health Monitoring Using Edge AI & IoT

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.1-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![ESP32](https://img.shields.io/badge/ESP32--S3-PlatformIO-00979D?logo=espressif)](https://www.espressif.com/)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-Lite-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql)](https://www.postgresql.org/)

</div>

---

## 🎯 About The Project

**Airea** is a comprehensive AI-powered health monitoring system that leverages **Edge AI**, **IoT sensors**, and **cloud computing** to provide real-time health insights. The system monitors multiple health metrics including respiratory health (cough detection), heart rate, respiratory rate, body temperature, and fall detection with automatic emergency alerts.

### Why Airea?

- 🏥 **Healthcare** - Remote patient monitoring and chronic disease management
- 🏠 **Home Care** - Non-invasive health surveillance for elderly and families
- 🤖 **AI-Powered** - Edge ML inference with TensorFlow Lite for real-time analysis
- 🔒 **Privacy-First** - Sensor data processed locally on ESP32 device
- 📊 **Comprehensive** - Multiple health metrics in one wearable system
- 🚨 **Emergency Alerts** - Automatic SMS alerts to emergency contacts

---

## ✨ Key Features

### 🤖 Edge AI Capabilities

- ✅ On-device ML inference using TensorFlow Lite Micro
- ✅ Real-time cough classification with confidence scoring (>80%)
- ✅ Fall detection using accelerometer/gyroscope fusion
- ✅ Low latency DSP-based heart rate and respiratory rate extraction
- ✅ INT8 quantized models for ESP32 optimization

### 📊 Health Monitoring

- 🫁 **Respiratory** - Cough detection via INMP441 microphone + CNN model
- ❤️ **Cardiovascular** - Heart rate (BPM) via AD8232 ECG module with DSP peak detection
- 🌬️ **Breathing** - Respiratory rate via ECG-derived respiration (EDR)
- 🌡️ **Temperature** - Body temperature via MAX30205 sensor
- 🏃 **Motion** - Fall detection via MPU6050 IMU + G-force analysis

### 🚨 Emergency Alert System

- Automatic SMS alerts via Notify.lk API
- Critical thresholds: HR <40 or >150 BPM, Temp <35°C or >39.5°C, RR <8 or >30
- Fall impact severity scoring (G-force >2.5G triggers alert)
- GPS location included in emergency messages
- 5-minute cooldown to prevent duplicate alerts

### 🌐 Cross-Platform

- iOS, Android, Web, and Desktop support via Flutter
- Real-time data synchronization with WebSocket
- Daily/Weekly health summaries with AI-generated insights
- Patient & Doctor role-based dashboards

---

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            AIREA ECOSYSTEM                                  │
└─────────────────────────────────────────────────────────────────────────────┘

┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│   IoT Layer      │──────▶│   Edge AI Layer  │──────▶│   Cloud Layer    │
│                  │      │                  │      │                  │
│ • ESP32-S3       │      │ • TFLite Cough   │      │ • Spring Boot    │
│ • INMP441 Mic    │      │ • TFLite Fall    │      │ • PostgreSQL     │
│ • AD8232 ECG     │      │ • DSP Processing │      │ • REST API       │
│ • MAX30205 Temp  │      │ • G-Force Calc   │      │ • WebSocket      │
│ • MPU6050 IMU    │      │ • FreeRTOS Tasks │      │ • SMS Alerts     │
└──────────────────┘      └──────────────────┘      └──────────────────┘
                                                               │
                                                               │
                          ┌────────────────────────────────────┤
                          │                                    │
                          ▼                                    ▼
              ┌──────────────────┐              ┌──────────────────┐
              │  Mobile Layer    │              │   Data Layer     │
              │                  │              │                  │
              │ • Flutter App    │              │ • Supabase DB    │
              │ • iOS/Android    │              │ • Time-series    │
              │ • Web Dashboard  │              │ • Health Reports │
              │ • Push Alerts    │              │ • Analytics      │
              └──────────────────┘              └──────────────────┘
```

### Data Flow

```
ESP32 Sensors → Edge AI Processing → Cloud Backend → Mobile App → Emergency Contact
     ↓               ↓                      ↓             ↓              ↓
  Raw Data    TFLite Inference        PostgreSQL    Real-time UI    SMS Alert
  Capture     + DSP Analysis           Storage       Dashboard     (if critical)
```

### API Data Flow (every 5 seconds)

| Endpoint                 | Data Sent                             | Purpose                            |
| ------------------------ | ------------------------------------- | ---------------------------------- |
| `POST /api/vitals/event` | temp, bpm, respiratory rate, leadsOff | Continuous vitals monitoring       |
| `POST /api/cough/event`  | confidence, audio volume              | Cough event logging                |
| `POST /api/fall/event`   | g-force, GPS, vitals snapshot         | Fall detection + emergency trigger |

---

## 🛠️ Tech Stack

<div align="center">

### Backend

![Java](https://img.shields.io/badge/Java-17-ED8B00?style=for-the-badge&logo=openjdk)
![Spring Boot](https://img.shields.io/badge/Spring_Boot-3.2.1-6DB33F?style=for-the-badge&logo=spring-boot)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-316192?style=for-the-badge&logo=postgresql)
![Maven](https://img.shields.io/badge/Maven-3.x-C71A36?style=for-the-badge&logo=apache-maven)

### Frontend

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart)

### Firmware

![ESP32](https://img.shields.io/badge/ESP32-WROOM--32-00979D?style=for-the-badge&logo=espressif)
![Arduino](https://img.shields.io/badge/Arduino-2.x-00979D?style=for-the-badge&logo=arduino)
![TensorFlow Lite](https://img.shields.io/badge/TFLite-Micro-FF6F00?style=for-the-badge&logo=tensorflow)

### Machine Learning

![Python](https://img.shields.io/badge/Python-3.x-3776AB?style=for-the-badge&logo=python)
![TensorFlow](https://img.shields.io/badge/TensorFlow-2.x-FF6F00?style=for-the-badge&logo=tensorflow)
![Keras](https://img.shields.io/badge/Keras-Latest-D00000?style=for-the-badge&logo=keras)

</div>

---

## 🚀 Installation

### Prerequisites

```bash
✅ Java 17+
✅ Maven 3.6+
✅ Flutter 3.x
✅ PlatformIO
✅ PostgreSQL 15+ (or Supabase account)
✅ ESP32 hardware + sensors
```

---

## 1️⃣ Backend Setup

```bash
# Clone repository
git clone https://github.com/yourusername/airea.git
cd airea/backend

# Create .env file
cat > .env << EOF
SUPABASE_URL=jdbc:postgresql://db.your-project.supabase.co:5432/postgres
SUPABASE_USERNAME=postgres
SUPABASE_PASSWORD=your_password
EOF

# Run backend
mvn clean install
mvn spring-boot:run
```

**Backend runs at:** `http://localhost:8080`

**Test it:**

```bash
curl http://localhost:8080/api/cough/health
```

---

## 2️⃣ Frontend Setup

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

### Hardware Connections (ESP32-S3)

```
INMP441 Microphone (I2S Audio):
  SCK  → GPIO 41
  WS   → GPIO 42
  SD   → GPIO 2
  VDD  → 3.3V
  GND  → GND

AD8232 ECG Module:
  OUTPUT → GPIO 1 (ADC)
  LO+    → GPIO 6
  LO-    → GPIO 7
  VCC    → 3.3V
  GND    → GND

MAX30205 Temperature (I2C Bus 1):
  SDA  → GPIO 17
  SCL  → GPIO 18
  VIN  → 3.3V
  GND  → GND

MPU6050 IMU (I2C Bus 2):
  SDA  → GPIO 15
  SCL  → GPIO 16
  VCC  → 3.3V
  GND  → GND

Status LED:
  LED  → GPIO 4
```

### Upload Firmware

```bash
cd esp32_firmware

# Install PlatformIO CLI
pip install platformio

# The firmware uses WiFiManager for easy WiFi setup
# On first boot, connect to "AIREA-Setup" WiFi network
# Configure your WiFi credentials via the captive portal

# Upload to ESP32-S3
pio run -t upload

# Monitor serial output
pio device monitor -b 115200
```

### Firmware Features

- **FreeRTOS Tasks**: Audio inference and network sender run on Core 0
- **WiFiManager**: Easy WiFi configuration via captive portal
- **Background HTTP Queue**: Non-blocking data transmission
- **ECG DSP**: 250Hz sampling with peak detection for BPM
- **Respiratory Rate**: EDR (ECG-derived respiration) extraction

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
# Send test cough event
curl -X POST http://localhost:8080/api/cough/event \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ESP32_HEALTH_01",
    "coughType": "dry",
    "confidence": 0.85,
    "audioVolume": 65.5
  }'

# Get statistics
curl http://localhost:8080/api/cough/stats/ESP32_HEALTH_01/today
```

---

## 📡 API Endpoints

### Base URL

```
Production: https://airea-production.up.railway.app/api
Local:      http://localhost:8080/api
```

### Authentication Endpoints

| Method | Endpoint                 | Description                 |
| ------ | ------------------------ | --------------------------- |
| `POST` | `/auth/patient/register` | Register new patient        |
| `POST` | `/auth/patient/login`    | Patient login (returns JWT) |
| `POST` | `/auth/doctor/register`  | Register new doctor         |
| `POST` | `/auth/doctor/login`     | Doctor login (returns JWT)  |
| `POST` | `/auth/forgot-password`  | Request password reset OTP  |
| `POST` | `/auth/reset-password`   | Reset password with OTP     |

### Vitals Endpoints

| Method | Endpoint                    | Description                                 |
| ------ | --------------------------- | ------------------------------------------- |
| `POST` | `/vitals/event`             | Submit vitals (temp, bpm, respiratory rate) |
| `GET`  | `/vitals/device/{deviceId}` | Get all vitals for device                   |
| `GET`  | `/vitals/latest/{deviceId}` | Get latest vitals reading                   |
| `GET`  | `/vitals/range/{deviceId}`  | Get vitals in date range                    |

### Cough Detection Endpoints

| Method | Endpoint                        | Description              |
| ------ | ------------------------------- | ------------------------ |
| `POST` | `/cough/event`                  | Submit cough event       |
| `GET`  | `/cough/device/{deviceId}`      | Get all cough events     |
| `GET`  | `/cough/stats/{deviceId}/hour`  | Hourly cough statistics  |
| `GET`  | `/cough/stats/{deviceId}/today` | Today's cough statistics |
| `GET`  | `/cough/health`                 | Health check endpoint    |

### Fall Detection Endpoints

| Method | Endpoint                     | Description                                  |
| ------ | ---------------------------- | -------------------------------------------- |
| `POST` | `/fall/event`                | Submit fall event (triggers emergency check) |
| `GET`  | `/fall/device/{deviceId}`    | Get all fall events                          |
| `GET`  | `/fall/emergency/{deviceId}` | Get emergency events only                    |

### Health Summary Endpoints

| Method | Endpoint                              | Description                        |
| ------ | ------------------------------------- | ---------------------------------- |
| `GET`  | `/summary/daily/{patientId}`          | Daily health summary with insights |
| `GET`  | `/summary/weekly/{patientId}`         | Weekly health summary with trends  |
| `GET`  | `/summary/cough-analysis/{patientId}` | Detailed cough pattern analysis    |

### Device Management Endpoints

| Method | Endpoint           | Description            |
| ------ | ------------------ | ---------------------- |
| `POST` | `/device/register` | Register new device    |
| `GET`  | `/device/active`   | Get all active devices |
| `POST` | `/device/link`     | Link device to patient |

---

## 🔌 Hardware Requirements

### Minimum Setup (Cough Detection)

- ESP32-S3-WROOM ($8-15)
- INMP441 Microphone ($2-5)
- **Total: ~$15**

### Full Setup (All Features)

- ESP32-S3-WROOM
- INMP441 Microphone
- AD8232 ECG Module ($5-10)
- MAX30205 Temperature Sensor ($3-8)
- MPU6050 Accelerometer/Gyroscope ($2-5)
- **Total: ~$25-50**

---

## 📁 Project Structure

```
airea/
├── backend/                      # Spring Boot REST API
│   ├── src/main/java/
│   │   ├── config/               # Security, CORS, WebSocket config
│   │   ├── controller/           # REST endpoints
│   │   │   ├── AuthController    # Patient/Doctor authentication
│   │   │   ├── VitalsController  # Vitals data endpoints
│   │   │   ├── CoughController   # Cough event endpoints
│   │   │   ├── FallController    # Fall detection endpoints
│   │   │   └── SummaryController # Health summaries
│   │   ├── model/                # JPA entities
│   │   │   ├── Patient, Doctor   # User models
│   │   │   ├── VitalsEvent       # Temperature, BPM, respiratory rate
│   │   │   ├── CoughEvent        # Cough detection events
│   │   │   └── FallEvent         # Fall events with emergency status
│   │   ├── repository/           # JPA repositories
│   │   ├── service/              # Business logic
│   │   │   ├── FallDetectionService   # Emergency detection logic
│   │   │   ├── SmsAlertService        # Notify.lk SMS integration
│   │   │   └── SummaryService         # Health insights generation
│   │   └── dto/                  # Data transfer objects
│   └── pom.xml
│
├── frontend/                     # Flutter Cross-Platform App
│   ├── lib/
│   │   ├── config/               # API configuration, themes
│   │   ├── models/               # Data models (Patient, Vitals, etc.)
│   │   ├── screens/              # UI screens
│   │   │   ├── patient/          # Patient dashboard, summaries
│   │   │   └── doctor/           # Doctor patient management
│   │   ├── services/             # API, Auth, Summary services
│   │   ├── widgets/              # Reusable UI components
│   │   └── utils/                # Helpers, formatters
│   └── pubspec.yaml
│
├── esp32_firmware/               # ESP32-S3 PlatformIO Project
│   ├── src/
│   │   └── main.cpp              # FreeRTOS tasks, sensor reading, ML inference
│   ├── lib/
│   │   ├── cough_model.h         # TFLite cough detection model
│   │   └── fall_model.h          # TFLite fall detection model
│   └── platformio.ini
│
└── ml-training/                  # Machine Learning Training
    ├── cough-training/
    │   ├── train_final.py        # Cough CNN model training
    │   ├── dataset/              # Audio samples (cough/noise)
    │   └── model.h               # Exported TFLite model
    └── fall-training/
        ├── train_fall.py         # Fall detection model training
        ├── process_dataset.py    # IMU data preprocessing
        └── IMU-Dataset/          # Accelerometer/gyroscope data
```

---

## 🧠 ML Model Training

### Cough Detection Model

```bash
cd ml-training/cough-training

# Install dependencies
pip install -r requirements.txt

# Train model (uses dataset/ folder)
python train_final.py

# Output: model.h (TFLite INT8 quantized for ESP32)
```

- **Architecture**: Conv1D → MaxPooling → GlobalAveragePooling → Dense
- **Input**: 2-second audio (16000 samples at 16kHz)
- **Output**: Binary (cough vs. noise)

### Fall Detection Model

```bash
cd ml-training/fall-training

# Process IMU dataset
python process_dataset.py

# Train model
python train_fall.py

# Output: fall_model.h (TFLite Float32)
```

- **Architecture**: Conv1D → MaxPooling → Dropout → Dense
- **Input**: 200 timesteps × 6 features (3-axis accel + 3-axis gyro)
- **Output**: Binary (fall vs. ADL activities)

---

## 🚨 Emergency Detection Thresholds

| Metric           | Normal Range | Warning     | Critical (Emergency) |
| ---------------- | ------------ | ----------- | -------------------- |
| Heart Rate       | 60-100 BPM   | <50 or >120 | <40 or >150          |
| Temperature      | 36.1-37.5°C  | >38°C       | <35°C or >39.5°C     |
| Respiratory Rate | 12-20 /min   | <10 or >25  | <8 or >30            |
| Fall G-Force     | <1.5G        | >2.0G       | >2.5G (>3.0G severe) |

---

## 🗺️ Roadmap

- [x] Cough detection with TFLite CNN
- [x] Real-time Flutter mobile app
- [x] Cloud database integration (Supabase PostgreSQL)
- [x] Heart rate monitoring via AD8232 ECG
- [x] Respiratory rate via ECG-derived respiration
- [x] Body temperature tracking via MAX30205
- [x] Fall detection with MPU6050 + G-force analysis
- [x] Emergency SMS alerts via Notify.lk
- [x] Daily/Weekly health summaries with AI insights
- [x] Patient & Doctor authentication with JWT
- [x] WebSocket real-time vitals streaming
- [ ] Push notifications for mobile
- [ ] Offline data caching
- [ ] Apple Watch / WearOS integration

---

## 🚀 Deployment

### Backend (Railway)

```bash
# The backend is configured for Railway deployment
# See railway.toml for configuration

# Database configuration (choose ONE approach)

# Option A (recommended)
SPRING_DATASOURCE_URL=jdbc:postgresql://db.xxx.supabase.co:5432/postgres?sslmode=require
SPRING_DATASOURCE_USERNAME=postgres
SPRING_DATASOURCE_PASSWORD=your_password

# Option B
DATABASE_URL=postgresql://postgres:your_password@db.xxx.supabase.co:5432/postgres

# Required app variables
JWT_SECRET=your_long_secure_secret_key
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.com

# Optional mail (password reset)
MAIL_USERNAME=your_gmail@gmail.com
MAIL_PASSWORD=your_gmail_app_password

# Optional SMS (alerts)
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890
SMS_ALERTS_ENABLED=true
```

**Production URL**: `https://airea-production.up.railway.app`

### Database (Supabase)

- PostgreSQL 15 hosted on Supabase
- Automatic backups enabled
- Connection pooling via PgBouncer

### Frontend (Multi-platform)

```bash
# Build for different platforms
flutter build apk          # Android
flutter build ios          # iOS
flutter build web          # Web
flutter build macos        # macOS
flutter build windows      # Windows
```

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

MIT License - see [LICENSE](LICENSE) file

---

## 📧 Contact

**Project Link:** [https://github.com/yourusername/airea](https://github.com/yourusername/airea)

---

<div align="center">

### ⭐ Star this repository if you found it helpful!

Made with ❤️ by the Airea Team

</div>
