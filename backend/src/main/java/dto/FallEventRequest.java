package dto;

import com.fasterxml.jackson.annotation.JsonProperty;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FallEventRequest {

    private String deviceId;
    
    @JsonProperty("gForce")
    private Float gForce;

    // Vitals at time of fall
    private Float temp;
    private Float bpm;
    private Float rr;
    private Boolean leadsOff;

    // Location (from phone GPS or fixed location)
    private Double latitude;
    private Double longitude;

    // Timestamp (Unix milliseconds)
    private Long timestamp;

    // Explicit getters for compatibility
    public String getDeviceId() {
        return deviceId;
    }

    @JsonProperty("gForce")
    public Float getGForce() {
        return gForce;
    }

    public Float getTemp() {
        return temp;
    }

    public Float getBpm() {
        return bpm;
    }

    public Float getRr() {
        return rr;
    }

    public Boolean getLeadsOff() {
        return leadsOff != null ? leadsOff : false;
    }

    public Double getLatitude() {
        return latitude;
    }

    public Double getLongitude() {
        return longitude;
    }

    public Long getTimestamp() {
        return timestamp;
    }
}
