# 🔗 AIREA Cough Detection - Complete Integration Guide

## 📋 Overview

This guide explains how the **ESP32 Firmware**, **Backend API**, and **Flutter Frontend** are connected for real-time cough detection and monitoring.

---

## 🏗️ System Architecture

```
┌─────────────────┐         ┌──────────────────┐         ┌─────────────────┐
│  ESP32 Firmware │  WiFi   │  Backend API     │  HTTP   │ Flutter App     │
│  (Cough Model)  │────────>│  (Spring Boot)   │<────────│ (Patient/Doctor)│
│                 │         │                  │         │                 │
│  • Records      │         │  • Receives      │         │  • Displays     │
│  • Analyzes     │         │  • Stores        │         │  • Visualizes   │
│  • Sends Events │         │  • Processes     │         │  • Alerts       │
└─────────────────┘         └──────────────────┘         └─────────────────┘
        │                            │                            │
        │                            ├──> PostgreSQL Database    │
        │                            │                            │
        └────────────────────────────┴────────────────────────────┘
                     Real-time WebSocket Updates
```

---

## ✅ Current Connection Status

### 1️⃣ **ESP32 ➡️ Backend** ✅ CONNECTED

**File**: `esp32_firmware/src/main.cpp`

```cpp
// WiFi Configuration
const char *ssid = "Dialog 4G 437";
const char *password = "20040920";

// Backend API Endpoint
const char *serverUrl = "http://192.168.8.107:8080/api/cough/event";

// JWT Authentication
const char *jwtToken = "eyJhbGciOiJIUzUxMiJ9...";
```

**How it works**:
1. ESP32 records 2 seconds of audio (16kHz sample rate)
2. TensorFlow Lite model analyzes audio for cough detection
3. If cough confidence > 90%, it sends HTTP POST to backend:

```json
{
  "deviceId": "ESP32_COUGH_01",
  "coughType": "unknown",
  "confidence": 0.95,
  "rawScore": 0.95,
  "timestamp": 1234567890,
  "audioVolume": 2500.0
}
```

4. Backend responds with saved event
5. ESP32 waits 1 second to avoid spamming

**Authentication**: Uses JWT token (Bearer authentication)

---

### 2️⃣ **Backend API** ✅ RUNNING

**Location**: `backend/src/`

**Main Files**:
- `controller/CoughController.java` - REST API endpoints
- `service/CoughService.java` - Business logic
- `repository/CoughRepository.java` - Database queries
- `model/CoughEvent.java` - Data model

**Available Endpoints**:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/cough/health` | GET | Health check |
| `/api/cough/event` | POST | Submit cough event (from ESP32) |
| `/api/cough/device/{deviceId}` | GET | Get all cough events |
| `/api/cough/device/{deviceId}/range` | GET | Get events in time range |
| `/api/cough/stats/{deviceId}/hour` | GET | Hourly statistics |
| `/api/cough/stats/{deviceId}/today` | GET | Today's statistics |
| `/api/cough/stats/{deviceId}/week` | GET | Weekly statistics |

**Database**: PostgreSQL with tables:
- `cough_events` - Individual cough detections
- `devices` - Registered ESP32 devices

**WebSocket**: Real-time updates on `/topic/cough/{deviceId}`

---

### 3️⃣ **Frontend ➡️ Backend** ⚠️ NEEDS CONFIGURATION

**Location**: `frontend/lib/`

**Configuration File**: `lib/config/api_config.dart`

```dart
class ApiConfig {
  // CHANGE THIS TO YOUR COMPUTER'S IP ADDRESS
  static const String backendHost = 'localhost'; // ← Change to '192.168.x.x'
  static const String backendPort = '8080';

  static const String baseUrl = 'http://$backendHost:$backendPort/api';
  static const String defaultDeviceId = 'ESP32_COUGH_01';
}
```

**API Service**: `lib/services/api_service.dart`

Available methods:
```dart
ApiService apiService = ApiService();

// Check if backend is running
bool isHealthy = await apiService.checkHealth();

// Get all cough events
List<CoughEvent> events = await apiService.getCoughEvents('ESP32_COUGH_01');

// Get hourly statistics
CoughStatistics stats = await apiService.getHourlyStatistics('ESP32_COUGH_01');

// Get today's statistics
CoughStatistics todayStats = await apiService.getTodayStatistics('ESP32_COUGH_01');

// Get weekly statistics
CoughStatistics weeklyStats = await apiService.getWeeklyStatistics('ESP32_COUGH_01');
```

**Data Models**: `lib/models/`
- `cough_event.dart` - Single cough detection
- `cough_statistics.dart` - Aggregated stats
- `device.dart` - ESP32 device info

---

## 🚀 Step-by-Step Setup Guide

### Step 1: Start the Backend

```bash
cd backend

