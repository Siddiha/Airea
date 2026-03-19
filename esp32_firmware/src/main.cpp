/*
  ===========================================================================
    AIREA MASTER FIRMWARE - v11 (The "Goldilocks" Gain Edition)
    ESP32-S3 Custom PCB Integration
  ===========================================================================
*/

#include <Arduino.h>
#include <Wire.h>
#include <WiFiManager.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <driver/i2s.h>
#include <esp_task_wdt.h>
#include <esp_heap_caps.h>

// --- FREERTOS ---
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

// --- TFLITE ---
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "cough_model.h"
#include "fall_model.h"

// =========================================================
// FEATURE TOGGLES
// =========================================================
bool enableFallDetection = false;
bool enableCoughDetection = true;

// =========================================================
// 1. PIN DEFINITIONS & I2C ADDRESSES
// =========================================================
#define PIN_TEMP_SDA 17
#define PIN_TEMP_SCL 18
#define PIN_MOTION_SDA 15
#define PIN_MOTION_SCL 16
#define MAX30205_ADDR 0x4C
#define MPU6050_ADDR 0x68

#define PIN_ECG_OUTPUT 1
#define PIN_ECG_LO_PLUS 6
#define PIN_ECG_LO_MINUS 7
#define I2S_WS 42
#define I2S_SD 2
#define I2S_SCK 41
#define I2S_PORT I2S_NUM_0
#define PIN_LED 4

// =========================================================
// 2. NETWORK URLS
// =========================================================
const String BASE_URL = "https://airea-production.up.railway.app/api";
const String STATUS_URL = BASE_URL + "/board/status";
const String VITALS_URL = BASE_URL + "/vitals/event";
const String COUGH_URL = BASE_URL + "/cough/event";
const String FALL_URL = BASE_URL + "/fall/event";

// =========================================================
// 3. GLOBALS & QUEUES
// =========================================================
enum EventType
{
    EVENT_COUGH,
    EVENT_FALL,
    EVENT_VITALS
};
struct CloudEvent
{
    EventType type;
    float val1;
    float val2;
    float val3;
    bool flag;
};
QueueHandle_t cloudQueue;

// --- TFLite Globals (Cough Model) ---
const int kAudioArenaSize = 200 * 1024;
uint8_t *audio_tensor_arena;
int16_t *raw_audio_buffer;
#define SAMPLE_RATE 16000
const int kAudioBufferSize = 32000;

// THE GOLDILOCKS CALIBRATION
#define COUGH_THRESHOLD 0.70 // 75% Confidence
#define COUGH_COOLDOWN_MS 5000

tflite::MicroErrorReporter micro_error_reporter;
tflite::AllOpsResolver audio_resolver;
tflite::AllOpsResolver fall_resolver;

const tflite::Model *audio_model;
tflite::MicroInterpreter *audio_interpreter;
TfLiteTensor *audio_input = nullptr;
TfLiteTensor *audio_output = nullptr;

// --- Fall Globals ---
const int kFallArenaSize = 100 * 1024;
uint8_t *fall_tensor_arena;
const tflite::Model *fall_model_ptr;
tflite::MicroInterpreter *fall_interpreter;
TfLiteTensor *fall_input = nullptr;
TfLiteTensor *fall_output = nullptr;

#define TIME_STEPS 200
#define NUM_FEATURES 6
#define FALL_THRESHOLD 0.95
float motion_buffer[TIME_STEPS][NUM_FEATURES];
int motion_buffer_index = 0;

// --- Vitals ---
float currentTemp = 0.0, currentBPM = 0.0, currentRR = 0.0;
bool leadsAreOff = false;

constexpr unsigned long SAMPLE_INTERVAL_US = 4000;
static float ecgEma = 0.0f, baselineEma = 0.0f, respEma = 0.0f;
static float signalMin = 4095.0f, signalMax = 0.0f, respMin = 1e9f, respMax = -1e9f;
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
        digitalWrite(PIN_LED, LOW);
        delay(delayMs);
        digitalWrite(PIN_LED, HIGH);
        delay(delayMs);
    }
    digitalWrite(PIN_LED, WiFi.status() == WL_CONNECTED ? HIGH : LOW);
}

