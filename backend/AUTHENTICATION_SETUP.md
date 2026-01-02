# Airea Backend - Authentication Setup Guide

## 🔐 Overview

This guide explains how to set up JWT-based authentication for the Airea IoT cough detection system.

---

## 📋 **What Was Implemented**

### ✅ **Backend Security Features:**
1. **JWT Token Authentication** - Secure token-based auth
2. **Device API Keys** - Long-lived keys for IoT devices
3. **Password Hashing** - BCrypt encryption for API keys
4. **Rate Limiting** - 100 requests/minute per IP
5. **CORS Protection** - Configurable allowed origins
6. **Secure Headers** - Authorization, Content-Type validation

### ✅ **New Endpoints:**
- `POST /api/auth/generate-key/{deviceId}` - Generate API key for device
- `POST /api/auth/login` - Login and get JWT token
- `DELETE /api/auth/revoke/{deviceId}` - Revoke device API key
- `GET /api/auth/health` - Auth service health check

### ✅ **Protected Endpoints:**
All endpoints now require authentication **EXCEPT**:
- `/api/auth/**` - Authentication endpoints
- `/api/cough/health` - Health check
- `/ws/**` - WebSocket connections
- `/error` - Error page

---

## 🚀 **Setup Instructions**

### **Step 1: Configure Environment Variables**

Create a `.env` file in the backend root (if not exists):

```env
# Database
SUPABASE_URL=jdbc:postgresql://your-supabase-url:5432/postgres
SUPABASE_USERNAME=postgres
SUPABASE_PASSWORD=your_password

# JWT Secret (CHANGE THIS!)
JWT_SECRET=your-super-secret-key-at-least-256-bits-long-change-in-production

# CORS (Comma-separated origins)
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080,http://localhost:5173
```

⚠️ **IMPORTANT**: Generate a strong JWT secret:
```bash
# Generate random 256-bit secret
openssl rand -base64 64
```

---

### **Step 2: Build and Run Backend**

```bash
cd backend
mvn clean install
mvn spring-boot:run
```

Backend will start on `http://localhost:8080`

---

### **Step 3: Register a Device**

First, register your ESP32 device:

```bash
curl -X POST http://localhost:8080/api/device/register \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ESP32_COUGH_01",
    "deviceName": "Bedroom Cough Monitor",
    "location": "Master Bedroom"
  }'
```

Response:
```json
{
  "id": "uuid-here",
  "deviceId": "ESP32_COUGH_01",
  "deviceName": "Bedroom Cough Monitor",
  "location": "Master Bedroom",
  "isActive": true,
  "createdAt": "2025-01-02T10:00:00Z"
}
```

---

### **Step 4: Generate API Key**

Generate a long-lived API key for the device:

```bash
curl -X POST http://localhost:8080/api/auth/generate-key/ESP32_COUGH_01
```

Response:
```json
{
  "deviceId": "ESP32_COUGH_01",
  "apiKey": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJFU1AzMl9DT1VHSF8wMSIsInR5cGUiOiJBUElfS0VZIiwiaWF0IjoxNzM1ODE2MDAwLCJleHAiOjE3NjczNTIwMDB9.xxx",
  "message": "IMPORTANT: Save this API key securely. It will not be shown again!"
}
```

⚠️ **CRITICAL**: Save this API key - it won't be shown again!

---

### **Step 5: Login to Get JWT Token**

Use the API key to login and get a JWT token:

```bash
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "deviceId": "ESP32_COUGH_01",
    "apiKey": "YOUR_API_KEY_FROM_STEP_4"
  }'
```

Response:
```json
{
  "token": "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJFU1AzMl9DT1VHSF8wMSIsImlhdCI6MTczNTgxNjAwMCwiZXhwIjoxNzM1OTAyNDAwfQ.xxx",
  "deviceId": "ESP32_COUGH_01",
  "tokenType": "Bearer",
  "expiresIn": 86400
}
```

---

### **Step 6: Update ESP32 Firmware**

1. Open `esp32_firmware/src/main.cpp`
2. Update the configuration:

```cpp
// SERVER URL (Backend API endpoint)
const char *serverUrl = "http://192.168.1.100:8080/api/cough/event";  // Your computer's IP

// AUTHENTICATION
const char *jwtToken = "YOUR_JWT_TOKEN_FROM_STEP_5";  // Paste token here
```

3. Find your computer's IP:
```bash
# Windows
ipconfig

# Linux/Mac
ifconfig
```

4. Upload to ESP32:
```bash
cd esp32_firmware
pio run --target upload
```

---

### **Step 7: Test Authentication**

Send a test cough event with authentication:

```bash
curl -X POST http://localhost:8080/api/cough/event \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "deviceId": "ESP32_COUGH_01",
    "coughType": "unknown",
    "confidence": 0.95,
    "rawScore": 0.95,
    "timestamp": 1735816000000,
    "audioVolume": 1234.5
  }'
```

Success Response (HTTP 201):
```json
{
  "id": "uuid",
  "deviceId": "ESP32_COUGH_01",
  "coughType": "unknown",
  "confidence": 0.95,
  "timestamp": "2025-01-02T10:00:00Z",
  "createdAt": "2025-01-02T10:00:00Z"
}
```

