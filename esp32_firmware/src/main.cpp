#include <Arduino.h>
#include <driver/i2s.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include "cough_model.h"

// --- FREERTOS INCLUDES ---
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

// --- WI-FI CREDENTIALS ---
const char *ssid = "Dialog 4G 437";
const char *password = "20040920";

// --- SERVER URL ---
// Make sure this IP matches your computer's IP!
const char *serverUrl = "http://192.168.8.102:8080/api/cough/event";

// --- TENSORFLOW INCLUDES ---
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

// --- PIN DEFINITIONS (ESP32-S3) ---
#define I2S_WS 5
#define I2S_SD 6
#define I2S_SCK 4
#define I2S_PORT I2S_NUM_0

// --- AUDIO SETTINGS ---
#define SAMPLE_RATE 16000
const int kAudioBufferSize = 32000; // 2 Seconds
#define COUGH_THRESHOLD 0.90

// --- QUEUE STRUCTURE ---
struct CoughEvent
{
    float confidence;
    float volume;
    unsigned long timestamp;
};
QueueHandle_t coughQueue;

// --- GLOBALS ---
const int kArenaSize = 200 * 1024;
uint8_t *tensor_arena;
int16_t *raw_audio_buffer;

tflite::MicroErrorReporter micro_error_reporter;
tflite::AllOpsResolver resolver;
const tflite::Model *model;
tflite::MicroInterpreter *interpreter;
TfLiteTensor *input;
TfLiteTensor *output;

// -------------------------------------------------------------------------
// TASK 1: NETWORK SENDER (Runs on CORE 0)
// Handles Wi-Fi logs and Uploads
// -------------------------------------------------------------------------
void network_sender_task(void *parameter)
{
    CoughEvent receivedEvent;

    while (true)
    {
        // Wait for data (Blocks until cough detected)
        if (xQueueReceive(coughQueue, &receivedEvent, portMAX_DELAY) == pdTRUE)
        {

            Serial.println("\n--- [Network] Starting Upload Sequence ---");
            Serial.print("[Network] Event Received! Confidence: ");
            Serial.print(receivedEvent.confidence * 100);
            Serial.println("%");

            // Connect Wi-Fi
            if (WiFi.status() != WL_CONNECTED)
            {
                Serial.print("[Network] Connecting to Wi-Fi: ");
                Serial.print(ssid);

                WiFi.begin(ssid, password);
                int attempts = 0;
                while (WiFi.status() != WL_CONNECTED && attempts < 20)
                {
                    vTaskDelay(500 / portTICK_PERIOD_MS);
                    Serial.print(".");
                    attempts++;
                }
                Serial.println();
            }

            if (WiFi.status() == WL_CONNECTED)
            {
                Serial.println("[Network] Wi-Fi Connected! IP: " + WiFi.localIP().toString());

                HTTPClient http;
                http.begin(serverUrl);
                http.addHeader("Content-Type", "application/json");

                // Construct JSON
                String jsonPayload = "{";
                jsonPayload += "\"deviceId\":\"ESP32_COUGH_01\",";
                jsonPayload += "\"confidence\":" + String(receivedEvent.confidence, 3) + ",";
                jsonPayload += "\"rawScore\":" + String(receivedEvent.confidence, 3) + ",";
                jsonPayload += "\"timestamp\":" + String(receivedEvent.timestamp) + ",";
                jsonPayload += "\"audioVolume\":" + String(receivedEvent.volume, 2);
                jsonPayload += "}";

                Serial.println("[Network] Sending Payload: " + jsonPayload);

                int httpResponseCode = http.POST(jsonPayload);

                if (httpResponseCode > 0)
                {
                    Serial.printf("[Network]  Upload Success! Response Code: %d\n", httpResponseCode);
                }
                else
                {
                    Serial.printf("[Network]  Upload Failed! Error: %s\n", http.errorToString(httpResponseCode).c_str());
                }
                http.end();
            }
            else
            {
                Serial.println("[Network]  Wi-Fi Connection Failed.");
            }
            Serial.println("------------------------------------------\n");
        }
    }
}

