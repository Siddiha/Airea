#include <Arduino.h>
#include <WiFiManager.h>
#include <HTTPClient.h>

// TODO: Replace with your actual Railway Spring Boot URL
const String SPRING_BOOT_URL = "https://airea-production.up.railway.app/api/board/status";

void notifyBackendOnline()
{
    if (WiFi.status() == WL_CONNECTED)
    {
        HTTPClient http;

        Serial.println("Notifying Spring Boot Backend...");
        http.begin(SPRING_BOOT_URL);

        // Standard JSON headers
        http.addHeader("Content-Type", "application/json");
        // http.addHeader("Authorization", "Bearer YOUR_BACKEND_TOKEN"); // Uncomment if your Spring Boot API is secured

        // We can pass the device's new IP address and a unique ID to the backend
        String deviceIP = WiFi.localIP().toString();
        String payload = "{\"deviceId\": \"airea_board_001\", \"status\": \"online\", \"ipAddress\": \"" + deviceIP + "\"}";

        int httpResponseCode = http.POST(payload);

        if (httpResponseCode > 0)
        {
            Serial.print("Backend Notified Successfully! HTTP Code: ");
            Serial.println(httpResponseCode);
        }
        else
        {
            Serial.print("Error communicating with Spring Boot: ");
            Serial.println(http.errorToString(httpResponseCode).c_str());
        }
        http.end();
    }
}

void setup()
{
    Serial.begin(115200);
    Serial.println("Starting Airea Device...");

    WiFiManager wm;
    wm.resetSettings(); // Keep this commented out for production

    bool res = wm.autoConnect("Airea-Setup");

    if (!res)
    {
        Serial.println("Failed to connect and hit timeout.");
        ESP.restart();
    }

    Serial.println("===============================");
    Serial.println("Successfully connected to Wi-Fi!");
    Serial.println("===============================");

    // Trigger the API call to Railway exactly when Wi-Fi connects
    notifyBackendOnline();
}

void loop()
{
    // Main sensor code goes here
}