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

// --- YOUR MODELS & LIBRARIES ---
#include "cough_model.h"
#include "fall_model.h"
#include "Protocentral_MAX30205.h"

// =========================================================
// 1. PIN DEFINITIONS & CONSTANTS
// =========================================================
#define PIN_TEMP_SDA 4
#define PIN_TEMP_SCL 5
#define PIN_MOTION_SDA 15
#define PIN_MOTION_SCL 16
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
// 2. CLASS: BIO SENSORS
// =========================================================
class BioMonitor
{
private:
    MAX30205 tempSensor;
    float bpm = 0, rr = 0;

public:
    float currentTemp = 0.0;

    void begin(TwoWire &wireRef)
    {
        if (!tempSensor.scanAvailableSensors())
        {
            Serial.println("⚠️ Temp Sensor (MAX30205) not found on Bus 0!");
        }
        pinMode(PIN_ECG_OUT, INPUT);
        analogReadResolution(12);
    }

    void update()
    {
        static unsigned long lastTempRead = 0;
        if (millis() - lastTempRead > 1000)
        {
            currentTemp = tempSensor.getTemperature();
            lastTempRead = millis();
        }
        // ECG/BPM logic remains the same as your draft...
    }

    float getBPM() { return bpm; }
    float getRR() { return rr; }
    float getTemp() { return currentTemp; }
    bool isAbnormal()
    {
        return (currentTemp > TEMP_HIGH_LIMIT || bpm < BPM_LOW_LIMIT || bpm > BPM_HIGH_LIMIT);
    }
};

// =========================================================
// 3. CLASS: FALL DETECTOR (The Fixes)
// =========================================================
class FallMonitor
{
private:
    TwoWire *i2cBus;
    tflite::MicroInterpreter *interpreter = nullptr;
    TfLiteTensor *input = nullptr;
    TfLiteTensor *output = nullptr;
    uint8_t *tensor_arena = nullptr;
    const int kTensorArenaSize = 40 * 1024; // Fits in SRAM

public:
    bool fallDetected = false;

    void begin(TwoWire &wireRef)
    {
        i2cBus = &wireRef;
        i2cBus->begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 400000);

        static tflite::MicroErrorReporter micro_error_reporter;

        // FIX: Manually adding ExpandDims and enough ops for the Fall Model
        static tflite::MicroMutableOpResolver<10> resolver;
        resolver.AddFullyConnected();
        resolver.AddSoftmax();
        resolver.AddReshape();
        resolver.AddExpandDims(); // FIX: The missing opcode

        const tflite::Model *model = tflite::GetModel(fall_model);

        // FIX: Using malloc (Internal RAM) because your board has No PSRAM
        tensor_arena = (uint8_t *)malloc(kTensorArenaSize);
        if (!tensor_arena)
        {
            Serial.println("Panic: Could not allocate Fall Arena in SRAM!");
            return;
        }

        static tflite::MicroInterpreter static_interpreter(
            model, resolver, tensor_arena, kTensorArenaSize, &micro_error_reporter);

        interpreter = &static_interpreter;
        if (interpreter->AllocateTensors() != kTfLiteOk)
        {
            Serial.println("Fall Tensors Allocation Failed!");
            return;
        }
        input = interpreter->input(0);
        output = interpreter->output(0);
    }

    void update()
    {
        // MPU6050 Reading & Normalization logic...
    }
};

// =========================================================
// 4. GLOBAL OBJECTS & EMERGENCY
// =========================================================
BioMonitor bioMonitor;
FallMonitor fallMonitor;
TwoWire I2C_Motion = TwoWire(1);

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
            String json = "{\"type\":\"" + type + "\", \"temp\":" + String(bioMonitor.getTemp()) + "}";
            http.POST(json);
            http.end();
        }
    }
}

// =========================================================
// 5. COUGH DETECTION (Core 0 Task)
// =========================================================
void TaskCough(void *pvParameters)
{
    static tflite::MicroErrorReporter cough_reporter;
    static tflite::MicroMutableOpResolver<10> cough_res;
    cough_res.AddConv2D();
    cough_res.AddExpandDims(); // FIX: Opcode for Audio Model

    uint8_t *cough_arena = (uint8_t *)malloc(32 * 1024);

    // I2S Initialization logic goes here...

    for (;;)
    {
        // Run Audio Inference
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
    WiFi.begin(SSID_NAME, WIFI_PASS);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\nWiFi Connected.");

    // 2. Initialize I2C Buses
    Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL);

    // 3. Initialize Monitors
    bioMonitor.begin(Wire);
    fallMonitor.begin(I2C_Motion);

    // 4. Start AI Task on Core 0
    xTaskCreatePinnedToCore(TaskCough, "CoughAI", 8192, NULL, 1, NULL, 0);

    Serial.println("Airea System Online.");
}

void loop()
{
    bioMonitor.update();
    fallMonitor.update();

    if (fallMonitor.fallDetected)
    {
        sendAlert("FALL_DETECTED");
        fallMonitor.fallDetected = false;
    }

    delay(5); // Keep watchdog happy
}