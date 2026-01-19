package dto;

public class AuthResponse {

    private String token;
    private String deviceId;
    private String tokenType = "Bearer";
    private long expiresIn;

    public AuthResponse() {
    }

    public AuthResponse(String token, String deviceId, long expiresIn) {
        this.token = token;
        this.deviceId = deviceId;
        this.expiresIn = expiresIn;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public String getTokenType() {
        return tokenType;
    }

    public void setTokenType(String tokenType) {
        this.tokenType = tokenType;
    }

    public long getExpiresIn() {
        return expiresIn;
    }

    public void setExpiresIn(long expiresIn) {
        this.expiresIn = expiresIn;
    }
}
