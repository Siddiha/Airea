#include <Arduino.h>
#include <driver/i2s.h>
#include "cough_model.h"

// 📦 TENSORFLOW LITE INCLUDES
#include "tensorflow/lite/micro/all_ops_resolver.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/schema/schema_generated.h"

// 🔌 PIN DEFINITIONS (ESP32-S3 N16R8)
#define I2S_WS 5  // Word Select (LRC)
#define I2S_SD 6  // Serial Data (DIN)
#define I2S_SCK 4 // Serial Clock (BCLK)
#define I2S_PORT I2S_NUM_0

// 🎤 AUDIO SETTINGS
#define SAMPLE_RATE 16000
#define RECORD_TIME 2
const int kAudioBufferSize = SAMPLE_RATE * RECORD_TIME;

// 🧠 AI MEMORY SETTINGS (8MB PSRAM available)
const int kArenaSize = 200 * 1024;
uint8_t *tensor_arena;

// 🛠 GLOBAL VARIABLES
tflite::MicroErrorReporter micro_error_reporter;
tflite::AllOpsResolver resolver;
const tflite::Model *model;
tflite::MicroInterpreter *interpreter;
TfLiteTensor *input;
TfLiteTensor *output;

// Audio Buffer (Allocated in PSRAM)
int16_t *raw_audio_buffer;

// -------------------------------------------------------------------------
// 🛠 SETUP I2S MICROPHONE
// -------------------------------------------------------------------------
void setup_i2s()
{
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
        .tx_desc_auto_clear = false,
        .fixed_mclk = 0};

    const i2s_pin_config_t pin_config = {
        .bck_io_num = I2S_SCK,
        .ws_io_num = I2S_WS,
        .data_out_num = I2S_PIN_NO_CHANGE,
        .data_in_num = I2S_SD};

    i2s_driver_install(I2S_PORT, &i2s_config, 0, NULL);
    i2s_set_pin(I2S_PORT, &pin_config);
}

// -------------------------------------------------------------------------
// 🔁 SETUP
// -------------------------------------------------------------------------
void setup()
{
    Serial.begin(115200);
    delay(3000); // Wait for Mac USB

    Serial.println("📢 Airea (S3): System Online.");

    // 1. ALLOCATE MEMORY (PSRAM)
    tensor_arena = (uint8_t *)ps_malloc(kArenaSize);
    raw_audio_buffer = (int16_t *)ps_malloc(kAudioBufferSize * sizeof(int16_t));

    if (!tensor_arena || !raw_audio_buffer)
    {
        Serial.println("❌ PSRAM Allocation Failed!");
        while (1)
            ;
    }

    // 2. LOAD MODEL
    model = tflite::GetModel(model_data);
    if (model->version() != TFLITE_SCHEMA_VERSION)
    {
        Serial.println("❌ Schema Mismatch!");
        while (1)
            ;
    }

    // 3. START INTERPRETER
    static tflite::MicroInterpreter static_interpreter(
        model, resolver, tensor_arena, kArenaSize, &micro_error_reporter);
    interpreter = &static_interpreter;

    if (interpreter->AllocateTensors() != kTfLiteOk)
    {
        Serial.println("❌ AllocateTensors Failed!");
        while (1)
            ;
    }

    input = interpreter->input(0);
    output = interpreter->output(0);

    // 4. START MIC
    setup_i2s();
    Serial.println("✅ AI Active. Waiting for sound...");
}

// -------------------------------------------------------------------------
// 🔁 MAIN LOOP (With Noise + Cough Output)
// -------------------------------------------------------------------------
void loop()
{
    size_t bytes_read = 0;

    // 1. LISTEN
    i2s_read(I2S_PORT, raw_audio_buffer, kAudioBufferSize * sizeof(int16_t), &bytes_read, portMAX_DELAY);

    // 2. AMPLIFY (Software Gain 8x)
    int gain_factor = 8;
    float average_vol = 0;
    for (int i = 0; i < kAudioBufferSize; i++)
    {
        int32_t amplified = raw_audio_buffer[i] * gain_factor;
        // Clamp values
        if (amplified > 32767)
            amplified = 32767;
        if (amplified < -32768)
            amplified = -32768;

        raw_audio_buffer[i] = (int16_t)amplified;
        average_vol += abs(raw_audio_buffer[i]);
    }
    average_vol /= kAudioBufferSize;

    // 3. PREPARE FOR AI
    if (input->type == kTfLiteInt8)
    {
        int8_t *input_data = input->data.int8;
        for (int i = 0; i < kAudioBufferSize; i++)
        {
            if (i < input->bytes)
                input_data[i] = (raw_audio_buffer[i] >> 8);
        }
    }
    else
    {
        for (int i = 0; i < kAudioBufferSize; i++)
        {
            if (i < input->bytes / sizeof(float))
                input->data.f[i] = raw_audio_buffer[i] / 32768.0f;
        }
    }

    // 4. THINK
    interpreter->Invoke();

    // 5. DECIDE
    float noise_score = 0;
    float cough_score = 0;

    if (output->type == kTfLiteInt8)
    {
        float scale = output->params.scale;
        int zero_point = output->params.zero_point;
        noise_score = (output->data.int8[0] - zero_point) * scale;
        cough_score = (output->data.int8[1] - zero_point) * scale;
    }
    else
    {
        noise_score = output->data.f[0];
        cough_score = output->data.f[1];
    }

    // 6. REPORT (Shows Both Scores)
    Serial.print("🎤 Vol: ");
    Serial.print((int)average_vol);
    Serial.print(" | 🛡️ Noise: ");
    Serial.print(noise_score * 100);
    Serial.print("% | 🧠 Cough: ");
    Serial.print(cough_score * 100);
    Serial.println("%");

    // 7. ACT
    // LOWERED THRESHOLD: 0.70 (70%)
    // This catches the "hesitant" coughs but still ignores background noise.
    if (cough_score > 0.90)
    {
        Serial.println("🚨 🚨 🚨 COUGH DETECTED! 🚨 🚨 🚨");
        delay(1000);
    }
}