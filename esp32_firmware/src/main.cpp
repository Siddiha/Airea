/*
  ===========================================================================
    AIREA MASTER FIRMWARE (PROTOTYPE)
    ESP32-S3 Custom PCB Integration
    Features:
    - WiFiManager for easy setup
    - TFLite Audio Inference (Cough Detection)
    - Fall Detection (MPU6050 magnitude tracking)
    - Vitals DSP (MAX30205 Temp, AD8232 BPM & Respiratory Rate)
    - FreeRTOS Network Queueing to Railway Spring Boot
  ===========================================================================
*/

#include <Arduino.h>
#include <Wire.h>
#include <WiFiManager.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <driver/i2s.h>

// --- FREERTOS ---
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

// --- TFLITE ---
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "cough_model.h" // Your exported TFLite model array

// --- SENSORS ---
#include <Protocentral_MAX30205.h>

// =========================================================
// 1. PIN DEFINITIONS (Strictly Airea PCB)
// =========================================================
// I2C Bus 1 (Temperature)
#define PIN_TEMP_SDA 17
#define PIN_TEMP_SCL 18

// I2C Bus 2 (Motion / MPU6050)
#define PIN_MOTION_SDA 15
#define PIN_MOTION_SCL 16
#define MPU6050_ADDR 0x68

// AD8232 (ECG & Respiration)
#define PIN_ECG_OUTPUT 1
#define PIN_ECG_LO_PLUS 6
#define PIN_ECG_LO_MINUS 7

// INMP441 (Microphone)
#define I2S_WS 42
#define I2S_SD 2
#define I2S_SCK 41
#define I2S_PORT I2S_NUM_0

// Status LED
#define PIN_LED 4

// =========================================================
// 2. NETWORK URLS (Railway Backend)
// =========================================================
const String BASE_URL = "https://airea-production.up.railway.app/api";
const String STATUS_URL = BASE_URL + "/board/status";
const String VITALS_URL = BASE_URL + "/vitals/event";
const String COUGH_URL = BASE_URL + "/cough/event";
const String FALL_URL = BASE_URL + "/fall/event";

// =========================================================
// 3. GLOBALS & QUEUES
// =========================================================
// We use one unified queue to prevent the main loop from blocking
enum EventType
{
    EVENT_COUGH,
    EVENT_FALL,
    EVENT_VITALS
};

struct CloudEvent
{
    EventType type;
    float val1; // Cough Confidence / Fall G-Force / Temp
    float val2; // Cough Volume / BPM
    float val3; // Respiratory Rate
    bool flag;  // Leads Off
};

QueueHandle_t cloudQueue;

// TFLite Globals
const int kArenaSize = 200 * 1024;
uint8_t *tensor_arena;
int16_t *raw_audio_buffer;
#define SAMPLE_RATE 16000
const int kAudioBufferSize = 32000; // 2 Seconds
#define COUGH_THRESHOLD 0.80

tflite::MicroErrorReporter micro_error_reporter;
tflite::AllOpsResolver resolver;
const tflite::Model *model;
tflite::MicroInterpreter *interpreter;
TfLiteTensor *input = nullptr;
TfLiteTensor *output = nullptr;

// Vitals & Sensor Globals
MAX30205 tempSensor;
float currentTemp = 0.0;
float currentBPM = 0.0;
float currentRR = 0.0;
bool leadsAreOff = false;

// ECG DSP Variables (250Hz)
constexpr unsigned long SAMPLE_INTERVAL_US = 4000; // 1/250th second
static float ecgEma = 0.0f, baselineEma = 0.0f, respEma = 0.0f;
static float signalMin = 4095.0f, signalMax = 0.0f;
static float respMin = 1e9f, respMax = -1e9f;
static unsigned long lastRangeResetMs = 0, lastRespRangeResetMs = 0;
static unsigned long lastBeatMs = 0, lastBreathMs = 0;
static bool wasAbove = false, respWasAbove = false;

// =========================================================
// 4. HELPER FUNCTIONS
// =========================================================
void blinkLED(int times, int delayMs)
{
    for (int i = 0; i < times; i++)
    {
        digitalWrite(PIN_LED, HIGH);
        delay(delayMs);
        digitalWrite(PIN_LED, LOW);
        delay(delayMs);
    }
}