void notifyBackendOnline()
{
    if (WiFi.status() == WL_CONNECTED)
    {
        WiFiClientSecure client;
        client.setInsecure();
        HTTPClient http;
        http.begin(client, STATUS_URL);
        http.addHeader("Content-Type", "application/json");
        String payload = "{\"hardwareId\": \"ESP32_AIREA_01\", \"status\": \"online\", \"ipAddress\": \"" + WiFi.localIP().toString() + "\"}";
        http.POST(payload);
        http.end();
        Serial.println("\n✅ Backend Online (Vitals Sync Active)");
    }
}

float readTempRaw()
{
    Wire.beginTransmission(MAX30205_ADDR);
    Wire.write(0x00);
    if (Wire.endTransmission(false) != 0)
        return currentTemp;
    Wire.requestFrom((uint16_t)MAX30205_ADDR, (uint8_t)2);
    if (Wire.available() >= 2)
    {
        int16_t rawT = (Wire.read() << 8 | Wire.read());
        return rawT * 0.00390625;
    }
    return currentTemp;
}

// =========================================================
// 5. TASK: NETWORK SENDER
// =========================================================
void network_sender_task(void *parameter)
{
    CloudEvent event;
    while (true)
    {
        if (WiFi.status() != WL_CONNECTED)
        {
            digitalWrite(PIN_LED, LOW);
            WiFi.disconnect();
            WiFi.reconnect();
            vTaskDelay(5000 / portTICK_PERIOD_MS);
            if (WiFi.status() == WL_CONNECTED)
                digitalWrite(PIN_LED, HIGH);
            continue;
        }

        if (xQueueReceive(cloudQueue, &event, portMAX_DELAY) == pdTRUE)
        {
            WiFiClientSecure client;
            client.setInsecure();
            client.setTimeout(10000);
            HTTPClient http;

            String url = "";
            String json = "{ \"deviceId\":\"ESP32_AIREA_01\",";

            if (event.type == EVENT_COUGH)
            {
                url = COUGH_URL;
                json += "\"confidence\":" + String(event.val1, 3) + ", \"rawScore\":" + String(event.val1, 3) + ", \"audioVolume\":" + String(event.val2, 2);
            }
            else if (event.type == EVENT_FALL)
            {
                url = FALL_URL;
                json += "\"confidence\":" + String(event.val1, 3) + ",\"alert\":\"EMERGENCY_FALL\"";
            }
            else if (event.type == EVENT_VITALS)
            {
                url = VITALS_URL;
                json += "\"temp\":" + String(event.val1, 2) + ", \"bpm\":" + String(event.val2, 1) + ", \"rr\":" + String(event.val3, 1) + ", \"leadsOff\":" + String(event.flag ? "true" : "false");
            }
            json += "}";

            if (http.begin(client, url))
            {
                http.addHeader("Content-Type", "application/json");
                int httpCode = http.POST(json);
                if (event.type == EVENT_COUGH)
                {
                    Serial.printf("\n☁️ Uploading COUGH Event... Done! (Status: %d)\n", httpCode);
                }
                else if (event.type == EVENT_FALL)
                {
                    Serial.printf("\n☁️ Uploading FALL Event... Done! (Status: %d)\n", httpCode);
                }
                http.end();
            }
        }
    }
}

