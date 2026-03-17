package dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class EmergencyAlertResponse {

    private boolean fallDetected;
    private boolean isEmergency;
    private String emergencyLevel; // CRITICAL, WARNING, MONITORING, NORMAL
    private List<String> abnormalVitals;
    private String emergencyReason;
    private boolean alertSent;
    private String alertSentTo;
    private String message;
    private String fallEventId;

    // Vitals summary
    private Float temp;
    private Float bpm;
    private Float rr;
    private Float confidence;
    private String alertType;

    // Location
    private String location;
}
