#include <Arduino.h>
#include <Wire.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h>
#include <driver/i2s.h>

// --- FREERTOS INCLUDES ---
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

// --- TFLITE INCLUDES ---
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

// --- YOUR MODELS & LIBRARIES ---
#include "cough_model.h"
#include "Protocentral_MAX30205.h"

// =========================================================
// 1. PIN DEFINITIONS
// =========================================================
// Vitals
#define PIN_TEMP_SDA 17
#define PIN_TEMP_SCL 18
#define PIN_ECG_OUT 1
#define PIN_ECG_LO_PLUS 6
#define PIN_ECG_LO_MINUS 7

// Audio
#define I2S_WS 42
#define I2S_SD 2
#define I2S_SCK 41
#define I2S_PORT I2S_NUM_0

// =========================================================
// 2. NETWORK & CONFIGURATION
// =========================================================
const char *ssid = "Dialog 4G 437";
const char *password = "20040920";
const char *vitalsUrl = "https://airea-production.up.railway.app/api/vitals/event";
const char *coughUrl = "https://airea-production.up.railway.app/api/cough/event";

#define SAMPLE_RATE 16000
const int kAudioBufferSize = 32000; // 2 Seconds
#define COUGH_THRESHOLD 0.90

// =========================================================
// 3. GLOBALS & QUEUES
// =========================================================
struct CoughEvent
{
    float confidence;
    float volume;
    unsigned long timestamp;
};
QueueHandle_t coughQueue;

// TFLite Globals
const int kArenaSize = 200 * 1024;
uint8_t *tensor_arena;
int16_t *raw_audio_buffer;

tflite::MicroErrorReporter micro_error_reporter;
tflite::AllOpsResolver resolver; // Using AllOps to prevent crashes!
const tflite::Model *model;
tflite::MicroInterpreter *interpreter;
TfLiteTensor *input = nullptr;
TfLiteTensor *output = nullptr;

// =========================================================
// 4. CLASS: BIO SENSORS (Temp, BPM, RR)
// =========================================================
class BioMonitor
{
private:
    MAX30205 tempSensor;

    // Heart Rate
    float bpm = 0;
    unsigned long lastBeatMs = 0;
    float ecgEma = 0.0f;

    // Respiratory Rate
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
        // --- Temperature (1s interval) ---
        static unsigned long lastTempRead = 0;
        if (millis() - lastTempRead > 1000)
        {
            Wire.begin(PIN_TEMP_SDA, PIN_TEMP_SCL, 100000);
            currentTemp = tempSensor.getTemperature();
            lastTempRead = millis();
        }

        // --- ECG Leads Off Check ---
        if (digitalRead(PIN_ECG_LO_PLUS) == 1 || digitalRead(PIN_ECG_LO_MINUS) == 1)
        {
            leadsAreOff = true;
            bpm = 0;
            rr = 0;
            return;
        }
        else
        {
            leadsAreOff = false;
        }

        int raw = analogRead(PIN_ECG_OUT);

        // --- Heart Rate (BPM) ---
        ecgEma = 0.15f * raw + 0.85f * ecgEma;
        static float bpmMin = 4095, bpmMax = 0;
        static unsigned long lastBpmReset = 0;
        static bool beatWasHigh = false;

        bool beatHigh = detectPeak(ecgEma, bpmMin, bpmMax, lastBpmReset, 0.70, 3000);
        if (beatHigh && !beatWasHigh)
        {
            if (millis() - lastBeatMs > 250)
            {
                float instantBpm = 60000.0 / (millis() - lastBeatMs);
                if (instantBpm > 30 && instantBpm < 200)
                {
                    bpm = (bpm == 0) ? instantBpm : (0.8 * bpm + 0.2 * instantBpm);
                }
                lastBeatMs = millis();
            }
        }
        beatWasHigh = beatHigh;

        // --- Respiratory Rate (RR) ---
        baselineEma = 0.004f * raw + 0.996f * baselineEma;
        respEma = 0.05f * baselineEma + 0.95f * respEma;

