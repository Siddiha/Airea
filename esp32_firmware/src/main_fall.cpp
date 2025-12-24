#include <Arduino.h>
#include <Wire.h>
#include <Adafruit_MPU6050.h>
#include <Adafruit_Sensor.h>
// Make sure "eloquentarduino/EloquentTinyML" is in your platformio.ini
#include <EloquentTinyML.h>

// INCLUDE YOUR TRAINED MODEL
#include "fall_model.h"

// ================= CONFIGURATION =================
// Hardware Pins
#define LED_PIN 2     // ESP32 Onboard LED
#define BUZZER_PIN 15 // Connect (+) of buzzer here

// AI Model Settings (MUST match your Python script)
#define NUMBER_OF_INPUTS 6          // AccX, AccY, AccZ, GyroX, GyroY, GyroZ
#define NUMBER_OF_OUTPUTS 1         // 0 = Safe, 1 = Fall
#define TENSOR_ARENA_SIZE 30 * 1024 // 30KB RAM for AI
#define WINDOW_SIZE 200             // 2 seconds window
#define SAMPLING_DELAY 10           // 10ms = 100Hz

// Logic Thresholds
#define AI_CONFIDENCE_THRESHOLD 0.75 // 75% sure it's a fall
#define POST_FALL_WAIT_TIME 5000     // 5 Seconds wait before checking orientation
#define LYING_DOWN_THRESHOLD 5.0     // If vertical gravity is < 5.0 m/s^2, they are horizontal

// ================= OBJECTS =================
Adafruit_MPU6050 mpu;
Eloquent::TinyML::TfLite<NUMBER_OF_INPUTS, NUMBER_OF_OUTPUTS, TENSOR_ARENA_SIZE> ml;

// Rolling Buffer for Sensor Data
float inputBuffer[WINDOW_SIZE * NUMBER_OF_INPUTS];

// ================= FUNCTION PROTOTYPES =================
void verifyAndAlert(float confidence);

// ================= SETUP =================
void setup()
{
    Serial.begin(115200);
    pinMode(LED_PIN, OUTPUT);
    pinMode(BUZZER_PIN, OUTPUT);

    delay(2000); // Wait for Serial
    Serial.println("\n--- LUNG CANCER FALL DETECTOR SYSTEM ---");

    // 1. Initialize Sensor
    if (!mpu.begin())
    {
        Serial.println("CRITICAL ERROR: MPU6050 not found! Check wiring.");
        while (1)
        {
            digitalWrite(LED_PIN, HIGH);
            delay(100);
            digitalWrite(LED_PIN, LOW);
            delay(100);
        }
    }
    Serial.println("Sensor: OK");

    // 2. Configure Sensor (Matches Robinovitch Dataset)
    mpu.setAccelerometerRange(MPU6050_RANGE_4_G);
    mpu.setGyroRange(MPU6050_RANGE_500_DEG);
    mpu.setFilterBandwidth(MPU6050_BAND_21_HZ);

    // 3. Initialize AI
    ml.begin(fall_model);
    Serial.println("AI Model: OK");
    Serial.println("System Status: ARMED & READY.");
}

// ================= MAIN LOOP =================
void loop()
{
    unsigned long start_time = millis();

    // 1. READ SENSOR
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // 2. SHIFT BUFFER (Remove oldest, shift left)
    for (int i = 0; i < (WINDOW_SIZE - 1) * NUMBER_OF_INPUTS; i++)
    {
        inputBuffer[i] = inputBuffer[i + NUMBER_OF_INPUTS];
    }

    // 3. ADD NEW DATA (At the end)
    int last_index = (WINDOW_SIZE - 1) * NUMBER_OF_INPUTS;

    // Acceleration
    inputBuffer[last_index + 0] = a.acceleration.x;
    inputBuffer[last_index + 1] = a.acceleration.y;
    inputBuffer[last_index + 2] = a.acceleration.z;

    // Gyroscope (CONVERT RAD -> DEG)
    // Python training used Degrees/s. MPU library gives Radians/s.
    inputBuffer[last_index + 3] = g.gyro.x * 57.2958;
    inputBuffer[last_index + 4] = g.gyro.y * 57.2958;
    inputBuffer[last_index + 5] = g.gyro.z * 57.2958;

    // 4. RUN AI CHECK (Every 100ms)
    static int counter = 0;
    if (counter++ > 10)
    {
        counter = 0;

        float prediction = ml.predict(inputBuffer);

        if (prediction > AI_CONFIDENCE_THRESHOLD)
        {
            // AI says "Impact Detected!" -> Now we verify physics.
            verifyAndAlert(prediction);

            // Reset buffer after handling event to prevent loops
            for (int i = 0; i < WINDOW_SIZE * NUMBER_OF_INPUTS; i++)
                inputBuffer[i] = 0;
        }
    }

    // 5. TIMING CONTROL (Maintain 100Hz)
    while (millis() - start_time < SAMPLING_DELAY)
        ;
}

// ================= LOGIC FUNCTIONS =================
void verifyAndAlert(float confidence)
{
    Serial.println("\n-----------------------------------------");
    Serial.print("1. IMPACT DETECTED! AI Confidence: ");
    Serial.print(confidence * 100);
    Serial.println("%");

    // Phase 2: Wait for the 'Long Lie' (5 Seconds)
    Serial.println("2. Waiting 5s to check if user recovers...");

    // Rapid blink while waiting
    unsigned long waitStart = millis();
    while (millis() - waitStart < POST_FALL_WAIT_TIME)
    {
        digitalWrite(LED_PIN, !digitalRead(LED_PIN)); // Toggle LED
        delay(100);
    }
    digitalWrite(LED_PIN, LOW);

    // Phase 3: Check Orientation (Physics)
    // We read the sensor FRESH right now.
    sensors_event_t a, g, temp;
    mpu.getEvent(&a, &g, &temp);

    // LOGIC: If user is Standing/Sitting, gravity (9.8) acts on the Vertical Axis.
    // If user is Lying Down, gravity acts on the Z-Axis (Chest to Back).
    // Assuming Y-Axis is vertical when standing:

    float vertical_gravity = abs(a.acceleration.y); // <--- CHANGE THIS AXIS IF NEEDED

    Serial.print("   Post-Fall Vertical Force: ");
    Serial.print(vertical_gravity);
    Serial.println(" m/s^2");

    if (vertical_gravity < LYING_DOWN_THRESHOLD)
    {
        // If vertical force is LOW (near 0), it means they are Horizontal.
        Serial.println("3. STATUS: HORIZONTAL -> FALL CONFIRMED!");
        Serial.println("!!! SENDING ALERT !!!");

        // --- FINAL ALARM ---
        digitalWrite(LED_PIN, HIGH);

        // Buzzer Loop (Requires reset/reboot to stop)
        while (1)
        {
            digitalWrite(BUZZER_PIN, HIGH);
            delay(500);
            digitalWrite(BUZZER_PIN, LOW);
            delay(500);
            Serial.println("...BEEP...");
        }
    }
    else
    {
        // If vertical force is HIGH (near 9.8), they are Upright.
        Serial.println("3. STATUS: UPRIGHT -> User recovered or False Alarm.");
        Serial.println("   (Alarm Cancelled)");
    }
    Serial.println("-----------------------------------------");
}