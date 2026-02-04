/*
 * AIREA Project - Final Firmware (Logistic Fix)
 * Hardware: ESP32-S3 + MPU6050
 * Status: READY FOR FINAL TEST
 */

#include <Arduino.h>
#include <Wire.h>

#include "tensorflow/lite/micro/micro_mutable_op_resolver.h"
#include "tensorflow/lite/micro/micro_interpreter.h"
#include "tensorflow/lite/micro/system_setup.h"
#include "tensorflow/lite/schema/schema_generated.h"
#include "tensorflow/lite/micro/micro_error_reporter.h"

#include "fall_model.h"

#define SDA_PIN 1
#define SCL_PIN 2
#define MPU_ADDR 0x68

const int kTensorArenaSize = 60 * 1024;
uint8_t *tensor_arena = nullptr;

tflite::MicroInterpreter *interpreter = nullptr;
// Increased to 30 to cover everything
tflite::MicroMutableOpResolver<30> *resolver = nullptr;
tflite::ErrorReporter *error_reporter = nullptr;
const tflite::Model *model = nullptr;
TfLiteTensor *input = nullptr;
TfLiteTensor *output = nullptr;

const int TIME_STEPS = 200;
const int NUM_FEATURES = 6;
const int INPUT_BUFFER_SIZE = TIME_STEPS * NUM_FEATURES;
float data_buffer[INPUT_BUFFER_SIZE];
int buffer_head = 0;
const float FALL_CONFIDENCE = 0.85;
const int ALARM_COOLDOWN = 5000;

void writeMPU(byte reg, byte data)
{
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(reg);
    Wire.write(data);
    Wire.endTransmission();
}

void setup()
{
    delay(3000);
    Serial.begin(115200);
    while (!Serial)
        delay(10);
    Serial.println("\n--- AIREA SYSTEM FINAL ---");

    Wire.begin(SDA_PIN, SCL_PIN, 100000);
    writeMPU(0x6B, 0);
    delay(50);
    writeMPU(0x1C, 0x08);
    writeMPU(0x1B, 0x08);

    static tflite::MicroErrorReporter micro_error_reporter;
    error_reporter = &micro_error_reporter;

    model = tflite::GetModel(fall_model);
    if (model->version() != TFLITE_SCHEMA_VERSION)
    {
        error_reporter->Report("Model version %d not supported!", model->version());
        while (1)
            ;
    }

    tensor_arena = (uint8_t *)malloc(kTensorArenaSize + 16);
    if (!tensor_arena)
    {
        Serial.println("❌ Malloc Failed");
        while (1)
            ;
    }
    uintptr_t arena_addr = (uintptr_t)tensor_arena;
    if (arena_addr % 16 != 0)
        arena_addr += (16 - (arena_addr % 16));
    tensor_arena = (uint8_t *)arena_addr;

    resolver = new tflite::MicroMutableOpResolver<30>();

    // --- COMPLETE OP LIST ---
    resolver->AddFullyConnected();
    resolver->AddSoftmax();
    resolver->AddReshape();
    resolver->AddRelu();
    resolver->AddQuantize();
    resolver->AddDequantize();
    resolver->AddConv2D();
    resolver->AddExpandDims();
    resolver->AddConcatenation();
    resolver->AddPack();
    resolver->AddMaxPool2D();
    resolver->AddShape();

    // [FIX] The missing piece for tonight:
    resolver->AddLogistic(); // This fixes the "LOGISTIC" error

    // Extras just in case:
    resolver->AddFill();
    resolver->AddSplit();
    resolver->AddSplitV();
    resolver->AddStridedSlice();
    resolver->AddMean();
    resolver->AddPad();
    resolver->AddAdd();
    resolver->AddMul();

    interpreter = new tflite::MicroInterpreter(
        model, *resolver, tensor_arena, kTensorArenaSize, error_reporter);

    if (interpreter->AllocateTensors() != kTfLiteOk)
    {
        Serial.println("❌ Failed to Allocate Tensors!");
        while (1)
            ;
    }

    input = interpreter->input(0);
    output = interpreter->output(0);
    Serial.println("✅ AIREA Armed & Monitoring...");
}

void loop()
{
    Wire.beginTransmission(MPU_ADDR);
    Wire.write(0x3B);
    Wire.endTransmission(false);
    Wire.requestFrom((uint16_t)MPU_ADDR, (uint8_t)14, true);

    if (Wire.available() == 14)
    {
        int16_t raw_ax = Wire.read() << 8 | Wire.read();
        int16_t raw_ay = Wire.read() << 8 | Wire.read();
        int16_t raw_az = Wire.read() << 8 | Wire.read();
        Wire.read();
        Wire.read();
        int16_t raw_gx = Wire.read() << 8 | Wire.read();
        int16_t raw_gy = Wire.read() << 8 | Wire.read();
        int16_t raw_gz = Wire.read() << 8 | Wire.read();

        float norm_ax = (raw_ax / 8192.0 * 9.81) / 20.0;
        float norm_ay = (raw_ay / 8192.0 * 9.81) / 20.0;
        float norm_az = (raw_az / 8192.0 * 9.81) / 20.0;
        float norm_gx = (raw_gx / 65.5) / 500.0;
        float norm_gy = (raw_gy / 65.5) / 500.0;
        float norm_gz = (raw_gz / 65.5) / 500.0;

        for (int i = 0; i < INPUT_BUFFER_SIZE - 6; i++)
        {
            data_buffer[i] = data_buffer[i + 6];
        }
        int tail = INPUT_BUFFER_SIZE - 6;
        data_buffer[tail + 0] = norm_ax;
        data_buffer[tail + 1] = norm_ay;
        data_buffer[tail + 2] = norm_az;
        data_buffer[tail + 3] = norm_gx;
        data_buffer[tail + 4] = norm_gy;
        data_buffer[tail + 5] = norm_gz;

        buffer_head++;
        if (buffer_head < TIME_STEPS)
        {
            delay(10);
            return;
        }

        for (int i = 0; i < INPUT_BUFFER_SIZE; i++)
            input->data.f[i] = data_buffer[i];

        if (interpreter->Invoke() == kTfLiteOk)
        {
            float fall_prob = output->data.f[0];
            if (fall_prob > FALL_CONFIDENCE)
            {
                Serial.println("\n🚨 FALL DETECTED! 🚨");
                buffer_head = 0;
                delay(ALARM_COOLDOWN);
            }
        }
    }
    delay(10);
}