        static float respMin = 4095, respMax = 0;
        static unsigned long lastRespReset = 0;
        static bool respWasHigh = false;

        bool respHigh = detectPeak(respEma, respMin, respMax, lastRespReset, 0.60, 8000);
        if (respHigh && !respWasHigh)
        {
            if (millis() - lastBreathMs > 1000)
            {
                float instantRr = 60000.0 / (millis() - lastBreathMs);
                if (instantRr > 5 && instantRr < 40)
                {
                    rr = (rr == 0) ? instantRr : (0.85 * rr + 0.15 * instantRr);
                }
                lastBreathMs = millis();
            }
        }
        respWasHigh = respHigh;
    }

    float getBPM() { return bpm; }
    float getRR() { return rr; }
    float getTemp() { return currentTemp; }
};

BioMonitor bioMonitor;

// =========================================================
// 5. TASK: COUGH NETWORK SENDER
// =========================================================
void network_sender_task(void *parameter)
{
    CoughEvent receivedEvent;
    while (true)
    {
        if (xQueueReceive(coughQueue, &receivedEvent, portMAX_DELAY) == pdTRUE)
        {
            Serial.print("\n☁️  [Cloud] Uploading Cough Event... ");

            if (WiFi.status() == WL_CONNECTED)
            {
                WiFiClientSecure client;
                client.setInsecure();
                client.setTimeout(10000);
                HTTPClient http;

                if (http.begin(client, coughUrl))
                {
                    http.addHeader("Content-Type", "application/json");
                    String jsonPayload = "{";
                    jsonPayload += "\"deviceId\":\"ESP32_COUGH_01\",";
                    jsonPayload += "\"confidence\":" + String(receivedEvent.confidence, 3) + ",";
                    jsonPayload += "\"rawScore\":" + String(receivedEvent.confidence, 3) + ",";
                    jsonPayload += "\"audioVolume\":" + String(receivedEvent.volume, 2);
                    jsonPayload += "}";

                    int httpResponseCode = http.POST(jsonPayload);
                    if (httpResponseCode > 0)
                    {
                        Serial.printf("Done! (Status: %d)\n", httpResponseCode);
                    }
                    else
                    {
                        Serial.printf("Failed. (Error: %s)\n", http.errorToString(httpResponseCode).c_str());
                    }
                    http.end();
                }
            }
            else
            {
                Serial.println("Failed (No Wi-Fi).");
            }
            Serial.println("------------------------------------------------");
        }
    }
}

// =========================================================
// 6. TASK: AUDIO INFERENCE (Cough AI)
// =========================================================
void audio_inference_task(void *parameter)
{
    if (input == nullptr)
    {
        Serial.println("❌ FATAL: Model failed to load.");
        vTaskDelete(NULL);
        return;
    }

    size_t bytes_read = 0;
    static unsigned long last_alert_time = 0;
    static unsigned long last_dot_time = 0;

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

    if (i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL) != ESP_OK)
        return;
    i2s_set_pin(I2S_PORT, &pin_config);

    Serial.println("🎤  Microphone Ready. AI Listening...");

    while (true)
    {
        i2s_read(I2S_PORT, raw_audio_buffer, kAudioBufferSize * sizeof(int16_t), &bytes_read, portMAX_DELAY);

        int8_t *input_data = input->data.int8;
        float avg_vol = 0;

        for (int i = 0; i < input->bytes; i++)
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
        avg_vol /= (input->bytes / 100);

        if (interpreter->Invoke() != kTfLiteOk)
            continue;

        float cough_score = (output->type == kTfLiteInt8) ? (output->data.int8[1] - output->params.zero_point) * output->params.scale : output->data.f[1];

        if (avg_vol < 300)
        {
            cough_score = 0.0;
            if (millis() - last_dot_time > 2000)
            {
                Serial.print(".");
                last_dot_time = millis();
            }
        }
        else
        {
            if (cough_score > COUGH_THRESHOLD && (millis() - last_alert_time > 5000))
            {
                Serial.println("\n🚨  COUGH DETECTED!");
                Serial.printf("    Confidence: %.1f%%  |  Volume: %d\n", cough_score * 100, (int)avg_vol);

                CoughEvent event = {cough_score, avg_vol, millis()};
                xQueueSend(coughQueue, &event, 0);
                last_alert_time = millis();
            }
            else if (avg_vol > 500)
            {
                Serial.printf("\n🔊  Noise Detected (Vol: %d, Cough Prob: %.1f%%)\n", (int)avg_vol, cough_score * 100);
            }
        }
        vTaskDelay(10 / portTICK_PERIOD_MS);
    }
}

