#include <Arduino.h>
#include <driver/i2s.h>
#include <WiFi.h>
#include <HTTPClient.h>
#include <WiFiClientSecure.h> // Required for Railway HTTPS
#include "cough_model.h"

// --- FREERTOS INCLUDES ---
#include "freertos/FreeRTOS.h"
#include "freertos/task.h"
#include "freertos/queue.h"

// --- WI-FI CREDENTIALS ---
const char *ssid = "Dialog 4G 437";
const char *password = "20040920";

// --- SERVER URL ---
const char *serverUrl = "https://airea-production.up.railway.app/api/cough/event";

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
TfLiteTensor *input = nullptr;
TfLiteTensor *output = nullptr;

// -------------------------------------------------------------------------
// TASK 1: NETWORK SENDER (Fixed for Railway HTTPS)
// -------------------------------------------------------------------------
void network_sender_task(void *parameter)
{
    CoughEvent receivedEvent;

    while (true)
    {
        if (xQueueReceive(coughQueue, &receivedEvent, portMAX_DELAY) == pdTRUE)
        {

            Serial.println();
            Serial.print("☁️  [Cloud] Uploading Event... ");

            if (WiFi.status() != WL_CONNECTED)
            {
                Serial.print("(Connecting Wi-Fi)... ");
                WiFi.begin(ssid, password);
                int attempts = 0;
                while (WiFi.status() != WL_CONNECTED && attempts < 20)
                {
                    vTaskDelay(500 / portTICK_PERIOD_MS);
                    attempts++;
                }
            }

            if (WiFi.status() == WL_CONNECTED)
            {
                // --- HTTPS FIX START ---
                WiFiClientSecure client;
                client.setInsecure(); // Trust Railway Certificate
                client.setTimeout(10000);

                HTTPClient http;

                // Use the secure client!
                if (http.begin(client, serverUrl))
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
                else
                {
                    Serial.println("Connection Failed.");
                }
                // --- HTTPS FIX END ---
            }
            else
            {
                Serial.println("Failed (No Wi-Fi).");
            }
            Serial.println("------------------------------------------------");
        }
    }
}

// -------------------------------------------------------------------------
// TASK 2: AI LISTENER (Fixed for 0% on Silence)
// -------------------------------------------------------------------------
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

    Serial.println("🎤  System Ready. Listening...");

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

        TfLiteStatus invoke_status = interpreter->Invoke();
        if (invoke_status != kTfLiteOk)
            continue;

        float cough_score = 0;
        if (output->type == kTfLiteInt8)
        {
            float scale = output->params.scale;
            int zero_point = output->params.zero_point;
            cough_score = (output->data.int8[1] - zero_point) * scale;
        }
        else
        {
            cough_score = output->data.f[1];
        }

        // --- 🛠️ 0% FIX START ---
        // If volume is low, force score to 0.0
        if (avg_vol < 300)
        {
            cough_score = 0.0;

            // Heartbeat
            if (millis() - last_dot_time > 2000)
            {
                Serial.print(".");
                last_dot_time = millis();
            }
        }
        // --- 0% FIX END ---

        else
        {
            if (cough_score > COUGH_THRESHOLD && (millis() - last_alert_time > 5000))
            {
                Serial.println("\n");
                Serial.println("🚨  COUGH DETECTED!");
                Serial.printf("    Confidence: %.1f%%  |  Volume: %d\n", cough_score * 100, (int)avg_vol);

                CoughEvent event;
                event.confidence = cough_score;
                event.volume = avg_vol;
                event.timestamp = millis();
                xQueueSend(coughQueue, &event, 0);
                last_alert_time = millis();
            }
            else if (avg_vol > 500)
            {
                Serial.println();
                Serial.printf("🔊  Noise Detected (Vol: %d, Cough Prob: %.1f%%)\n", (int)avg_vol, cough_score * 100);
            }
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
    Serial.println("   AIREA MONITORING SYSTEM       ");
    Serial.println("   Status: ONLINE                ");
    Serial.println("=================================");

    coughQueue = xQueueCreate(5, sizeof(CoughEvent));

    tensor_arena = (uint8_t *)ps_malloc(kArenaSize);
    raw_audio_buffer = (int16_t *)ps_malloc(kAudioBufferSize * sizeof(int16_t));

    if (!tensor_arena || !raw_audio_buffer)
    {
        Serial.println("❌ Memory Error.");
        while (1)
            ;
    }

    model = tflite::GetModel(model_data);
    static tflite::MicroInterpreter static_interpreter(model, resolver, tensor_arena, kArenaSize, &micro_error_reporter);
    interpreter = &static_interpreter;
    interpreter->AllocateTensors();

    input = interpreter->input(0);
    output = interpreter->output(0);

    xTaskCreatePinnedToCore(network_sender_task, "NetSender", 8192, NULL, 1, NULL, 0);
    xTaskCreatePinnedToCore(audio_inference_task, "AudioAI", 8192, NULL, 2, NULL, 1);
}

void loop() { vTaskDelay(1000); }