#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>

// --- TFLITE INCLUDES ---
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

// --- YOUR MODELS ---
#include "cough_model.h"
#include "fall_model.h"
#include "Protocentral_MAX30205.h"

// =========================================================
// 1. PIN DEFINITIONS & CONSTANTS
// =========================================================
// Temperature (I2C Bus 0)
#define PIN_TEMP_SDA 4
#define PIN_TEMP_SCL 5

// Motion (I2C Bus 1)
#define PIN_MOTION_SDA 15
#define PIN_MOTION_SCL 16

// Audio (I2S)
#define I2S_WS 42
#define I2S_SD 2
#define I2S_SCK 41
#define I2S_PORT I2S_NUM_0

// Heart (Analog)
#define PIN_ECG_OUT 1

// WiFi
const char *SSID_NAME = "Dialog 4G 437";
const char *WIFI_PASS = "20040920";
const char *SERVER_URL = "https://airea-production.up.railway.app/api/event";

// Thresholds
const float TEMP_HIGH_LIMIT = 37.5;
const float BPM_LOW_LIMIT = 45.0;
const float BPM_HIGH_LIMIT = 130.0;
const float RR_LOW_LIMIT = 8.0;
const float RR_HIGH_LIMIT = 30.0;
const float FALL_CONFIDENCE_THRESHOLD = 0.85;

// =========================================================
// 2. CLASS: BIO SENSORS (Temp, Heart, Resp)
// =========================================================
class BioMonitor
{
private:
    MAX30205 tempSensor;
    TwoWire *i2cBus;

    // ECG Variables
    float ecgEma = 0.0f;
    float bpm = 0.0f;
    unsigned long lastBeatMs = 0;
    float baselineEma = 0.0f;
    float respEma = 0.0f;
    float rr = 0.0f;
    unsigned long lastBreathMs = 0;

    // Internal Helper for Respiration
    bool detectPeak(float val, float &minVal, float &maxVal, unsigned long &lastReset, float thresholdRatio)
    {
        unsigned long now = millis();
        minVal = min(minVal, val);
        maxVal = max(maxVal, val);
        if (now - lastReset > 3000)
        { // Reset dynamic threshold periodically
            minVal = val;
            maxVal = val;
            lastReset = now;
        }
        float range = maxVal - minVal;
        return (val > (minVal + range * thresholdRatio));
    }

public:
    float currentTemp = 0.0;

    void begin(TwoWire &wireRef)
    {
        i2cBus = &wireRef;
        // Start Temp Sensor on the passed I2C bus
        if (!tempSensor.scanAvailableSensors())
        {
            Serial.println("⚠️ Temp Sensor not found on Bus 0");
        }
        pinMode(PIN_ECG_OUT, INPUT);
        analogReadResolution(12);
    }

    void update()
    {
        // --- 1. Temperature (Read less frequently, e.g., every 1s) ---
        static unsigned long lastTempRead = 0;
        if (millis() - lastTempRead > 1000)
        {
            currentTemp = tempSensor.getTemperature();
            lastTempRead = millis();
        }

        // --- 2. ECG & BPM Processing (Run every call) ---
        int raw = analogRead(PIN_ECG_OUT);

        // Signal Smoothing
        ecgEma = 0.15f * raw + 0.85f * ecgEma;

        // Simple Peak Detection for BPM
        static float sigMin = 4095, sigMax = 0;
        static unsigned long lastSigReset = 0;
        static bool beatWasHigh = false;

        bool beatHigh = detectPeak(ecgEma, sigMin, sigMax, lastSigReset, 0.70);

        if (beatHigh && !beatWasHigh)
        { // Rising edge
            if (millis() - lastBeatMs > 250)
            { // Debounce
                float instantBpm = 60000.0 / (millis() - lastBeatMs);
                if (instantBpm > 30 && instantBpm < 200)
                {
                    bpm = (bpm == 0) ? instantBpm : (0.8 * bpm + 0.2 * instantBpm);
                }
                lastBeatMs = millis();
            }
        }
        beatWasHigh = beatHigh;

        // --- 3. Respiration (Derived from Baseline Wander) ---
        baselineEma = 0.004f * raw + 0.996f * baselineEma;
        respEma = 0.05f * baselineEma + 0.95f * respEma;

        static float respMin = 1e9, respMax = -1e9;
        static unsigned long lastRespReset = 0;
        static bool respWasHigh = false;

        bool respHigh = detectPeak(respEma, respMin, respMax, lastRespReset, 0.60);
        if (respHigh && !respWasHigh)
        {
            if (millis() - lastBreathMs > 1000)
            {
                float instantRr = 60000.0 / (millis() - lastBreathMs);
                if (instantRr > 5 && instantRr < 60)
                {
                    rr = (rr == 0) ? instantRr : (0.85 * rr + 0.15 * instantRr);
                }
                lastBreathMs = millis();
            }
        }
        respWasHigh = respHigh;
    }