// =========================================================
// 7. MAIN SETUP & LOOP
// =========================================================
void setup()
{
    Serial.begin(115200);
    delay(2000);
    Serial.println("\n\n=================================");
    Serial.println("   AIREA MONITORING SYSTEM       ");
    Serial.println("   Status: COMPETITION MODE      ");
    Serial.println("=================================");

    // 1. Wi-Fi Setup
    Serial.print("Connecting to WiFi...");
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delay(500);
        Serial.print(".");
    }
    Serial.println("\n✅ WiFi Connected.");

    // 2. Queue & Memory Initialization
    coughQueue = xQueueCreate(5, sizeof(CoughEvent));

    tensor_arena = (uint8_t *)ps_malloc(kArenaSize);
    if (!tensor_arena)
        tensor_arena = (uint8_t *)malloc(kArenaSize);

    raw_audio_buffer = (int16_t *)ps_malloc(kAudioBufferSize * sizeof(int16_t));
    if (!raw_audio_buffer)
        raw_audio_buffer = (int16_t *)malloc(kAudioBufferSize * sizeof(int16_t));

    if (!tensor_arena || !raw_audio_buffer)
    {
        Serial.println("❌ CRITICAL: Memory Allocation Failed.");
        while (1)
            ;
    }

    // 3. TFLite Initialization
    model = tflite::GetModel(model_data);
    static tflite::MicroInterpreter static_interpreter(model, resolver, tensor_arena, kArenaSize, &micro_error_reporter);
    interpreter = &static_interpreter;
    interpreter->AllocateTensors();
    input = interpreter->input(0);
    output = interpreter->output(0);

    // 4. BioMonitor Start
    bioMonitor.begin();

    // 5. Start FreeRTOS Tasks
    xTaskCreatePinnedToCore(network_sender_task, "NetSender", 8192, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(audio_inference_task, "AudioAI", 8192, NULL, 2, NULL, 0);
}

void loop()
{
    // Hardware Sensors
    bioMonitor.update();

    // Push Vitals to Backend (Every 5 Seconds)
    static unsigned long lastVitalsSync = 0;
    if (millis() - lastVitalsSync > 5000)
    {
        if (WiFi.status() == WL_CONNECTED)
        {
            WiFiClientSecure client;
            client.setInsecure();
            HTTPClient http;
            if (http.begin(client, vitalsUrl))
            {
                http.addHeader("Content-Type", "application/json");

                String json = "{\"deviceId\":\"ESP32_COUGH_01\", ";
                json += "\"type\":\"VITALS_UPDATE\", ";
                json += "\"temp\":" + String(bioMonitor.getTemp()) + ", ";
                json += "\"bpm\":" + String(bioMonitor.getBPM()) + ", ";
                json += "\"rr\":" + String(bioMonitor.getRR()) + ", ";
                json += "\"leadsOff\":" + String(bioMonitor.leadsAreOff ? "true" : "false") + "}";

                int response = http.POST(json);
                if (response > 0)
                {
                    Serial.println("🌐 Vitals Synced: " + json);
                }
                http.end();
            }
        }
        lastVitalsSync = millis();
    }

    delay(10);
}