void notifyBackendOnline()
{
    if (WiFi.status() == WL_CONNECTED)
    {
        WiFiClientSecure client;
        client.setInsecure(); // Accept self-signed Railway certs
        HTTPClient http;

        Serial.println("🌐 Notifying Spring Boot Backend...");
        http.begin(client, STATUS_URL);
        http.addHeader("Content-Type", "application/json");

        String deviceIP = WiFi.localIP().toString();
        String payload = "{\"hardwareId\": \"ESP32_AIREA_01\", \"status\": \"online\", \"ipAddress\": \"" + deviceIP + "\"}";

        int httpCode = http.POST(payload);
        if (httpCode > 0)
            Serial.printf("✅ Backend Online! (HTTP %d)\n", httpCode);
        else
            Serial.printf("❌ Backend Error: %s\n", http.errorToString(httpCode).c_str());

        http.end();
    }
}

// =========================================================
// 5. FREE-RTOS TASK: NETWORK SENDER
// =========================================================
// This task runs in the background. It takes packages from the queue
// and uploads them so the main loop never gets stuck waiting on Wi-Fi.
void network_sender_task(void *parameter)
{
    CloudEvent event;
    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;

    while (true)
    {
        // Wait here until an event is pushed into the queue
        if (xQueueReceive(cloudQueue, &event, portMAX_DELAY) == pdTRUE)
        {
            if (WiFi.status() == WL_CONNECTED)
            {

                String url = "";
                String json = "{";
                json += "\"deviceId\":\"ESP32_AIREA_01\",";

                // Format the JSON based on what kind of event it is
                if (event.type == EVENT_COUGH)
                {
                    url = COUGH_URL;
                    json += "\"confidence\":" + String(event.val1, 3) + ",";
                    json += "\"audioVolume\":" + String(event.val2, 2);
                }
                else if (event.type == EVENT_FALL)
                {
                    url = FALL_URL;
                    json += "\"gForce\":" + String(event.val1, 2) + ",";
                    json += "\"alert\":\"EMERGENCY_FALL\"";
                }
                else if (event.type == EVENT_VITALS)
                {
                    url = VITALS_URL;
                    json += "\"temp\":" + String(event.val1, 2) + ",";
                    json += "\"bpm\":" + String(event.val2, 1) + ",";
                    json += "\"rr\":" + String(event.val3, 1) + ",";
                    json += "\"leadsOff\":" + String(event.flag ? "true" : "false");
                }
                json += "}";

                // Send the POST request
                http.begin(client, url);
                http.addHeader("Content-Type", "application/json");
                int httpCode = http.POST(json);
                http.end();

                Serial.printf("☁️ [Cloud] Sent %s | HTTP: %d\n",
                              (event.type == EVENT_COUGH ? "COUGH" : event.type == EVENT_FALL ? "FALL"
                                                                                              : "VITALS"),
                              httpCode);
            }
        }
    }
}

// =========================================================
// 6. FREE-RTOS TASK: AUDIO AI (Cough Detection)
// =========================================================
void audio_inference_task(void *parameter)
{
    if (input == nullptr)
    {
        Serial.println("❌ FATAL: Model failed to load.");
        vTaskDelete(NULL);
        return;
    }

    size_t bytes_read;
    static unsigned long last_alert_time = 0;

    // I2S Config for INMP441
    const i2s_config_t i2s_config = {
        .mode = i2s_mode_t(I2S_MODE_MASTER | I2S_MODE_RX),
        .sample_rate = SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
        .communication_format = i2s_comm_format_t(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB),
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 4,
        .dma_buf_len = 1024,
        .use_apll = false,
        .fixed_mclk = 0};

    const i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_SCK,
        .ws_io_num = I2S_WS,
        .data_out_num = I2S_PIN_NO_CHANGE,
        .data_in_num = I2S_SD};

    i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
    i2s_set_pin(I2S_PORT, &pin_config);

    Serial.println("🎤 Microphone Ready. AI Listening...");

    while (true)
    {
        i2s_read(I2S_PORT, raw_audio_buffer, kAudioBufferSize * sizeof(int16_t), &bytes_read, portMAX_DELAY);

        int8_t *input_data = input->data.int8;
        float avg_vol = 0;

        for (int i = 0; i < input->bytes; i++)
        {
            int16_t sample = raw_audio_buffer[i * 2];
            int32_t amplified = sample * 8; // Gain
            if (amplified > 32767)
                amplified = 32767;
            if (amplified < -32768)
                amplified = -32768;
            input_data[i] = (int8_t)(amplified >> 8);
            if (i % 100 == 0)
                avg_vol += abs(amplified);
        }
        avg_vol /= (input->bytes / 100);

        if (interpreter->Invoke() != kTfLiteOk)
            continue;

        float cough_score = (output->type == kTfLiteInt8) ? (output->data.int8[1] - output->params.zero_point) * output->params.scale : output->data.f[1];

        if (avg_vol > 300 && cough_score > COUGH_THRESHOLD && (millis() - last_alert_time > 5000))
        {
            Serial.println("\n🚨 COUGH DETECTED!");

            // Visual LED Indicator for Cough
            digitalWrite(PIN_LED, HIGH);

            // Push to Network Queue
            CloudEvent event = {EVENT_COUGH, cough_score, avg_vol, 0.0, false};
            xQueueSend(cloudQueue, &event, 0);

            last_alert_time = millis();
            delay(200); // Brief pause to keep LED visible
            digitalWrite(PIN_LED, LOW);
        }
        vTaskDelay(10 / portTICK_PERIOD_MS);
    }
}