// =========================================================
// 6. TASK: AUDIO AI
// =========================================================
void audio_inference_task(void *parameter)
{
    size_t bytes_read;
    static unsigned long last_alert_time = 0;

    const i2s_config_t i2s_config = {
        .mode = i2s_mode_t(I2S_MODE_MASTER | I2S_MODE_RX),
        .sample_rate = SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
        .communication_format = i2s_comm_format_t(I2S_COMM_FORMAT_STAND_I2S),
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 4,
        .dma_buf_len = 1024,
        .use_apll = false};
    const i2s_pin_config_t pin_config = {.bck_io_num = I2S_SCK, .ws_io_num = I2S_WS, .data_out_num = -1, .data_in_num = I2S_SD};
    i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
    i2s_set_pin(I2S_PORT, &pin_config);

    Serial.println("\n🎤 System Ready. Listening...");

    while (true)
    {
        if (!enableCoughDetection || audio_input == nullptr)
        {
            vTaskDelay(1000 / portTICK_PERIOD_MS);
            continue;
        }

        i2s_read(I2S_PORT, raw_audio_buffer, kAudioBufferSize * sizeof(int16_t), &bytes_read, portMAX_DELAY);
        int8_t *input_data = audio_input->data.int8;

        float avg_vol = 0;
        for (int i = 0; i < audio_input->bytes; i++)
        {
            int16_t sample = raw_audio_buffer[i * 2];
            int32_t amplified = sample * 4;

            if (amplified > 32767)
                amplified = 32767;
            if (amplified < -32768)
                amplified = -32768;

            int abs_amp = abs(amplified);
            input_data[i] = (int8_t)(amplified >> 8);
            if (i % 100 == 0)
                avg_vol += abs_amp;
        }
        avg_vol /= (audio_input->bytes / 100);

        if (audio_interpreter->Invoke() != kTfLiteOk)
            continue;

        float cough_score = (audio_output->type == kTfLiteInt8) ? (audio_output->data.int8[1] - audio_output->params.zero_point) * audio_output->params.scale : audio_output->data.f[1];

        if (millis() > 10000)
        {
            if (cough_score > COUGH_THRESHOLD && (millis() - last_alert_time > COUGH_COOLDOWN_MS))
            {
                Serial.println("\n🚨 COUGH DETECTED!");
                Serial.printf("   Confidence: %.1f%% | Volume: %d\n", cough_score * 100, (int)avg_vol);
                blinkLED(3, 150);
                CloudEvent event = {EVENT_COUGH, cough_score, avg_vol, 0.0, false};
                xQueueSend(cloudQueue, &event, 0);
                last_alert_time = millis();
            }
            else if (avg_vol > 100)
            {
                Serial.println();
                Serial.printf("🔊 Cough Prob: %.1f%% | Volume: %d\n", cough_score * 100, (int)avg_vol);
            }
        }
        vTaskDelay(10 / portTICK_PERIOD_MS);
    }
}

