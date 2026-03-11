package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FallEventDetail {
    private String time; // HH:mm format
    private double gForce;
    private boolean isEmergency;
    private String emergencyLevel; // CRITICAL, WARNING, MONITORING, NORMAL
    private String emergencyReason;
    private Float bpm;
    private Float temp;
    private Float rr;
}
