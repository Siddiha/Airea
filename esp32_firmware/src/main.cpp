/*
  ===========================================================================
    AIREA MASTER FIRMWARE (PROTOTYPE)
    ESP32-S3 Custom PCB Integration
    Features:
    - WiFiManager for easy setup
    - TFLite Audio Inference (Cough Detection)
    - TFLite Motion Inference (AI Fall Detection - MPU6050)
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
#include "cough_model.h"
#include "fall_model.h"

// --- SENSORS ---
#include <Protocentral_MAX30205.h>

// =========================================================
// 1. PIN DEFINITIONS
// =========================================================
#define PIN_TEMP_SDA 17
#define PIN_TEMP_SCL 18
#define PIN_MOTION_SDA 15
#define PIN_MOTION_SCL 16
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
    float val1; // Cough Confidence / Fall Confidence / Temp
    float val2; // Cough Volume / BPM
    float val3; // Respiratory Rate
    bool flag;  // Leads Off
};

QueueHandle_t cloudQueue;

// --- TFLite Globals (Cough Model) ---
const int kAudioArenaSize = 200 * 1024;
uint8_t *audio_tensor_arena;
int16_t *raw_audio_buffer;
#define SAMPLE_RATE 16000
const int kAudioBufferSize = 32000;
#define COUGH_THRESHOLD 0.80

tflite::MicroErrorReporter micro_error_reporter;
tflite::AllOpsResolver resolver;

const tflite::Model *audio_model;
tflite::MicroInterpreter *audio_interpreter;
TfLiteTensor *audio_input = nullptr;
TfLiteTensor *audio_output = nullptr;

// --- TFLite Globals (Fall Model) ---
const int kFallArenaSize = 100 * 1024;
uint8_t *fall_tensor_arena;

const tflite::Model *fall_model_ptr;
tflite::MicroInterpreter *fall_interpreter;
TfLiteTensor *fall_input = nullptr;
TfLiteTensor *fall_output = nullptr;

#define TIME_STEPS 200
#define NUM_FEATURES 6
#define FALL_THRESHOLD 0.85
float motion_buffer[TIME_STEPS][NUM_FEATURES];
int motion_buffer_index = 0;

// --- Vitals ---
MAX30205 tempSensor;
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
        client.setInsecure();
        HTTPClient http;
        http.begin(client, STATUS_URL);
        http.addHeader("Content-Type", "application/json");
        String payload = "{\"hardwareId\": \"ESP32_AIREA_01\", \"status\": \"online\", \"ipAddress\": \"" + WiFi.localIP().toString() + "\"}";
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
void network_sender_task(void *parameter)
{
    CloudEvent event;
    WiFiClientSecure client;
    client.setInsecure();
    HTTPClient http;

    while (true)
    {
        if (xQueueReceive(cloudQueue, &event, portMAX_DELAY) == pdTRUE)
        {
            if (WiFi.status() == WL_CONNECTED)
            {
                String url = "";
                String json = "{\"deviceId\":\"ESP32_AIREA_01\",";

                if (event.type == EVENT_COUGH)
                {
                    url = COUGH_URL;
                    json += "\"confidence\":" + String(event.val1, 3) + ",\"audioVolume\":" + String(event.val2, 2);
                }
                else if (event.type == EVENT_FALL)
                {
                    url = FALL_URL;
                    json += "\"confidence\":" + String(event.val1, 3) + ",\"alert\":\"EMERGENCY_FALL\"";
                }
                else if (event.type == EVENT_VITALS)
                {
                    url = VITALS_URL;
                    json += "\"temp\":" + String(event.val1, 2) + ",\"bpm\":" + String(event.val2, 1) +
                            ",\"rr\":" + String(event.val3, 1) + ",\"leadsOff\":" + String(event.flag ? "true" : "false");
                }
                json += "}";

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
// 6. FREE-RTOS TASK: AUDIO AI
// =========================================================
void audio_inference_task(void *parameter)
{
    if (audio_input == nullptr)
    {
        Serial.println("❌ FATAL: Audio Model failed.");
        vTaskDelete(NULL);
        return;
    }
    size_t bytes_read;
    static unsigned long last_alert_time = 0;

    const i2s_config_t i2s_config = {
        .mode = i2s_mode_t(I2S_MODE_MASTER | I2S_MODE_RX), .sample_rate = SAMPLE_RATE, .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT, .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT, .communication_format = i2s_comm_format_t(I2S_COMM_FORMAT_I2S | I2S_COMM_FORMAT_I2S_MSB), .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1, .dma_buf_count = 4, .dma_buf_len = 1024, .use_apll = false, .fixed_mclk = 0};
    const i2s_pin_config_t pin_config = {.bck_io_num = I2S_SCK, .ws_io_num = I2S_WS, .data_out_num = I2S_PIN_NO_CHANGE, .data_in_num = I2S_SD};
    i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
    i2s_set_pin(I2S_PORT, &pin_config);

    Serial.println("🎤 Microphone Ready. AI Listening...");

    while (true)
    {
        i2s_read(I2S_PORT, raw_audio_buffer, kAudioBufferSize * sizeof(int16_t), &bytes_read, portMAX_DELAY);
        int8_t *input_data = audio_input->data.int8;
        float avg_vol = 0;

        for (int i = 0; i < audio_input->bytes; i++)
        {
            int16_t sample = raw_audio_buffer[i * 2];
            int32_t amplified = sample * 8;
            if (amplified > 32767)
                amplified = 32767;
            if (amplified < -32768)
                amplified = -32768;
            input_data[i] = (int8_t)(amplified >> 8);
            if (i % 100 == 0)
                avg_vol += abs(amplified);
        }
        avg_vol /= (audio_input->bytes / 100);

        if (audio_interpreter->Invoke() != kTfLiteOk)
            continue;
        float cough_score = (audio_output->type == kTfLiteInt8) ? (audio_output->data.int8[1] - audio_output->params.zero_point) * audio_output->params.scale : audio_output->data.f[1];

        if (avg_vol > 300 && cough_score > COUGH_THRESHOLD && (millis() - last_alert_time > 5000))
        {
            Serial.println("\n🚨 COUGH DETECTED!");
            digitalWrite(PIN_LED, HIGH);
            CloudEvent event = {EVENT_COUGH, cough_score, avg_vol, 0.0, false};
            xQueueSend(cloudQueue, &event, 0);
            last_alert_time = millis();
            delay(200);
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
    pinMode(PIN_LED, OUTPUT);
    pinMode(PIN_ECG_LO_PLUS, INPUT);
    pinMode(PIN_ECG_LO_MINUS, INPUT);
    analogReadResolution(12);
    digitalWrite(PIN_LED, HIGH);

    Serial.println("\n=================================");
    Serial.println("    AIREA MONITORING SYSTEM      ");
    Serial.println("=================================");

    WiFiManager wm;
    Serial.println("📡 Connecting to WiFi...");
    if (!wm.autoConnect("Airea-Setup"))
    {
        Serial.println("❌ Failed. Restarting...");
        ESP.restart();
    }
    Serial.println("✅ WiFi Connected!");
    blinkLED(3, 200);
    digitalWrite(PIN_LED, HIGH);
    notifyBackendOnline();

    cloudQueue = xQueueCreate(10, sizeof(CloudEvent));
    audio_tensor_arena = (uint8_t *)malloc(kAudioArenaSize);
    fall_tensor_arena = (uint8_t *)malloc(kFallArenaSize);
    raw_audio_buffer = (int16_t *)malloc(kAudioBufferSize * sizeof(int16_t));

    // AUDIO INTERPRETER INIT - Fixed &micro_error_reporter
    audio_model = tflite::GetModel(model_data);
    static tflite::MicroInterpreter static_audio_interpreter(audio_model, resolver, audio_tensor_arena, kAudioArenaSize, &micro_error_reporter);
    audio_interpreter = &static_audio_interpreter;
    audio_interpreter->AllocateTensors();
    audio_input = audio_interpreter->input(0);
    audio_output = audio_interpreter->output(0);

    // FALL INTERPRETER INIT - Fixed &micro_error_reporter
    fall_model_ptr = tflite::GetModel(fall_model);
    static tflite::MicroInterpreter static_fall_interpreter(fall_model_ptr, resolver, fall_tensor_arena, kFallArenaSize, &micro_error_reporter);
    fall_interpreter = &static_fall_interpreter;
    fall_interpreter->AllocateTensors();
    fall_input = fall_interpreter->input(0);
    fall_output = fall_interpreter->output(0);

    Serial.println("✅ AI Models Loaded Successfully.");

    Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000);
    tempSensor.begin();
    Wire1.begin(PIN_MOTION_SDA, PIN_MOTION_SCL, 100000);
    Wire1.beginTransmission(MPU6050_ADDR);
    Wire1.write(0x6B);
    Wire1.write(0x00);
    Wire1.endTransmission();

    xTaskCreatePinnedToCore(network_sender_task, "NetSender", 8192, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(audio_inference_task, "AudioAI", 8192, NULL, 2, NULL, 0);
}

// =========================================================
// 8. MAIN LOOP
// =========================================================
void loop()
{
    static unsigned long lastSampleUs = 0, lastMotionMs = 0, lastTempMs = 0, lastVitalsSyncMs = 0, lastFallAlertMs = 0;
    unsigned long nowUs = micros(), nowMs = millis();

    // A. ECG TASK (250Hz)
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

            baselineEma = 0.004f * raw + 0.996f * baselineEma;
            respEma = 0.05f * baselineEma + 0.95f * respEma;
            respMin = min(respMin, respEma);
            respMax = max(respMax, respEma);
            if (nowMs - lastRespRangeResetMs > 8000)
            {
                respMin = respMax = respEma;
                lastRespRangeResetMs = nowMs;
            }
            bool respAbove = (respEma > respMin + (respMax - respMin) * 0.60f);
            if (!respWasAbove && respAbove && lastBreathMs != 0)
            {
                unsigned long bbi = nowMs - lastBreathMs;
                if (bbi >= 2500 && bbi <= 12000)
                    currentRR = (currentRR == 0.0f) ? 60000.0f / bbi : (0.85f * currentRR + 0.15f * (60000.0f / bbi));
                lastBreathMs = nowMs;
            }
            respWasAbove = respAbove;
        }
        else
        {
            currentBPM = currentRR = 0;
        }
    }

    // B. AI FALL DETECTION (100Hz)
    if (nowMs - lastMotionMs >= 10)
    {
        lastMotionMs = nowMs;
        Wire1.beginTransmission(MPU6050_ADDR);
        Wire1.write(0x3B);
        if (Wire1.endTransmission(false) == 0)
        {
            Wire1.requestFrom((uint16_t)MPU6050_ADDR, (uint8_t)14, (uint8_t)true);
            if (Wire1.available() >= 14)
            {
                int16_t raw_ax = Wire1.read() << 8 | Wire1.read(), raw_ay = Wire1.read() << 8 | Wire1.read(), raw_az = Wire1.read() << 8 | Wire1.read();
                Wire1.read();
                Wire1.read();
                int16_t raw_gx = Wire1.read() << 8 | Wire1.read(), raw_gy = Wire1.read() << 8 | Wire1.read(), raw_gz = Wire1.read() << 8 | Wire1.read();

                float ax_mps2 = (raw_ax / 16384.0) * 9.81, ay_mps2 = (raw_ay / 16384.0) * 9.81, az_mps2 = (raw_az / 16384.0) * 9.81;
                float gx_degs = raw_gx / 131.0, gy_degs = raw_gy / 131.0, gz_degs = raw_gz / 131.0;

                motion_buffer[motion_buffer_index][0] = ay_mps2 / 20.0;
                motion_buffer[motion_buffer_index][1] = ax_mps2 / 20.0;
                motion_buffer[motion_buffer_index][2] = az_mps2 / 20.0;
                motion_buffer[motion_buffer_index][3] = gy_degs / 500.0;
                motion_buffer[motion_buffer_index][4] = gx_degs / 500.0;
                motion_buffer[motion_buffer_index][5] = gz_degs / 500.0;
                motion_buffer_index++;

                if (motion_buffer_index >= TIME_STEPS)
                {
                    for (int i = 0; i < TIME_STEPS; i++)
                        for (int j = 0; j < NUM_FEATURES; j++)
                            fall_input->data.f[(i * NUM_FEATURES) + j] = motion_buffer[i][j];
                    if (fall_interpreter->Invoke() == kTfLiteOk)
                    {
                        float fall_confidence = fall_output->data.f[0];
                        if (fall_confidence > FALL_THRESHOLD && (nowMs - lastFallAlertMs > 5000))
                        {
                            Serial.printf("⚠️ AI FALL DETECTED! Confidence: %.2f%%\n", fall_confidence * 100);
                            blinkLED(5, 100);
                            digitalWrite(PIN_LED, HIGH);
                            CloudEvent event = {EVENT_FALL, fall_confidence, 0.0, 0.0, false};
                            xQueueSend(cloudQueue, &event, 0);
                            lastFallAlertMs = nowMs;
                            delay(500);
                        }
                    }
                    int overlap = TIME_STEPS / 2;
                    for (int i = 0; i < overlap; i++)
                        for (int j = 0; j < NUM_FEATURES; j++)
                            motion_buffer[i][j] = motion_buffer[i + overlap][j];
                    motion_buffer_index = overlap;
                }
            }
        }
    }

    // C. TEMP (1s) & D. CLOUD SYNC (5s)
    if (nowMs - lastTempMs >= 1000)
    {
        lastTempMs = nowMs;
        currentTemp = tempSensor.getTemperature();
    }
    if (nowMs - lastVitalsSyncMs >= 5000)
    {
        lastVitalsSyncMs = nowMs;
        CloudEvent event = {EVENT_VITALS, currentTemp, currentBPM, currentRR, leadsAreOff};
        xQueueSend(cloudQueue, &event, 0);
    }
}