// -------------------------------------------------------------------------
// TASK 2: AI LISTENER (Runs on CORE 1)
// Handles Audio, Inference, and Live Terminal Logs
// -------------------------------------------------------------------------
void audio_inference_task(void *parameter)
{
    size_t bytes_read = 0;
    static unsigned long last_alert_time = 0;

    // Init I2S
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

    Serial.println("[AI] Listening for sound...");

    while (true)
    {
        // 1. LISTEN (Blocks for 2 seconds)
        i2s_read(I2S_PORT, raw_audio_buffer, kAudioBufferSize * sizeof(int16_t), &bytes_read, portMAX_DELAY);

        // 2. PROCESS (Downsample 32k -> 16k & Amplify)
        int8_t *input_data = input->data.int8;
        float avg_vol = 0;

        for (int i = 0; i < input->bytes; i++)
        {
            int16_t sample = raw_audio_buffer[i * 2];
            int32_t amplified = sample * 8; // Gain 8x
            if (amplified > 32767)
                amplified = 32767;
            if (amplified < -32768)
                amplified = -32768;
            input_data[i] = (int8_t)(amplified >> 8);
            if (i % 100 == 0)
                avg_vol += abs(amplified);
        }
        avg_vol /= (input->bytes / 100);

        // 3. INFERENCE
        TfLiteStatus invoke_status = interpreter->Invoke();
        if (invoke_status != kTfLiteOk)
        {
            Serial.println("[AI] Inference Failed!");
            continue;
        }

        // 4. GET SCORES
        float noise_score = 0;
        float cough_score = 0;

        if (output->type == kTfLiteInt8)
        {
            float scale = output->params.scale;
            int zero_point = output->params.zero_point;
            // Index 0 = Noise, Index 1 = Cough
            noise_score = (output->data.int8[0] - zero_point) * scale;
            cough_score = (output->data.int8[1] - zero_point) * scale;
        }
        else
        {
            noise_score = output->data.f[0];
            cough_score = output->data.f[1];
        }

        // --- 📊 LIVE TERMINAL MONITORING ---
        // This prints every 2 seconds so you know it's alive
        Serial.print(" Noise: ");
        Serial.print(noise_score * 100, 1);
        Serial.print("% | Cough: ");
        Serial.print(cough_score * 100, 1);
        Serial.print("% | Vol: ");
        Serial.println((int)avg_vol);
        // ------------------------------------

        // 5. DETECT
        if (cough_score > COUGH_THRESHOLD && (millis() - last_alert_time > 5000))
        {
            Serial.println("\nCOUGH DETECTED!");
            Serial.println(">> Sending event to Network Task...");

            CoughEvent event;
            event.confidence = cough_score;
            event.volume = avg_vol;
            event.timestamp = millis();

            xQueueSend(coughQueue, &event, 0);
            last_alert_time = millis();
        }

        vTaskDelay(10 / portTICK_PERIOD_MS);
    }
}

// -------------------------------------------------------------------------
// SETUP
// -------------------------------------------------------------------------
void setup()
{
    Serial.begin(115200);
    delay(2000);
    Serial.println("\n\n=================================");
    Serial.println("   AIREA SYSTEM STARTING (S3)    ");
    Serial.println("=================================");

    // Create Queue
    coughQueue = xQueueCreate(5, sizeof(CoughEvent));

    // Allocate Memory
    tensor_arena = (uint8_t *)ps_malloc(kArenaSize);
    raw_audio_buffer = (int16_t *)ps_malloc(kAudioBufferSize * sizeof(int16_t));

    if (!tensor_arena || !raw_audio_buffer)
    {
        Serial.println("ERROR: PSRAM Malloc Failed! Enable 'OPI PSRAM'.");
        while (1)
            ;
    }
    Serial.println("PSRAM Allocated.");

    // Load Model
    model = tflite::GetModel(model_data);
    if (model->version() != TFLITE_SCHEMA_VERSION)
    {
        Serial.println("ERROR: Model Schema Mismatch!");
        while (1)
            ;
    }

    static tflite::MicroInterpreter static_interpreter(
        model, resolver, tensor_arena, kArenaSize, &micro_error_reporter);
    interpreter = &static_interpreter;
    interpreter->AllocateTensors();

    input = interpreter->input(0);
    output = interpreter->output(0);
    Serial.println("Model Loaded.");

    // Launch Tasks
    xTaskCreatePinnedToCore(network_sender_task, "NetSender", 8192, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(audio_inference_task, "AudioAI", 8192, NULL, 2, NULL, 1);

    Serial.println("Tasks Started. Waiting for audio...");
    Serial.println("=================================\n");
}

void loop()
{
    vTaskDelay(1000 / portTICK_PERIOD_MS);
}