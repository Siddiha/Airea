#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <driver/i2s.h>

// --- TFLITE INCLUDES ---
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

// --- YOUR MODELS & LIBRARIES ---
#include "cough_model.h"
#include "fall_model.h"
#include "Protocentral_MAX30205.h"

// =========================================================
// 1. PIN DEFINITIONS
// =========================================================
#define PIN_TEMP_SDA 17
#define PIN_TEMP_SCL 18
#define PIN_MOTION_SDA 15
#define PIN_MOTION_SCL 16

#define I2S_WS 42
#define I2S_SD 2
#define I2S_SCK 41
#define I2S_PORT I2S_NUM_0

#define PIN_ECG_OUT 1
#define PIN_ECG_LO_PLUS 6
#define PIN_ECG_LO_MINUS 7

const char *SSID_NAME = "Dialog 4G 437";
const char *WIFI_PASS = "20040920";
const char *SERVER_URL = "https://airea-production.up.railway.app/api/event";

// =========================================================
// 2. CLASS: BIO SENSORS (Temp, ECG Heart Rate, ECG Resp Rate)
// =========================================================
class BioMonitor
{
private:
    MAX30205 tempSensor;

    // Heart Rate Variables
    float bpm = 0;
    unsigned long lastBeatMs = 0;
    float ecgEma = 0.0f;

    // Respiratory Rate Variables
    float rr = 0;
    unsigned long lastBreathMs = 0;
    float baselineEma = 0.0f;
    float respEma = 0.0f;

    bool detectPeak(float val, float &minVal, float &maxVal, unsigned long &lastReset, float thresholdRatio, unsigned long timeout)
    {
        unsigned long now = millis();
        minVal = min(minVal, val);
        maxVal = max(maxVal, val);
        if (now - lastReset > timeout)
        {
            minVal = val;
            maxVal = val;
            lastReset = now;
        }
        float range = maxVal - minVal;
        return (val > (minVal + range * thresholdRatio));
    }

public:
    float currentTemp = 0.0;
    bool leadsAreOff = true;

    void begin()
    {
        pinMode(PIN_ECG_OUT, INPUT);
        pinMode(PIN_ECG_LO_PLUS, INPUT);
        pinMode(PIN_ECG_LO_MINUS, INPUT);
        analogReadResolution(12);

        Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000);
        delay(100);

        if (!tempSensor.scanAvailableSensors())
        {
            Serial.println("⚠️ Temp Sensor not found! Check wiring.");
            Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000);
        }
        else
        {
            Serial.println("✅ MAX30205 Temp Sensor Ready!");
        }
    }

    void update()
    {
        // --- 1. Temperature ---
        static unsigned long lastTempRead = 0;
        if (millis() - lastTempRead > 1000)
        {
            Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000);
            currentTemp = tempSensor.getTemperature();
            lastTempRead = millis();
        }

        // --- 2. ECG Leads Off Check ---
        if (digitalRead(PIN_ECG_LO_PLUS) == 1 || digitalRead(PIN_ECG_LO_MINUS) == 1)
        {
            leadsAreOff = true;
            bpm = 0;
            rr = 0; // Reset Respiration if pads are off
            return;
        }
        else
        {
            leadsAreOff = false;
        }

        int raw = analogRead(PIN_ECG_OUT);

        // --- 3. Heart Rate (BPM) Processing ---
        ecgEma = 0.15f * raw + 0.85f * ecgEma; // Fast filter for sharp QRS peaks

        static float bpmMin = 4095, bpmMax = 0;
        static unsigned long lastBpmReset = 0;
        static bool beatWasHigh = false;

        bool beatHigh = detectPeak(ecgEma, bpmMin, bpmMax, lastBpmReset, 0.70, 3000);

        if (beatHigh && !beatWasHigh)
        {
            if (millis() - lastBeatMs > 250)
            { // Max 240 BPM debounce
                float instantBpm = 60000.0 / (millis() - lastBeatMs);
                if (instantBpm > 30 && instantBpm < 200)
                {
                    bpm = (bpm == 0) ? instantBpm : (0.8 * bpm + 0.2 * instantBpm);
                }
                lastBeatMs = millis();
            }
        }
        beatWasHigh = beatHigh;

        // --- 4. Respiratory Rate (RR) Processing ---
        // Isolate the slow baseline wander caused by breathing
        baselineEma = 0.004f * raw + 0.996f * baselineEma;
        respEma = 0.05f * baselineEma + 0.95f * respEma;

        static float respMin = 4095, respMax = 0;
        static unsigned long lastRespReset = 0;
        static bool respWasHigh = false;

        // Breaths are slower, so we use a longer timeout (8000ms) for the dynamic threshold
        bool respHigh = detectPeak(respEma, respMin, respMax, lastRespReset, 0.60, 8000);

        if (respHigh && !respWasHigh)
        {
            if (millis() - lastBreathMs > 1000)
            { // Max 60 breaths/min debounce
                float instantRr = 60000.0 / (millis() - lastBreathMs);
                if (instantRr > 5 && instantRr < 40)
                { // Normal resting RR is 12-20
                    rr = (rr == 0) ? instantRr : (0.85 * rr + 0.15 * instantRr);
                }
                lastBreathMs = millis();
            }
        }
        respWasHigh = respHigh;
    }

    float getBPM() { return bpm; }
    float getRR() { return rr; } // New Getter
    float getTemp() { return currentTemp; }
};
// =========================================================
// 3. CLASS: FALL DETECTOR (DISABLED FOR COMPETITION)
// =========================================================
class FallMonitor
{
public:
    bool fallDetected = false;
    void begin(TwoWire &wireRef)
    {
        Serial.println("⏸️ Fall Monitor Disabled for Competition.");
    }
    void update()
    {
        // Skipped
    }
};

