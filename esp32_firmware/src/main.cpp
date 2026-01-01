#include <Arduino.h>
#include <driver/i2s.h>
#include <stdint.h>
#include <TensorFlowLite_ESP32.h>
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "model.h"

// --- ⚙️ S3 ULTIMATE CONFIGURATION ---
#define SAMPLE_RATE 16000

// 2 Seconds of Recording (Full Duration)
#define RECORD_TIME 32000

// High Quality Input (Downsample by 2)
// 32000 / 2 = 16000 Inputs. (The S3 handles this easily)
#define AI_INPUT_SIZE 16000

// --- SENSITIVITY ---
#define NOISE_GATE_THRESHOLD 300
#define TRIGGER_THRESHOLD 200
#define CONFIDENCE_THRESHOLD 0.70

// --- 🔌 S3 PINS (WIRED TO 4, 5, 6) ---
// ⚠️ MAKE SURE YOU WIRE YOUR MIC TO THESE PINS!
#define I2S_SCK 4
#define I2S_WS 5
#define I2S_SD 6
#define I2S_PORT I2S_NUM_0

// --- 💾 BUFFERS ---
int16_t *raw_capture_buffer = nullptr;
int16_t i2s_chunk[512];

// --- 🧠 TFLITE GLOBALS ---
uint8_t *tensor_arena = nullptr;

// MEMORY LUXURY: We allocate 200KB because your board has 8MB!
const int kArenaSize = 200 * 1024;

tflite::MicroErrorReporter micro_error_reporter;
tflite::MicroInterpreter *interpreter = nullptr;
TfLiteTensor *input = nullptr;
TfLiteTensor *output = nullptr;

void i2s_install()
{
    const i2s_config_t i2s_config = {
        .mode = (i2s_mode_t)(I2S_MODE_MASTER | I2S_MODE_RX),
        .sample_rate = SAMPLE_RATE,
        .bits_per_sample = I2S_BITS_PER_SAMPLE_16BIT,
        .channel_format = I2S_CHANNEL_FMT_ONLY_LEFT,
        .communication_format = I2S_COMM_FORMAT_STAND_I2S,
        .intr_alloc_flags = ESP_INTR_FLAG_LEVEL1,
        .dma_buf_count = 8,
        .dma_buf_len = 512,
        .use_apll = false};
    i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
}

void i2s_setpin()
{
    const i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_SCK,
        .ws_io_num = I2S_WS,
        .data_out_num = -1,
        .data_in_num = I2S_SD};
    i2s_set_pin(I2S_PORT, &pin_config);
}

void setup()
{
    Serial.begin(115200);
    Serial.println("📢 Airea (S3 N16R8 Edition): Starting...");

    // Allocating Memory from PSRAM (The 8MB chip)
    tensor_arena = (uint8_t *)ps_malloc(kArenaSize);
    raw_capture_buffer = (int16_t *)ps_malloc(RECORD_TIME * sizeof(int16_t));

    // Fallback if PSRAM fails (just in case)
    if (tensor_arena == nullptr)
    {
        Serial.println("⚠️ PSRAM Failed! Using Internal RAM...");
        tensor_arena = (uint8_t *)malloc(kArenaSize);
        raw_capture_buffer = (int16_t *)malloc(RECORD_TIME * sizeof(int16_t));
    }

    if (tensor_arena == nullptr)
    {
        Serial.println("❌ CRITICAL ERROR: Memory Allocation Failed!");
        while (1)
            ;
    }

    i2s_install();
    i2s_setpin();
    i2s_start(I2S_PORT);

    static tflite::AllOpsResolver resolver;
    const tflite::Model *model = tflite::GetModel(model_data);
    static tflite::MicroInterpreter static_interpreter(
        model, resolver, tensor_arena, kArenaSize, &micro_error_reporter);
    interpreter = &static_interpreter;

    if (interpreter->AllocateTensors() != kTfLiteOk)
    {
        Serial.println("❌ Arena Error");
        while (1)
            ;
    }

    input = interpreter->input(0);
    output = interpreter->output(0);
    Serial.println("✅ S3 Ready. Power Level: MAXIMUM.");
}

void RecordAndClassify()
{
    Serial.println(" -> 🔴 Recording 2 Seconds...");

    int write_index = 0;
    size_t bytes_in = 0;
    i2s_read(I2S_PORT, &i2s_chunk, sizeof(i2s_chunk), &bytes_in, 10);

    while (write_index < RECORD_TIME)
    {
        i2s_read(I2S_PORT, &i2s_chunk, sizeof(i2s_chunk), &bytes_in, portMAX_DELAY);
        int samples_read = bytes_in / 2;
        for (int i = 0; i < samples_read; i++)
        {
            if (write_index < RECORD_TIME)
                raw_capture_buffer[write_index++] = i2s_chunk[i];
        }
    }

    // Noise Gate
    for (int i = 0; i < RECORD_TIME; i++)
    {
        if (abs(raw_capture_buffer[i]) < NOISE_GATE_THRESHOLD)
            raw_capture_buffer[i] = 0;
    }

    // Auto-Gain
    int16_t max_val = 0;
    for (int i = 0; i < RECORD_TIME; i++)
    {
        if (abs(raw_capture_buffer[i]) > max_val)
            max_val = abs(raw_capture_buffer[i]);
    }
    if (max_val < 100)
        max_val = 100;
    float gain_factor = 26000.0 / (float)max_val;
    if (gain_factor > 40.0)
        gain_factor = 40.0;

    // 4. PREPARE INPUT (Downsample by 2 for High Quality)
    for (int i = 0; i < AI_INPUT_SIZE; i++)
    {
        int16_t raw_sample = raw_capture_buffer[i * 2]; // Keep crisp quality
        int32_t boosted = (int32_t)(raw_sample * gain_factor);
        if (boosted > 32767)
            boosted = 32767;
        if (boosted < -32768)
            boosted = -32768;
        input->data.int8[i] = (int8_t)(boosted >> 8);
    }

    // 5. RUN AI
    interpreter->Invoke();
    int8_t score_cough = output->data.int8[1];
    float confidence = (score_cough + 128) / 255.0;

    Serial.print("   Confidence: ");
    Serial.print(confidence * 100);
    Serial.println("%");

    if (confidence > CONFIDENCE_THRESHOLD)
    {
        Serial.println("   ✅ COUGH DETECTED");
    }
    else if (confidence > 0.50)
    {
        Serial.println("   ❓ Possible Cough");
    }
    else
    {
        Serial.println("   ❌ Noise");
    }
    Serial.println("-----------------------------");
}

void loop()
{
    size_t bytesIn = 0;
    i2s_read(I2S_PORT, &i2s_chunk, sizeof(i2s_chunk), &bytesIn, portMAX_DELAY);
    long sum = 0;
    for (int i = 0; i < 512; i++)
        sum += abs(i2s_chunk[i]);
    float average = sum / 512.0;

    if (average > TRIGGER_THRESHOLD)
    {
        Serial.println("🔊 Triggered!");
        RecordAndClassify();
        delay(500);
    }
}