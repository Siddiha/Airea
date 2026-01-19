package dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Pattern;

public class AuthRequest {

    @NotBlank(message = "Device ID is required")
    @Pattern(regexp = "^ESP32_[A-Z0-9_]+$", message = "Invalid device ID format. Must start with ESP32_")
    private String deviceId;

    @NotBlank(message = "API key is required")
    private String apiKey;

    public AuthRequest() {
    }

    public AuthRequest(String deviceId, String apiKey) {
        this.deviceId = deviceId;
        this.apiKey = apiKey;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public String getApiKey() {
        return apiKey;
    }

    public void setApiKey(String apiKey) {
        this.apiKey = apiKey;
    }
}
