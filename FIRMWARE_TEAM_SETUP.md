# 🔧 ESP32 Firmware Team - Setup Instructions

## 📋 Overview
This document is for the firmware team who has the ESP32 hardware. Follow these steps to upload the firmware and connect it to the backend.

---

## ⚡ Prerequisites

### Hardware Required:
- ✅ ESP32-S3 DevKit (with N16R8 configuration)
- ✅ USB-C cable
- ✅ Microphone sensor (INMP441 or similar)
- ✅ WiFi network access

### Software Required:
- ✅ PlatformIO (VS Code extension or CLI)
- ✅ Python 3.7+
- ✅ USB drivers for ESP32

---

## 🚀 Step-by-Step Setup

### Step 1: Install PlatformIO

**Option A: VS Code Extension (Recommended)**
```bash
# Install VS Code
# Then install "PlatformIO IDE" extension from VS Code marketplace
```

**Option B: CLI Only**
```bash
pip install platformio
```

---

### Step 2: Configure WiFi and Backend

📁 Open file: `Airea/esp32_firmware/src/config.h`

Update these values:

```cpp
// WiFi Configuration
#define WIFI_SSID "YOUR_WIFI_NAME"
#define WIFI_PASSWORD "YOUR_WIFI_PASSWORD"

// Backend API Configuration
#define API_BASE_URL "http://YOUR_COMPUTER_IP:8080/api"
// Example: "http://192.168.1.100:8080/api"

// Device Configuration
#define DEVICE_ID "ESP32_COUGH_01"
```

**🔍 How to find YOUR_COMPUTER_IP:**

Windows:
```bash
ipconfig
# Look for "IPv4 Address" (e.g., 192.168.1.100)
```

Mac/Linux:
```bash
ifconfig
# Look for "inet" address
```

⚠️ **IMPORTANT:** Do NOT use `localhost` or `127.0.0.1` - use your actual local network IP!

---

### Step 3: Connect ESP32 Hardware

1. Connect microphone to ESP32:
   ```
   INMP441 → ESP32-S3
   SCK  → GPIO 4
   WS   → GPIO 5
   SD   → GPIO 6
   VDD  → 3.3V
   GND  → GND
   ```

2. Connect ESP32 to computer via USB-C cable

3. Check if ESP32 is detected:
   ```bash
   # Windows
   platformio device list

   # Should show something like:
   # COM3 - USB Serial Device (USB VID:PID=303A:1001)
   ```

---

### Step 4: Upload Firmware

```bash
cd Airea/esp32_firmware

# Build and upload firmware
platformio run --target upload

# Monitor serial output (to see logs)
platformio device monitor
```

**Expected Output:**
```
[SUCCESS] Firmware uploaded successfully
Connecting to WiFi...
WiFi connected! IP: 192.168.1.50
Connecting to backend...
Backend connected!
Listening for cough sounds...
```

---

### Step 5: Test the Connection

**Test 1: Check Serial Monitor**
```bash
platformio device monitor
```

You should see:
- WiFi connection status
- Backend API connection confirmation
- "Listening..." messages

**Test 2: Verify Backend Receives Data**

From your computer (not ESP32), run:
```bash
curl http://localhost:8080/api/device/active
```

Should show:
```json
[
  {
    "deviceId": "ESP32_COUGH_01",
    "deviceName": "Airea Cough Monitor",
    "status": "active",
    "lastSeen": "2026-01-08T10:30:00Z"
  }
]
```

**Test 3: Simulate a Cough**

Make a cough sound near the microphone and check serial monitor:
```
Cough detected!
Type: dry
Confidence: 0.89
Sending to backend...
✅ Data sent successfully
```

---

## 🔍 Troubleshooting

### Issue: ESP32 Won't Upload
```bash
# Check if device is detected
platformio device list

# Try holding BOOT button while uploading

# Or erase flash first
platformio run --target erase
platformio run --target upload
```

### Issue: WiFi Connection Failed
- Double-check SSID and password in `config.h`
- Make sure ESP32 and computer are on same network
- Some WiFi networks block device-to-device communication

### Issue: Backend Connection Failed
- Verify backend is running: `curl http://localhost:8080/api/cough/health`
- Check firewall isn't blocking port 8080
- Verify IP address is correct (use `ipconfig` not `localhost`)
- ESP32 and backend computer must be on same WiFi network

### Issue: No Cough Detection
- Check microphone connections
- Verify microphone is working (check serial logs for audio levels)
- Adjust sensitivity in `config.h` if needed

---

## 📊 Expected Data Flow

```
1. ESP32 hears cough → Analyzes audio
2. ESP32 sends to backend → POST /api/cough/event
3. Backend stores in database
4. Frontend polls backend → GET /api/cough/device/ESP32_COUGH_01
5. User sees live data on phone/web app
```

---

## 🎯 Verification Checklist

Once firmware is uploaded and running, verify:

- [ ] ESP32 connects to WiFi (check serial monitor)
- [ ] ESP32 connects to backend API (check serial monitor)
- [ ] Backend shows device as active (`curl http://localhost:8080/api/device/active`)
- [ ] Cough detection works (make test cough)
- [ ] Data appears in backend (`curl http://localhost:8080/api/cough/device/ESP32_COUGH_01`)
- [ ] Frontend shows live data (run Flutter app)

---

## 📞 Contact

If you encounter issues:
1. Check serial monitor output: `platformio device monitor`
2. Check backend logs in the terminal where `mvn spring-boot:run` is running
3. Verify all 3 parts are on the same WiFi network

---

## 🔄 Quick Reference Commands

```bash
# Upload firmware
cd Airea/esp32_firmware
platformio run --target upload

# Monitor serial output
platformio device monitor

# Restart ESP32
platformio run --target upload --target monitor

# Check backend health
curl http://localhost:8080/api/cough/health

# Check for cough data
curl http://localhost:8080/api/cough/device/ESP32_COUGH_01
```

---

## ✅ Success Indicators

You'll know everything is working when:
1. Serial monitor shows "Listening for cough sounds..."
2. Backend API returns data when you cough
3. Flutter app shows real-time cough events
4. Green "LIVE" indicator appears in the app

---

**Good luck! 🚀**