    // Getters for Vitals Check
    float getBPM() { return bpm; }
    float getRR() { return rr; }
    float getTemp() { return currentTemp; }
    bool isAbnormal()
    {
        return (currentTemp > TEMP_HIGH_LIMIT ||
                bpm < BPM_LOW_LIMIT || bpm > BPM_HIGH_LIMIT ||
                rr < RR_LOW_LIMIT || rr > RR_HIGH_LIMIT);
    }
};

// =========================================================
// 3. CLASS: FALL DETECTOR (MPU6050 + TFLite)
// =========================================================
class FallMonitor
{
private:
    TwoWire *i2cBus;
    uint8_t mpuAddr = 0x68;
    // TFLite globals
    tflite::MicroInterpreter *interpreter = nullptr;
    TfLiteTensor *input = nullptr;
    TfLiteTensor *output = nullptr;
    uint8_t *tensor_arena = nullptr;

    // Buffers
    const int TIME_STEPS = 200;
    const int NUM_FEATURES = 6;
    float *data_buffer = nullptr;
    int buffer_head = 0;

public:
    bool fallDetected = false;
    float confidence = 0.0;

    void begin(TwoWire &wireRef)
    {
        i2cBus = &wireRef;
        i2cBus->begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 400000); // High speed I2C

        // Init MPU
        writeMPU(0x6B, 0); // Wake up

        // Init TFLite
        static tflite::MicroErrorReporter micro_error_reporter;
        static tflite::MicroMutableOpResolver<35> resolver;
        // ... Add ops as per your original code ...
        resolver.AddFullyConnected();
        resolver.AddSoftmax();
        // (Add other ops here)

        const tflite::Model *model = tflite::GetModel(fall_model);

        const int kTensorArenaSize = 60 * 1024;
        tensor_arena = (uint8_t *)ps_malloc(kTensorArenaSize); // Use PSRAM if available

        static tflite::MicroInterpreter static_interpreter(
            model, resolver, tensor_arena, kTensorArenaSize, &micro_error_reporter);
        interpreter = &static_interpreter;
        interpreter->AllocateTensors();

        input = interpreter->input(0);
        output = interpreter->output(0);

        data_buffer = (float *)malloc(TIME_STEPS * NUM_FEATURES * sizeof(float));
    }

    void writeMPU(byte reg, byte data)
    {
        i2cBus->beginTransmission(mpuAddr);
        i2cBus->write(reg);
        i2cBus->write(data);
        i2cBus->endTransmission();
    }

    void update()
    {
        // Read MPU
        i2cBus->beginTransmission(mpuAddr);
        i2cBus->write(0x3B);
        i2cBus->endTransmission(false);
        i2cBus->requestFrom(mpuAddr, (uint8_t)14);

        if (i2cBus->available() == 14)
        {
            int16_t raw_ax = i2cBus->read() << 8 | i2cBus->read();
            int16_t raw_ay = i2cBus->read() << 8 | i2cBus->read();
            int16_t raw_az = i2cBus->read() << 8 | i2cBus->read();
            i2cBus->read();
            i2cBus->read(); // Temp
            int16_t raw_gx = i2cBus->read() << 8 | i2cBus->read();
            int16_t raw_gy = i2cBus->read() << 8 | i2cBus->read();
            int16_t raw_gz = i2cBus->read() << 8 | i2cBus->read();

            // Normalize & Buffer logic (Simplified for brevity)
            // ... [Insert your normalization code here] ...

            // Run Inference
            if (buffer_head >= TIME_STEPS)
            {
                // Copy buffer to input->data.f
                interpreter->Invoke();
                if (output->data.f[0] > FALL_CONFIDENCE_THRESHOLD)
                {
                    fallDetected = true;
                    confidence = output->data.f[0];
                }
            }
        }
    }

    void reset()
    {
        fallDetected = false;
        buffer_head = 0;
    }
};

