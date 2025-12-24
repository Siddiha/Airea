<div align="center">

# 🏥 Airea - AI-Powered Health Monitoring System

### Intelligent Real-time Health Monitoring Using Edge AI & IoT

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Spring Boot](https://img.shields.io/badge/Spring%20Boot-3.2.1-brightgreen.svg)](https://spring.io/projects/spring-boot)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![ESP32](https://img.shields.io/badge/ESP32-Arduino-00979D?logo=espressif)](https://www.espressif.com/)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-Lite-FF6F00?logo=tensorflow)](https://www.tensorflow.org/lite)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-336791?logo=postgresql)](https://www.postgresql.org/)

[Features](#-key-features) • [Architecture](#-system-architecture) • [Installation](#-installation) • [Tech Stack](#-tech-stack)

</div>

---

## 🎯 About The Project

**Airea** is a comprehensive AI-powered health monitoring system that leverages **Edge AI**, **IoT sensors**, and **cloud computing** to provide real-time health insights. The system monitors multiple health metrics including respiratory health, heart rate, temperature, and motion detection.

### Why Airea?

- 🏥 **Healthcare** - Remote patient monitoring and chronic disease management
- 🏠 **Home Care** - Non-invasive health surveillance for families
- 🤖 **AI-Powered** - Edge ML inference with real-time analysis
- 🔒 **Privacy-First** - Data processed locally on device
- 📊 **Comprehensive** - Multiple health metrics in one system

---

## ✨ Key Features

### 🤖 Edge AI Capabilities
- ✅ On-device ML inference using TensorFlow Lite
- ✅ Real-time classification with confidence scoring
- ✅ Low latency (<100ms)
- ✅ Multiple health metrics monitoring

### 📊 Health Monitoring
- 🫁 **Respiratory** - Cough detection & classification (Dry/Wet)
- ❤️ **Cardiovascular** - Heart rate & SpO2 monitoring
- 🌡️ **Temperature** - Body and ambient temperature tracking
- 🏃 **Motion** - Fall detection and activity tracking

### 🌐 Cross-Platform
- iOS, Android, Web, and Desktop support
- Real-time data synchronization
- Historical trend analysis
- Customizable alerts and notifications

---

## 🏗️ System Architecture

### High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        AIREA ECOSYSTEM                          │
└─────────────────────────────────────────────────────────────────┘

┌──────────────────┐      ┌──────────────────┐      ┌──────────────────┐
│   IoT Layer      │──────▶│   Edge Layer     │──────▶│   Cloud Layer    │
│                  │      │                  │      │                  │
│ • ESP32 Devices  │      │ • TFLite Models  │      │ • Spring Boot    │
│ • Sensors        │      │ • Preprocessing  │      │ • PostgreSQL     │
│ • INMP441 Mic    │      │ • Classification │      │ • REST API       │
│ • MAX30102 HR    │      │ • Filtering      │      │ • Supabase       │
│ • MLX90614 Temp  │      │ • Edge AI        │      │                  │
│ • MPU6050 IMU    │      │                  │      │                  │
└──────────────────┘      └──────────────────┘      └──────────────────┘
                                                               │
                                                               │
                          ┌────────────────────────────────────┤
                          │                                    │
                          ▼                                    ▼
              ┌──────────────────┐              ┌──────────────────┐
              │  Mobile Layer    │              │   Data Layer     │
              │                  │              │                  │
              │ • Flutter App    │              │ • Supabase       │
              │ • iOS/Android    │              │ • Time-series    │
              │ • Web Dashboard  │              │ • Analytics      │
              │ • Notifications  │              │ • Backups        │
              └──────────────────┘              └──────────────────┘
```

### Data Flow

```
ESP32 Sensors → Edge AI Processing → Cloud Backend → Mobile App
     ↓               ↓                      ↓             ↓
  Raw Data    TFLite Inference        PostgreSQL    Real-time UI
  Capture     Classification          Storage       Analytics
```

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
http://localhost:8080/api
```

### Key Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `GET` | `/cough/health` | Health check |
| `POST` | `/cough/event` | Submit cough event |
| `GET` | `/cough/device/{deviceId}` | Get all events |
| `GET` | `/cough/stats/{deviceId}/hour` | Hourly statistics |
| `GET` | `/cough/stats/{deviceId}/today` | Today's statistics |
| `POST` | `/device/register` | Register device |
| `GET` | `/device/active` | Get active devices |

---

## 🔌 Hardware Requirements

### Minimum Setup (Cough Detection)
- ESP32-WROOM-32 ($5-10)
- INMP441 Microphone ($2-5)
- **Total: ~$10**

### Full Setup (All Features)
- ESP32-WROOM-32
- INMP441 Microphone
- MAX30102 Heart Rate Sensor ($3-8)
- MLX90614 Temperature Sensor ($5-15)
- MPU6050 Accelerometer ($2-5)
- **Total: ~$20-45**

---

## 📁 Project Structure

```
airea/
├── backend/                 # Spring Boot API
│   ├── src/
│   │   ├── config/
│   │   ├── controller/
│   │   ├── model/
│   │   ├── repository/
│   │   └── service/
│   └── pom.xml
│
├── frontend/                # Flutter App
│   ├── lib/
│   │   ├── config/
│   │   ├── models/
│   │   ├── services/
│   │   └── screens/
│   └── pubspec.yaml
│
├── esp32_firmware/          # ESP32 Code
│   ├── src/main.cpp
│   ├── include/model.h
│   └── platformio.ini
│
└── ml-training/             # ML Models
    └── cough-detection/
```

---

## 🗺️ Roadmap

- [x] Cough detection and classification
- [x] Real-time mobile app
- [x] Cloud database integration
- [ ] Heart rate monitoring
- [ ] Temperature tracking
- [ ] Fall detection
- [ ] Push notifications
- [ ] Web dashboard

---

## 🤝 Contributing

Contributions are welcome!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add feature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---


<div align="center">

### ⭐ Star this repository if you found it helpful!

Made with ❤️ by the Airea Team

</div>