// =========================================================
// 7. SETUP
// =========================================================
void setup()
{
    Serial.begin(115200);
    delay(1000);
    Serial.println("\n\n=================================\n   AIREA MONITORING SYSTEM v11\n=================================");

    pinMode(PIN_LED, OUTPUT);
    digitalWrite(PIN_LED, LOW);
    pinMode(PIN_ECG_LO_PLUS, INPUT);
    pinMode(PIN_ECG_LO_MINUS, INPUT);
    analogReadResolution(12);
    pinMode(PIN_TEMP_SDA, INPUT_PULLUP);
    pinMode(PIN_TEMP_SCL, INPUT_PULLUP);
    Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000);

    if (enableFallDetection)
    {
        pinMode(PIN_MOTION_SDA, INPUT_PULLUP);
        pinMode(PIN_MOTION_SCL, INPUT_PULLUP);
        Wire1.begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 400000);
        Wire1.beginTransmission(MPU6050_ADDR);
        Wire1.write(0x6B);
        Wire1.write(0x00);
        Wire1.endTransmission();
    }

    WiFiManager wm;
    wm.setConfigPortalTimeout(60);
    if (!wm.autoConnect("Airea-Setup"))
        Serial.println("⚠️ WiFi Failed - Continuing in Offline Mode");
    digitalWrite(PIN_LED, HIGH);
    notifyBackendOnline();
    cloudQueue = xQueueCreate(10, sizeof(CloudEvent));

    Serial.println("\n🧠 Allocating AI Arenas in PSRAM...");
    if (enableCoughDetection)
    {
        audio_tensor_arena = (uint8_t *)heap_caps_malloc(kAudioArenaSize, MALLOC_CAP_SPIRAM);
        raw_audio_buffer = (int16_t *)heap_caps_malloc(kAudioBufferSize * sizeof(int16_t), MALLOC_CAP_SPIRAM);
        if (!audio_tensor_arena)
        {
            Serial.println("❌ FATAL: Audio PSRAM Allocation Failed!");
            while (1)
                delay(100);
        }

        audio_model = tflite::GetModel(model_data);
        static tflite::MicroInterpreter static_audio_interpreter(audio_model, audio_resolver, audio_tensor_arena, kAudioArenaSize, &micro_error_reporter);
        audio_interpreter = &static_audio_interpreter;
        audio_interpreter->AllocateTensors();
        audio_input = audio_interpreter->input(0);
        audio_output = audio_interpreter->output(0);
        Serial.println("✅ Audio AI Model Loaded.");
    }

    if (enableFallDetection)
    {
        fall_tensor_arena = (uint8_t *)heap_caps_malloc(kFallArenaSize, MALLOC_CAP_SPIRAM);
        if (!fall_tensor_arena)
        {
            Serial.println("❌ FATAL: Fall PSRAM Allocation Failed!");
            while (1)
                delay(100);
        }

        fall_model_ptr = tflite::GetModel(fall_model);
        static tflite::MicroInterpreter static_fall_interpreter(fall_model_ptr, fall_resolver, fall_tensor_arena, kFallArenaSize, &micro_error_reporter);
        fall_interpreter = &static_fall_interpreter;
        fall_interpreter->AllocateTensors();
        fall_input = fall_interpreter->input(0);
        fall_output = fall_interpreter->output(0);
        Serial.println("✅ Fall AI Model Loaded.");
    }

    esp_task_wdt_init(5, true);
    esp_task_wdt_add(NULL);

    xTaskCreatePinnedToCore(network_sender_task, "NetSender", 8192, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(audio_inference_task, "AudioAI", 16384, NULL, 2, NULL, 1);
}