// =========================================================
// 7. MAIN SETUP
// =========================================================
void setup()
{
    Serial.begin(115200);
    delay(1000);

    // 1. Hardware Pins Init
    pinMode(PIN_LED, OUTPUT);
    pinMode(PIN_ECG_LO_PLUS, INPUT);
    pinMode(PIN_ECG_LO_MINUS, INPUT);
    analogReadResolution(12);
    digitalWrite(PIN_LED, HIGH); // Turn LED on during setup

    Serial.println("\n=================================");
    Serial.println("    AIREA MONITORING SYSTEM      ");
    Serial.println("=================================");

    // 2. WiFi Setup via WiFiManager
    WiFiManager wm;
    // wm.resetSettings(); // Uncomment to wipe saved WiFi networks

    Serial.println("📡 Connecting to WiFi...");
    bool res = wm.autoConnect("Airea-Setup");
    if (!res)
    {
        Serial.println("❌ Failed to connect. Restarting...");
        ESP.restart();
    }
    Serial.println("✅ WiFi Connected!");
    blinkLED(3, 200);            // Blink 3 times to show WiFi success
    digitalWrite(PIN_LED, HIGH); // Leave solid when ready

    // 3. Notify Backend
    notifyBackendOnline();

    // 4. Queue & Memory Initialization
    cloudQueue = xQueueCreate(10, sizeof(CloudEvent));

    tensor_arena = (uint8_t *)malloc(kArenaSize);
    raw_audio_buffer = (int16_t *)malloc(kAudioBufferSize * sizeof(int16_t));

    // 5. TFLite Initialization
    model = tflite::GetModel(model_data);
    static tflite::MicroInterpreter static_interpreter(model, resolver, tensor_arena, kArenaSize, &micro_error_reporter);
    interpreter = &static_interpreter;
    interpreter->AllocateTensors();
    input = interpreter->input(0);
    output = interpreter->output(0);

    // 6. Sensor Bus Initialization
    Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000); // Temp Bus
    tempSensor.begin();

    Wire1.begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 100000); // Motion Bus
    Wire1.beginTransmission(MPU6050_ADDR);
    Wire1.write(0x6B);
    Wire1.write(0x00); // Wake MPU6050
    Wire1.endTransmission();

    // 7. Start FreeRTOS Tasks
    xTaskCreatePinnedToCore(network_sender_task, "NetSender", 8192, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(audio_inference_task, "AudioAI", 8192, NULL, 2, NULL, 0); // Core 0
}