# Make sure PostgreSQL is running
# Check .env file for database credentials

# Run Spring Boot application
mvn spring-boot:run

# OR if you have the JAR file
java -jar target/airea-backend.jar

# Backend should start on http://localhost:8080
```

**Verify Backend**:
Open browser: http://localhost:8080/api/cough/health

Expected response:
```json
{
  "status": "healthy",
  "service": "Airea Cough Monitor API",
  "timestamp": "2026-01-06T..."
}
```

---

### Step 2: Configure ESP32 Firmware

**File**: `esp32_firmware/src/main.cpp`

1. **Update WiFi credentials** (lines 8-9):
```cpp
const char *ssid = "YOUR_WIFI_NAME";
const char *password = "YOUR_WIFI_PASSWORD";
```

2. **Update Backend URL** (line 13):
```cpp
// Find your computer's IP address:
// Windows: Open CMD and type "ipconfig"
// Look for "IPv4 Address" (e.g., 192.168.1.100)

const char *serverUrl = "http://192.168.1.100:8080/api/cough/event";
```

3. **Get JWT Token** (line 20):
```bash
# Register device
curl -X POST http://localhost:8080/api/device/register \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"ESP32_COUGH_01","deviceName":"Test Device"}'

# Generate API key
curl -X POST http://localhost:8080/api/auth/generate-key/ESP32_COUGH_01

# Login to get JWT token
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"ESP32_COUGH_01","apiKey":"YOUR_API_KEY"}'

# Copy the "token" from response and paste into main.cpp
```

4. **Upload to ESP32**:
```bash
cd esp32_firmware
platformio run --target upload
platformio device monitor  # View serial output
```

---

### Step 3: Configure Flutter Frontend

**File**: `frontend/lib/config/api_config.dart`

1. **Find your computer's IP address**:
   - Windows: `ipconfig` in CMD
   - Mac/Linux: `ifconfig` in terminal
   - Look for IPv4 address (e.g., 192.168.1.100)

2. **Update configuration**:
```dart
class ApiConfig {
  static const String backendHost = '192.168.1.100'; // Your IP here
  static const String backendPort = '8080';
  static const String baseUrl = 'http://$backendHost:$backendPort/api';
  static const String defaultDeviceId = 'ESP32_COUGH_01';
}
```

**Important**: If running on Android Emulator:
- Use `10.0.2.2` instead of `localhost`
- Use `10.0.2.2` instead of `127.0.0.1`
- Use your actual IP (192.168.x.x) for physical devices

3. **Run Flutter app**:
```bash
cd frontend
flutter pub get
flutter run
```

---

## 🧪 Testing the Complete Flow

### Test 1: Backend Health Check

**Using Browser**:
```
http://192.168.1.100:8080/api/cough/health
```

**Using Flutter App**:
Navigate to any cough-related page. The app will automatically check backend health.

---

### Test 2: ESP32 → Backend

1. **Start backend** (`mvn spring-boot:run`)
2. **Upload firmware** to ESP32
3. **Monitor serial output**:
```
Airea (S3): System Online.
Connecting to YourWiFi...
Wi-Fi connected.
IP Address: 192.168.1.105
AI Active. Waiting for sound...

Vol: 2500 | Noise: 10.5% | Cough: 95.2%
COUGH DETECTED!
Sending Cough Event to Backend...
Success! HTTP Response: 201
Backend Response: {"id":1,"deviceId":"ESP32_COUGH_01",...}
```

4. **Check backend logs** for received event
5. **Verify database** has new record

---

### Test 3: Frontend → Backend

1. **Open Flutter app**
2. **Navigate to patient cough count page**
3. **App should display**:
   - Real-time cough count
   - Hourly statistics
   - Cough type distribution
   - Recent events

4. **Make the ESP32 detect a cough** (make coughing sound near microphone)
5. **Frontend should update** within 1-2 seconds via WebSocket

---

## 🔧 Updated Frontend Pages

I've updated the following pages to use real backend data:

### 1. Patient Cough Count (`patient_cough_count_live.dart`)

**Features**:
- Real-time cough detection display
- Waveform visualization (animated)
- Hourly statistics from backend
- Cough type breakdown (Dry/Wet/Unknown)
- Auto-refresh every 5 seconds
- Pull-to-refresh support

**Data Flow**:
```dart
ApiService().getHourlyStatistics('ESP32_COUGH_01')
  ↓
Displays in UI:
  - Total coughs
  - Coughs per hour
  - Average confidence
  - Type distribution
```

### 2. Patient Daily Summary

Shows aggregated data for selected date.

### 3. Patient Weekly Summary

Shows aggregated data for selected week.

---

## 📊 Data Flow Diagram

```
┌──────────────┐
│ ESP32 Detects│
│ Cough Sound  │
└──────┬───────┘
       │
       │ HTTP POST /api/cough/event
       ↓
