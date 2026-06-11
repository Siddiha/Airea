⚡ Part 2: Flashing the Device (ESP32)

1. Hardware RequiredESP32

   - Development Board (Doit DevKit V1 or similar).
   - INMP441 I2S Omnidirectional Microphone.
   - USB Cable.

2. Wiring Connections

Connect the INMP441 to the ESP32 as follows:

INMP441 - PinESP32 - Pin Note

SCK - GPIO 14 - Serial Clock
WS - GPIO 15 - Word Select
SD - GPIO 32 - Serial Data
L/R - GND - Set channel to Left
VDD - 3.3V - Do not use 5V
GND - GND - Ground

3. Software Setup

   1. Install VS Code.
   2. Install the PlatformIO extension inside VS Code.
   3. Open the Firmware folder in PlatformIO.

4. Import the ModelCopy the model.h file (generated in Part 1) and paste it into the Firmware/src/ folder.
   Note: This file contains the trained neural network weights.

5. Upload
   1. Connect your ESP32 via USB.
   2. Click the Arrow Icon (→) in the bottom PlatformIO toolbar to Upload.
   3. Open the Serial Monitor (Plug Icon) to see the output.

🛠️ Usage & Testing

1. Power On: The device will initialize and print ✅ System Ready.
2. Trigger: Make a sound louder than the ambient noise.
3. Detection:
   _ Cough Detected: The Serial Monitor will show ✅ Confirmed Cough (Confidence > 85%).
   _ Noise Ignored: It will show ❌ Ignored for clapping, talking, or static.

👥Authors
Team Airea - University Software Project (2025)
