package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeeklyVitalStats {
    private double weeklyAverage;
    private double weeklyMin;
    private double weeklyMax;
    private String status; // NORMAL, LOW, HIGH, CRITICAL
    private String statusMessage;
    private int totalReadings;
    private int anomalyCount;
    private String trend; // "IMPROVING", "WORSENING", "STABLE"
}
