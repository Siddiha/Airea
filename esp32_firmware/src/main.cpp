#include <Arduino.h>
#include <driver/i2s.h>
#include <stdint.h>
#include <TensorFlowLite_ESP32.h>
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "model.h"

// --- ⚙️ CONFIGURATION (1.5s SAFE MODE + TURBO BOOSTER) ---
#define SAMPLE_RATE 16000

// 1. Raw Recording Time (1.5 Seconds)
// 16000 Hz * 1.5 Seconds = 24000 samples
#define RECORD_TIME 24000

// 2. AI Input Size (Downsampled by 4)
// The "Sunglasses Effect" to ignore wind.
// 24000 / 4 = 6000 inputs.
#define AI_INPUT_SIZE 6000

// --- 🛡️ SENSITIVITY SETTINGS ---
#define NOISE_GATE_THRESHOLD 250
#define TRIGGER_THRESHOLD 150

// --- 🔌 PINS (INMP441) ---
#define I2S_WS 15
#define I2S_SD 32
#define I2S_SCK 14
#define I2S_PORT I2S_NUM_0

// --- 💾 BUFFERS ---
int16_t *raw_capture_buffer = nullptr;
int16_t i2s_chunk[512];

// --- 🧠 TFLITE GLOBALS ---
uint8_t *tensor_arena = nullptr;

// MEMORY SAFE ZONE:
// Model is ~8KB. Input is 6000.
// 55KB is plenty of space without crashing.
const int kArenaSize = 55 * 1024;

tflite::MicroErrorReporter micro_error_reporter;
tflite::MicroInterpreter *interpreter = nullptr;
TfLiteTensor *input = nullptr;
TfLiteTensor *output = nullptr;

// --- HARDWARE SETUP ---
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
    Serial.println("📢 Airea Cough Monitor: Starting...");

    // Dynamic Memory Allocation
    tensor_arena = (uint8_t *)malloc(kArenaSize);
    raw_capture_buffer = (int16_t *)malloc(RECORD_TIME * sizeof(int16_t));

    if (tensor_arena == nullptr || raw_capture_buffer == nullptr)
    {
        Serial.println("❌ CRITICAL ERROR: Heap Malloc Failed!");
        Serial.println("   The ESP32 ran out of RAM.");
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
        Serial.println("❌ TFLite Error: Arena too small?");
        while (1)
            ;
    }

    input = interpreter->input(0);
    output = interpreter->output(0);
    Serial.println("✅ System Ready. Listening...");
}

// --- MAIN AI LOGIC (TURBO BOOSTED) ---
void RecordAndClassify()
{
    Serial.println(" -> 🔴 Recording 1.5 Seconds...");

    // 1. CAPTURE AUDIO
    int write_index = 0;
    size_t bytes_in = 0;

    // Clear buffer
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

    // 2. NOISE GATE
    for (int i = 0; i < RECORD_TIME; i++)
    {
        if (abs(raw_capture_buffer[i]) < NOISE_GATE_THRESHOLD)
        {
            raw_capture_buffer[i] = 0;
        }
    }

    // 3. AUTO-GAIN
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
    if (gain_factor < 1.0)
        gain_factor = 1.0;

    // 4. PREPARE AI INPUT (Downsample by 4)
    for (int i = 0; i < AI_INPUT_SIZE; i++)
    {
        int16_t raw_sample = raw_capture_buffer[i * 4];

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
    float raw_confidence = (score_cough + 128) / 255.0;

    // 🚀 TURBO BOOSTER LOGIC
    // Based on your logs: Wind is < 0.03. Cough is > 0.15.
    float display_confidence = 0.0;

    // Only boost if it's clearly NOT wind (above 0.05)
    if (raw_confidence > 0.05)
    {
        // Multiply by 4.0 (Aggressive Boost)
        display_confidence = raw_confidence * 4.0;

        // Cap at 99%
        if (display_confidence > 0.99)
            display_confidence = 0.99;
    }

    Serial.print("   Raw Score: ");
    Serial.print(raw_confidence);
    Serial.print(" -> Display: ");
    Serial.print(display_confidence * 100);
    Serial.println("%");

    // --- FINAL DECISION ---
    if (display_confidence > 0.75)
    {
        Serial.println("   ✅ Confirmed Cough");
    }
    else if (display_confidence > 0.60)
    {
        Serial.println("   ❓ Possible Cough");
    }
    else
    {
        Serial.println("   ❌ Noise / Ignored");
    }
    Serial.println("-----------------------------");
}

// --- MAIN LOOP (THIS WAS MISSING!) ---
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
        Serial.print("🔊 Triggered! (Vol: ");
        Serial.print(average);
        Serial.println(")");
        RecordAndClassify();
        delay(500); // Short pause
    }
}