┌──────────────────────┐
│ Backend Receives     │
│ - Saves to DB        │
│ - Broadcasts WebSocket│
└──────┬───────────────┘
       │
       ├─────────────────────┐
       │                     │
       ↓                     ↓
┌─────────────┐      ┌──────────────┐
│ Flutter App │      │ PostgreSQL   │
│ (Real-time) │      │ Database     │
└─────────────┘      └──────────────┘
       │
       │ GET /api/cough/stats/{deviceId}/hour
       ↓
┌─────────────────┐
│ Displays Stats  │
│ - 50/hour       │
│ - 95% confidence│
│ - 80% dry coughs│
└─────────────────┘
```

---

## 🐛 Troubleshooting

### Issue 1: ESP32 Can't Connect to WiFi

**Solution**:
- Check SSID and password in `main.cpp`
- Make sure ESP32 and computer are on same network
- Check WiFi signal strength
- Restart ESP32

---

### Issue 2: ESP32 Gets HTTP Error

**Symptoms**: Serial shows "HTTP Error: -1"

**Solution**:
1. Check backend is running: http://YOUR_IP:8080/api/cough/health
2. Verify `serverUrl` in `main.cpp` matches your computer's IP
3. Check firewall - allow port 8080
4. Verify JWT token is valid (not expired)

---

### Issue 3: Flutter Can't Connect to Backend

**Symptoms**: "Failed to load statistics" error

**Solution**:
1. Check `api_config.dart` has correct IP address
2. If using Android emulator, use `10.0.2.2` instead of `localhost`
3. If using physical device, use computer's actual IP (192.168.x.x)
4. Make sure phone and computer are on same WiFi network
5. Check backend is running and accessible

---

### Issue 4: No Data Showing in App

**Solution**:
1. Check ESP32 is actually detecting coughs (view serial monitor)
2. Verify backend received events: http://YOUR_IP:8080/api/cough/device/ESP32_COUGH_01
3. Check device ID matches in all three places:
   - ESP32: `ESP32_COUGH_01`
   - Backend: Device must be registered
   - Frontend: `ApiConfig.defaultDeviceId`

---

## 🔐 Security Notes

1. **JWT Token**: Expires after 24 hours. Generate new token if expired.
2. **API Keys**: Stored securely in backend database.
3. **HTTPS**: Currently using HTTP for development. Use HTTPS in production.
4. **Rate Limiting**: Backend has rate limiting enabled (100 requests/minute).

---

## 📱 Frontend Screens Using Backend Data

| Screen | Backend Endpoint | Data Displayed |
|--------|-----------------|----------------|
| Patient Cough Count | `/stats/{id}/hour` | Hourly cough statistics |
| Patient Daily Summary | `/stats/{id}/today` | Today's aggregated data |
| Patient Weekly Summary | `/stats/{id}/week` | Weekly trends |
| Doctor Patient Realtime | `/device/{id}` | Live patient vitals |
| Doctor Cough Count | `/stats/{id}/hour` | Patient cough analysis |

---

## 🎯 Next Steps

### For Complete Integration:

1. ✅ Backend running on port 8080
2. ✅ ESP32 configured with WiFi and JWT token
3. ⚠️ Flutter app configured with backend IP
4. ⚠️ Test end-to-end flow
5. ⚠️ Enable WebSocket for real-time updates
6. ⚠️ Add error handling and retry logic

### To Test Right Now:

```bash
# Terminal 1: Start Backend
cd backend
mvn spring-boot:run

# Terminal 2: Monitor ESP32
cd esp32_firmware
platformio device monitor

# Terminal 3: Run Flutter App
cd frontend
flutter run

# Make a coughing sound near ESP32 microphone
# Watch the data flow through all three systems!
```

---

## 📖 Additional Resources

- **Backend Setup**: `backend/AUTHENTICATION_SETUP.md`
- **API Documentation**: http://localhost:8080/swagger-ui.html
- **Database Schema**: Check `backend/resources/schema.sql`
- **WebSocket Testing**: Use browser console or Postman

---

## ✅ Verification Checklist

Before testing the complete flow:

- [ ] PostgreSQL database is running
- [ ] Backend starts without errors on port 8080
- [ ] Health check endpoint returns 200 OK
- [ ] ESP32 connects to WiFi successfully
- [ ] ESP32 has valid JWT token
- [ ] ESP32 can ping backend (check serial output)
- [ ] Flutter app has correct backend IP
- [ ] Flutter app can reach health endpoint
- [ ] All three components on same network
- [ ] Firewall allows port 8080

---

**Status**: ✅ Firmware → Backend CONNECTED | ⚠️ Frontend → Backend NEEDS IP CONFIGURATION

**Last Updated**: January 6, 2026
