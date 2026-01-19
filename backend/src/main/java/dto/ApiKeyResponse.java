package dto;

public class ApiKeyResponse {

    private String deviceId;
    private String apiKey;
    private String message;

    public ApiKeyResponse() {
    }

    public ApiKeyResponse(String deviceId, String apiKey, String message) {
        this.deviceId = deviceId;
        this.apiKey = apiKey;
        this.message = message;
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

    public String getMessage() {
        return message;
    }

    public void setMessage(String message) {
        this.message = message;
    }
}