// =========================================================
// 4. GLOBAL OBJECTS & API SYNC
// =========================================================
BioMonitor bioMonitor;
FallMonitor fallMonitor; // Kept in memory but inactive
TwoWire I2C_Motion = TwoWire(1);

// Send periodic vitals to the frontend
void sendVitals()
{
    if (WiFi.status() == WL_CONNECTED)
    {
        WiFiClientSecure client;
        client.setInsecure();
        HTTPClient http;
        if (http.begin(client, SERVER_URL))
        {
            http.addHeader("Content-Type", "application/json");

            // Build the JSON payload for Temp and ECG
            String json = "{\"type\":\"VITALS_UPDATE\", ";
            json += "\"temp\":" + String(bioMonitor.getTemp()) + ", ";
            json += "\"bpm\":" + String(bioMonitor.getBPM()) + ", ";
            json += "\"leads_off\":" + String(bioMonitor.leadsAreOff ? "true" : "false") + "}";

            int httpResponseCode = http.POST(json);
            if (httpResponseCode > 0)
            {
                Serial.println("🌐 Frontend Synced: " + json);
            }
            http.end();
        }
    }
}

// Send urgent alerts (like a Cough)
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
            String json = "{\"type\":\"" + type + "\"}";
            http.POST(json);
            http.end();
        }
    }
}

// =========================================================
// 5. COUGH DETECTION (Core 0 Audio Task)
// =========================================================
void TaskCough(void *pvParameters)
{
    Serial.println("🎙️ Audio AI Task Started");

    // [Insert your working I2S & TFLite setup here]

    for (;;)
    {
        // [Insert your working inference loop here]

        // Example: If cough detected, trigger the frontend
        // sendAlert("COUGH_DETECTED");

        vTaskDelay(pdMS_TO_TICKS(10));
    }
}

// =========================================================
// 6. MAIN SETUP & LOOP
// =========================================================
void setup()
{
    Serial.begin(115200);

    // 1. WiFi
    Serial.print("Connecting to WiFi...");
    WiFi.begin(SSID_NAME, WIFI_PASS);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\n✅ WiFi Connected.");

    // 2. Start BioMonitor
    bioMonitor.begin();

    // 3. Start FallMonitor (Currently does nothing to save RAM)
    fallMonitor.begin(I2C_Motion);

    // 4. Start Cough Task on Core 0
    xTaskCreatePinnedToCore(TaskCough, "CoughAI", 8192, NULL, 1, NULL, 0);

    Serial.println("🚀 Airea System Competition Ready!");
}

void loop()
{
    // 1. Constantly read the Temp and ECG sensors
    bioMonitor.update();

    // 2. Push live data to frontend every 5 seconds
    static unsigned long lastApiSync = 0;
    if (millis() - lastApiSync > 5000)
    {
        sendVitals();
        lastApiSync = millis();
    }

    delay(5);
}