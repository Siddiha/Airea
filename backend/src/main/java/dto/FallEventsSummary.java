package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class FallEventsSummary {
    private boolean hasFallData;
    private int totalFalls;
    private int emergencyFalls;
    private int nonEmergencyFalls;
    private double maxGForce;
    private double avgGForce;
    private String latestFallTime; // HH:mm format
    private String worstEmergencyLevel; // CRITICAL, WARNING, MONITORING, NORMAL
    private String fallRiskLevel; // NONE, LOW, MODERATE, HIGH, CRITICAL
    private String fallRiskMessage;
    private List<FallEventDetail> fallEvents;
}
