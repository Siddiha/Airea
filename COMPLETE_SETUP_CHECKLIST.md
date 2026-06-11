# ✅ Airea Complete System Setup Checklist

## 🎯 System Architecture

```
📱 ESP32 Firmware → 🖥️ Spring Boot Backend → 📱 Flutter Frontend
   (Hardware Team)      (Your Computer)         (Your Computer)
```

---

## 🚀 Part 1: Backend Setup (YOU - Do This First)

### Step 1: Start Backend Server

```powershell
cd Airea\backend
mvn spring-boot:run
```

**Expected Output:**
```
✅ Airea Backend Server Started Successfully!
✅ API Available at: http://localhost:8080/api
✅ Health Check: http://localhost:8080/api/cough/health
```

### Step 2: Verify Backend is Running

Open a new terminal:
```powershell
curl http://localhost:8080/api/cough/health
```

**Expected Response:**
```json
{
  "service": "Airea Cough Monitor API",
  "status": "healthy",
  "timestamp": "2026-01-08T10:30:00Z"
}
```

✅ **If you see this, backend is ready!**

---

## 🔧 Part 2: ESP32 Firmware Setup (FIRMWARE TEAM)

### Instructions for Firmware Team:

**Send them this file:** `FIRMWARE_TEAM_SETUP.md`

**What they need to do:**
1. Update `config.h` with WiFi credentials and your computer's IP
2. Connect ESP32 hardware
3. Run: `platformio run --target upload`
4. Verify connection in serial monitor

**Your Computer's IP Address (Give this to firmware team):**
```powershell
# Run this to get your IP:
ipconfig

# Look for "IPv4 Address" under your WiFi adapter
# Example: 192.168.1.100
```

⚠️ **IMPORTANT:** Make sure:
- Backend is running (`mvn spring-boot:run`)
- ESP32 and your computer are on the **same WiFi network**
- Your firewall allows port 8080

---

## 📱 Part 3: Flutter Frontend Setup (YOU - Do After Backend is Running)

### Step 1: Update API Config (if needed)

📁 File: `frontend/lib/config/api_config.dart`

```dart
static const String backendHost = 'localhost';  // ✅ Correct for testing
static const String backendPort = '8080';       // ✅ Correct
```

### Step 2: Run Flutter App

```powershell
cd frontend
flutter run
```

**Choose device:**
- For Android emulator/device: Select [1]
- For web (Chrome): Select [2] (may have issues)
- For physical phone: Connect via USB and select it

**Expected Result:**
- App loads successfully
- Shows "Cough count analyzer" screen
- Shows "LIVE" indicator (green dot)
- Initially shows "No cough events detected yet"
- Once ESP32 is running, will show real cough data

---

## 🔄 Data Flow Test

### Test 1: Backend Health Check
```powershell
curl http://localhost:8080/api/cough/health
```
✅ Should return: `{"status":"healthy"}`

### Test 2: Check for Devices (After ESP32 is connected)
```powershell
curl http://localhost:8080/api/device/active
```
✅ Should show ESP32 device

### Test 3: Check for Cough Events (After ESP32 detects coughs)
```powershell
curl http://localhost:8080/api/cough/device/ESP32_COUGH_01
```
✅ Should return array of cough events

### Test 4: Frontend Shows Data
- Open Flutter app
- Navigate to Cough Analyzer screen
- Should see:
  - Real-time cough frequency (XX/hour)
  - Total, Dry, Wet counts
  - List of recent cough events
  - Auto-refreshes every 5 seconds

---

## 🐛 Troubleshooting Guide

### Issue: Backend won't start
```powershell
# Check Java version
java -version  # Should be Java 17+

# Check Maven version
mvn -version

# Check port 8080 is free
netstat -ano | findstr :8080
```

### Issue: Frontend can't connect to backend
```powershell
# Verify backend is running
curl http://localhost:8080/api/cough/health

# Check frontend config
# File: frontend/lib/config/api_config.dart
# Must have: backendHost = 'localhost'
```

### Issue: ESP32 can't connect to backend
- Verify backend is running
- Check firewall settings (allow port 8080)
- Ensure ESP32 has correct IP address (not localhost!)
- Both must be on same WiFi network

### Issue: No cough data appearing
1. Check ESP32 serial monitor: `platformio device monitor`
2. Verify cough detection is working (check logs)
3. Verify backend receives data: `curl http://localhost:8080/api/cough/device/ESP32_COUGH_01`
4. Check Flutter app console for errors

---

## 📊 Complete System Verification

Once everything is running, verify:

### Backend Checklist:
- [ ] Backend server running on port 8080
- [ ] Health endpoint responds: `/api/cough/health`
- [ ] Security allows `/api/cough/**` without auth
- [ ] Database connected successfully

### ESP32 Checklist (Firmware Team):
- [ ] WiFi connected
- [ ] Backend API connected
- [ ] Microphone working
- [ ] Cough detection active
- [ ] Data sending successfully

### Frontend Checklist:
- [ ] App launches without errors
- [ ] Can navigate to Cough Analyzer screen
- [ ] Shows "LIVE" indicator
- [ ] Displays cough statistics
- [ ] Shows list of recent events
- [ ] Auto-refreshes every 5 seconds
- [ ] Pull-to-refresh works

---

## 🎯 Current Status

### ✅ Completed:
- Backend security configuration updated
- Frontend with real-time polling (every 5 seconds)
- API endpoints configured
- Models and services created

### ⏳ Pending (Firmware Team):
- ESP32 firmware upload
- WiFi configuration
- Hardware testing
- Real cough detection

---

## 📞 Next Steps

### For You:
1. ✅ Start backend: `cd backend && mvn spring-boot:run`
2. ✅ Test backend health check
3. ✅ Run frontend: `cd frontend && flutter run`
4. ⏳ Wait for firmware team to upload ESP32 code

### For Firmware Team:
1. Read `FIRMWARE_TEAM_SETUP.md`
2. Get your computer's IP address from you
3. Update ESP32 `config.h` file
4. Upload firmware to ESP32
5. Test cough detection

---

## 🚀 Once Everything is Running:

You should see:
```
Backend Terminal:
✅ Server running on port 8080
✅ Receiving cough events from ESP32

ESP32 Serial Monitor:
✅ WiFi connected
✅ Backend connected
✅ Listening for cough sounds...
🎤 Cough detected! Sending to backend...

Flutter App:
✅ LIVE indicator (green)
✅ Cough frequency: 15/hour
✅ Total: 45, Dry: 30, Wet: 15
✅ Recent events list updating
```

---

**System is fully operational when all 3 parts are running and communicating!** 🎉