// =========================================================
// 8. MAIN LOOP (Real-Time Sensor Processing)
// =========================================================
void loop()
{
    static unsigned long lastSampleUs = 0;
    static unsigned long lastMotionMs = 0;
    static unsigned long lastTempMs = 0;
    static unsigned long lastVitalsSyncMs = 0;

    unsigned long nowUs = micros();
    unsigned long nowMs = millis();

    // --------------------------------------------------
    // A. ECG & RESPIRATION TASK (Runs exactly every 4ms / 250Hz)
    // --------------------------------------------------
    if (nowUs - lastSampleUs >= SAMPLE_INTERVAL_US)
    {
        lastSampleUs += SAMPLE_INTERVAL_US;

        // Check if pads are on the body
        leadsAreOff = (digitalRead(PIN_ECG_LO_PLUS) == 1 || digitalRead(PIN_ECG_LO_MINUS) == 1);

        if (!leadsAreOff)
        {
            int raw = analogRead(PIN_ECG_OUTPUT);

            // --- BPM Math ---
            ecgEma = 0.15f * raw + (1.0f - 0.15f) * ecgEma;
            signalMin = min(signalMin, ecgEma);
            signalMax = max(signalMax, ecgEma);

            if (nowMs - lastRangeResetMs > 2000)
            {
                signalMin = ecgEma;
                signalMax = ecgEma;
                lastRangeResetMs = nowMs;
            }
            float beatThreshold = signalMin + (signalMax - signalMin) * 0.65f;
            bool isAbove = (ecgEma > beatThreshold);
            if (!wasAbove && isAbove && (nowMs - lastBeatMs > 250))
            {
                if (lastBeatMs != 0)
                {
                    float newBpm = 60000.0f / (nowMs - lastBeatMs);
                    if (newBpm >= 45.0f && newBpm <= 160.0f)
                    {
                        currentBPM = (currentBPM == 0.0f) ? newBpm : (0.8f * currentBPM + 0.2f * newBpm);
                    }
                }
                lastBeatMs = nowMs;
            }
            wasAbove = isAbove;

            // --- Resp Math (EDR) ---
            baselineEma = 0.004f * raw + (1.0f - 0.004f) * baselineEma;
            respEma = 0.05f * baselineEma + (1.0f - 0.05f) * respEma;

            respMin = min(respMin, respEma);
            respMax = max(respMax, respEma);
            if (nowMs - lastRespRangeResetMs > 8000)
            {
                respMin = respEma;
                respMax = respEma;
                lastRespRangeResetMs = nowMs;
            }

            float respThreshold = respMin + (respMax - respMin) * 0.60f;
            bool respAbove = (respEma > respThreshold);
            if (!respWasAbove && respAbove && lastBreathMs != 0)
            {
                unsigned long bbi = nowMs - lastBreathMs;
                if (bbi >= 2500 && bbi <= 12000)
                {
                    float newRr = 60000.0f / (float)bbi;
                    currentRR = (currentRR == 0.0f) ? newRr : (0.85f * currentRR + 0.15f * newRr);
                }
                lastBreathMs = nowMs;
            }
            respWasAbove = respAbove;
        }
        else
        {
            currentBPM = 0;
            currentRR = 0;
        }
    }

    // --------------------------------------------------
    // B. FALL DETECTION TASK (Runs every 50ms)
    // --------------------------------------------------
    if (nowMs - lastMotionMs >= 50)
    {
        lastMotionMs = nowMs;

        Wire1.beginTransmission(MPU6050_ADDR);
        Wire1.write(0x3B);
        if (Wire1.endTransmission(true) == 0)
        {
            Wire1.requestFrom((uint16_t)MPU6050_ADDR, (uint8_t)6, (uint8_t)true);
            if (Wire1.available() >= 6)
            {
                int16_t ax = Wire1.read() << 8 | Wire1.read();
                int16_t ay = Wire1.read() << 8 | Wire1.read();
                int16_t az = Wire1.read() << 8 | Wire1.read();

                // Calculate G-Force Magnitude
                float gForce = sqrt(sq(ax / 16384.0) + sq(ay / 16384.0) + sq(az / 16384.0));

                // If G-Force spikes violently (e.g., > 2.5G), trigger a Fall Event
                if (gForce > 2.5)
                {
                    Serial.println("⚠️ FALL DETECTED!");
                    blinkLED(5, 100); // Fast strobe warning
                    digitalWrite(PIN_LED, HIGH);

                    CloudEvent event = {EVENT_FALL, gForce, 0.0, 0.0, false};
                    xQueueSend(cloudQueue, &event, 0);
                    delay(500); // Brief debounce
                }
            }
        }
    }

    // --------------------------------------------------
    // C. TEMPERATURE TASK (Runs every 1000ms)
    // --------------------------------------------------
    if (nowMs - lastTempMs >= 1000)
    {
        lastTempMs = nowMs;
        currentTemp = tempSensor.getTemperature();
    }

    // --------------------------------------------------
    // D. VITALS CLOUD SYNC TASK (Runs every 5000ms)
    // --------------------------------------------------
    if (nowMs - lastVitalsSyncMs >= 5000)
    {
        lastVitalsSyncMs = nowMs;

        // Simply package the current vitals and drop them in the queue.
        // The Network Task will handle the HTTP POST in the background.
        CloudEvent event = {EVENT_VITALS, currentTemp, currentBPM, currentRR, leadsAreOff};
        xQueueSend(cloudQueue, &event, 0);
    }
}