// =========================================================
// 4. CLASS: EMERGENCY MANAGER (The Logic Glue)
// =========================================================
class EmergencyManager
{
private:
    BioMonitor *bio;
    FallMonitor *fall;
    bool alarmActive = false;

public:
    EmergencyManager(BioMonitor *b, FallMonitor *f) : bio(b), fall(f) {}

    void check()
    {
        // 1. Check for Fall
        if (fall->fallDetected && !alarmActive)
        {
            Serial.println("🚨 POTENTIAL FALL DETECTED! Checking Vitals...");

            // 2. Cross-Reference Vitals
            float t = bio->getTemp();
            float hr = bio->getBPM();
            float rr = bio->getRR();

            Serial.printf("   [VITALS] Temp: %.1f | HR: %.1f | RR: %.1f\n", t, hr, rr);

            if (bio->isAbnormal())
            {
                Serial.println("🚨 FALL CONFIRMED VIA VITALS! (Abnormal Readings)");
                alarmActive = true;
                sendAlert("FALL_CONFIRMED_CRITICAL");
            }
            else
            {
                Serial.println("⚠️ Fall Detected but Vitals Stable. Low Priority Alert.");
                sendAlert("FALL_DETECTED_STABLE");
                alarmActive = true; // Still alert, but maybe different level
            }
        }
    }

    void sendAlert(String type)
    {
        if (WiFi.status() == WL_CONNECTED)
        {
            WiFiClientSecure client;
            client.setInsecure();
            HTTPClient http;
            if (http.begin(client, SERVER_URL))
            {
                http.addHeader("Content-Type", "application/json");
                String json = "{\"type\":\"" + type + "\", \"bpm\":" + String(bio->getBPM()) + "}";
                http.POST(json);
                http.end();
            }
        }
    }
};

// =========================================================
// 5. GLOBAL OBJECTS
// =========================================================
BioMonitor bioMonitor;
FallMonitor fallMonitor;
EmergencyManager emergency(&bioMonitor, &fallMonitor);

// Secondary I2C Bus for MPU6050
TwoWire I2C_Motion = TwoWire(1);

// =========================================================
// 6. COUGH DETECTION TASK (Runs on Core 0)
// =========================================================
// We keep this as a FreeRTOS task because audio sampling must not be interrupted.
void TaskCough(void *pvParameters)
{
    // ... [Insert your Setup code for I2S and TFLite Audio here] ...
    // Note: Ensure you use the I2S pins: SCK 41, WS 42, SD 2

    while (true)
    {
        // ... [Insert your Audio Loop Code here] ...
        // If cough detected -> sendAlert("COUGH");
        vTaskDelay(10);
    }
}

// =========================================================
// 7. MAIN SETUP & LOOP
// =========================================================
void setup()
{
    Serial.begin(115200);

    // 1. Connect WiFi
    WiFi.begin(SSID_NAME, WIFI_PASS);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi Connected.");

    // 2. Initialize Buses
    Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL); // Default Wire for Temp

    // 3. Initialize Modules
    bioMonitor.begin(Wire);
    fallMonitor.begin(I2C_Motion); // Pass the secondary Wire bus

    // 4. Start Cough Task on Core 0
    xTaskCreatePinnedToCore(
        TaskCough, "CoughAI", 8192, NULL, 1, NULL, 0);

    Serial.println("System Active.");
}

void loop()
{
    // Run Bio and Fall updates on Core 1 (Main Loop)
    bioMonitor.update();
    fallMonitor.update();

    // Check Logic
    emergency.check();

    // Small delay to prevent watchdog starvation
    delay(5);
}