---

## 🔄 **Token Lifecycle**

### **JWT Token:**
- **Validity**: 24 hours (86400 seconds)
- **Use**: Sent with every API request
- **Renewal**: Login again when expired

### **API Key:**
- **Validity**: 1 year
- **Use**: Login to get JWT tokens
- **Storage**: Hashed in database (BCrypt)

### **Token Expiration Flow:**
```
1. ESP32 sends request with expired JWT
   ↓
2. Backend returns 401 Unauthorized
   ↓
3. ESP32 automatically re-authenticates with API key
   ↓
4. Backend returns new JWT token
   ↓
5. ESP32 retries request with new token
```

---

## 🛡️ **Security Best Practices**

### ✅ **DO:**
1. Store JWT secret in `.env` file (never commit to git)
2. Use strong, random JWT secrets (256+ bits)
3. Rotate API keys every 6-12 months
4. Use HTTPS in production
5. Restrict CORS to specific domains
6. Monitor rate limit violations

### ❌ **DON'T:**
1. Hardcode JWT secrets in code
2. Share API keys publicly
3. Allow `*` for CORS in production
4. Disable authentication in production
5. Use weak or predictable secrets

---

## 🔧 **Troubleshooting**

### **Problem: "Invalid credentials"**
```
Cause: Wrong API key or device not registered
Fix: Re-generate API key via /api/auth/generate-key/{deviceId}
```

### **Problem: "Device is deactivated"**
```
Cause: Device marked as inactive in database
Fix: Activate device via /api/device/{deviceId} with {"isActive": true}
```

### **Problem: "Too many requests"**
```
Cause: Rate limit exceeded (100 requests/minute)
Fix: Wait 1 minute or increase limit in RateLimitingFilter.java
```

### **Problem: "CORS error"**
```
Cause: Frontend origin not in allowed list
Fix: Add origin to CORS_ALLOWED_ORIGINS in .env
```

### **Problem: "JWT token expired"**
```
Cause: Token older than 24 hours
Fix: Login again to get a new token
```

---

## 📊 **Rate Limiting**

Current limit: **100 requests/minute per IP**

To change:
1. Open `filter/RateLimitingFilter.java`
2. Modify line:
```java
private final Bandwidth limit = Bandwidth.classic(100, Refill.intervally(100, Duration.ofMinutes(1)));
```

Example: 500 requests per 5 minutes:
```java
private final Bandwidth limit = Bandwidth.classic(500, Refill.intervally(500, Duration.ofMinutes(5)));
```

---

## 🔐 **Revoking Access**

### **Revoke API Key:**
```bash
curl -X DELETE http://localhost:8080/api/auth/revoke/ESP32_COUGH_01
```

### **Deactivate Device:**
```bash
curl -X DELETE http://localhost:8080/api/device/ESP32_COUGH_01
```

---

## 📝 **Example: Complete Flow**

```bash
# 1. Register device
curl -X POST http://localhost:8080/api/device/register \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"ESP32_COUGH_01","deviceName":"Living Room"}'

# 2. Generate API key
curl -X POST http://localhost:8080/api/auth/generate-key/ESP32_COUGH_01

# 3. Login with API key
curl -X POST http://localhost:8080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"deviceId":"ESP32_COUGH_01","apiKey":"YOUR_API_KEY"}'

# 4. Use JWT token in requests
curl -X GET http://localhost:8080/api/cough/device/ESP32_COUGH_01 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## 🎯 **Production Checklist**

- [ ] Generate strong JWT secret (256+ bits)
- [ ] Store secrets in `.env` (not in git)
- [ ] Enable HTTPS/TLS
- [ ] Restrict CORS to specific domains
- [ ] Set up API key rotation policy
- [ ] Monitor authentication failures
- [ ] Set up alert thresholds
- [ ] Enable audit logging
- [ ] Configure backup authentication
- [ ] Test token expiration handling

---

## 📚 **API Reference**

| Endpoint | Method | Auth Required | Description |
|----------|--------|---------------|-------------|
| `/api/auth/generate-key/{deviceId}` | POST | ❌ No | Generate API key |
| `/api/auth/login` | POST | ❌ No | Login with API key |
| `/api/auth/revoke/{deviceId}` | DELETE | ❌ No | Revoke API key |
| `/api/auth/health` | GET | ❌ No | Health check |
| `/api/cough/event` | POST | ✅ Yes | Submit cough event |
| `/api/cough/device/{deviceId}` | GET | ✅ Yes | Get cough events |
| `/api/cough/stats/{deviceId}/hour` | GET | ✅ Yes | Hourly stats |
| `/api/device/register` | POST | ❌ No | Register device |
| `/api/device/{deviceId}` | GET | ✅ Yes | Get device info |

---

## 🆘 **Support**

For issues or questions:
1. Check logs: `tail -f logs/spring.log`
2. Test health endpoint: `curl http://localhost:8080/api/auth/health`
3. Verify JWT secret is set in `.env`
4. Check CORS configuration
5. Review rate limit settings

---

**Generated**: 2025-01-02
**Version**: 1.0.0
**Status**: ✅ Production Ready
