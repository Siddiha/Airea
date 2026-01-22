package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoughEventRequest {

    private String deviceId;
    // private String coughType;      // "dry", "wet", "unknown"
    private Float confidence;       // 0.0 to 1.0
    private Float rawScore;         // Raw ML score
    private Long timestamp;         // Unix timestamp (milliseconds)
    private Float audioVolume;      // Optional

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    // public String getCoughType() {
    //     return coughType;
    // }
    // public void setCoughType(String coughType) {
    //     this.coughType = coughType;
    // }
    public Float getConfidence() {
        return confidence;
    }

    public void setConfidence(Float confidence) {
        this.confidence = confidence;
    }

    public Float getRawScore() {
        return rawScore;
    }

    public void setRawScore(Float rawScore) {
        this.rawScore = rawScore;
    }

    public Long getTimestamp() {
        return timestamp;
    }

    public void setTimestamp(Long timestamp) {
        this.timestamp = timestamp;
    }

    public Float getAudioVolume() {
        return audioVolume;
    }

    public void setAudioVolume(Float audioVolume) {
        this.audioVolume = audioVolume;
    }
}