// =========================================================
// 8. LOOP
// =========================================================
void loop()
{
    esp_task_wdt_reset();
    static unsigned long lastSampleUs = 0, lastMotionMs = 0, lastTempMs = 0, lastVitalsSyncMs = 0, lastFallAlertMs = 0;
    unsigned long nowUs = micros(), nowMs = millis();

    // A. ECG TASK
    if (nowUs - lastSampleUs >= SAMPLE_INTERVAL_US)
    {
        lastSampleUs += SAMPLE_INTERVAL_US;
        leadsAreOff = (digitalRead(PIN_ECG_LO_PLUS) == 1 || digitalRead(PIN_ECG_LO_MINUS) == 1);
        if (!leadsAreOff)
        {
            int raw = analogRead(PIN_ECG_OUTPUT);
            ecgEma = 0.15f * raw + 0.85f * ecgEma;
            signalMin = min(signalMin, ecgEma);
            signalMax = max(signalMax, ecgEma);
            if (nowMs - lastRangeResetMs > 2000)
            {
                signalMin = signalMax = ecgEma;
                lastRangeResetMs = nowMs;
            }
            bool isAbove = (ecgEma > signalMin + (signalMax - signalMin) * 0.65f);
            if (!wasAbove && isAbove && (nowMs - lastBeatMs > 250))
            {
                if (lastBeatMs != 0)
                {
                    float newBpm = 60000.0f / (nowMs - lastBeatMs);
                    if (newBpm >= 45.0f && newBpm <= 160.0f)
                        currentBPM = (currentBPM == 0.0f) ? newBpm : (0.8f * currentBPM + 0.2f * newBpm);
                }
                lastBeatMs = nowMs;
            }
            wasAbove = isAbove;
        }
        else
        {
            currentBPM = currentRR = 0;
        }
    }

    // B. FALL DETECTION
    if (enableFallDetection && (nowMs - lastMotionMs >= 10))
    {
        lastMotionMs = nowMs;
        Wire1.beginTransmission(MPU6050_ADDR);
        Wire1.write(0x3B);
        if (Wire1.endTransmission(false) == 0)
        {
            uint8_t bytesReceived = Wire1.requestFrom((uint16_t)MPU6050_ADDR, (uint8_t)14, (uint8_t)true);
            if (bytesReceived == 14)
            {
                int16_t raw_ax = Wire1.read() << 8 | Wire1.read(), raw_ay = Wire1.read() << 8 | Wire1.read(), raw_az = Wire1.read() << 8 | Wire1.read();
                Wire1.read();
                Wire1.read();
                int16_t raw_gx = Wire1.read() << 8 | Wire1.read(), raw_gy = Wire1.read() << 8 | Wire1.read(), raw_gz = Wire1.read() << 8 | Wire1.read();

                if ((raw_ax == -1 && raw_ay == -1 && raw_az == -1) || (raw_ax == 0 && raw_ay == 0 && raw_az == 0))
                {
                    motion_buffer_index = 0;
                }
                else
                {
                    float ax_mps2 = (raw_ax / 16384.0) * 9.81, ay_mps2 = (raw_ay / 16384.0) * 9.81, az_mps2 = (raw_az / 16384.0) * 9.81;
                    float gx_degs = raw_gx / 131.0, gy_degs = raw_gy / 131.0, gz_degs = raw_gz / 131.0;

                    motion_buffer[motion_buffer_index][0] = ay_mps2 / 20.0;
                    motion_buffer[motion_buffer_index][1] = ax_mps2 / 20.0;
                    motion_buffer[motion_buffer_index][2] = az_mps2 / 20.0;
                    motion_buffer[motion_buffer_index][3] = gy_degs / 500.0;
                    motion_buffer[motion_buffer_index][4] = gx_degs / 500.0;
                    motion_buffer[motion_buffer_index][5] = gz_degs / 500.0;
                    motion_buffer_index++;
                }

                if (motion_buffer_index >= TIME_STEPS)
                {
                    for (int i = 0; i < TIME_STEPS; i++)
                        for (int j = 0; j < NUM_FEATURES; j++)
                            fall_input->data.f[(i * NUM_FEATURES) + j] = motion_buffer[i][j];
                    if (fall_interpreter->Invoke() == kTfLiteOk)
                    {
                        float fall_confidence = fall_output->data.f[0];
                        if (fall_confidence > FALL_THRESHOLD && (millis() > 10000) && (nowMs - lastFallAlertMs > 5000))
                        {
                            Serial.printf("\n⚠️ AI FALL DETECTED! Confidence: %.2f%%\n", fall_confidence * 100);
                            blinkLED(10, 100);
                            CloudEvent event = {EVENT_FALL, fall_confidence, 0.0, 0.0, false};
                            xQueueSend(cloudQueue, &event, 0);
                            lastFallAlertMs = nowMs;
                        }
                    }
                    int overlap = TIME_STEPS / 2;
                    for (int i = 0; i < overlap; i++)
                        for (int j = 0; j < NUM_FEATURES; j++)
                            motion_buffer[i][j] = motion_buffer[i + overlap][j];
                    motion_buffer_index = overlap;
                }
            }
            else
            {
                motion_buffer_index = 0;
                static unsigned long lastRetry = 0;
                if (millis() - lastRetry > 5000)
                {
                    lastRetry = millis();
                    Wire1.begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 400000);
                }
            }
        }
        else
        {
            motion_buffer_index = 0;
            static unsigned long lastRetry = 0;
            if (millis() - lastRetry > 5000)
            {
                lastRetry = millis();
                Wire1.begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 400000);
            }
        }
    }

    // C. TEMP & D. CLOUD SYNC
    if (nowMs - lastVitalsSyncMs >= 5000)
    {
        lastVitalsSyncMs = nowMs;
        currentTemp = readTempRaw();

        // Vitals printout to monitor health
        Serial.printf("\n🩺 [Vitals Check] Temp: %.1f°C | BPM: %.0f | RR: %.0f | Leads Off: %s\n", currentTemp, currentBPM, currentRR, leadsAreOff ? "YES" : "NO");

        CloudEvent event = {EVENT_VITALS, currentTemp, currentBPM, currentRR, leadsAreOff};
        xQueueSend(cloudQueue, &event, 0);
    }
}