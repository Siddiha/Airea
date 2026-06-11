package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeeklyFallEventsSummary {
    private boolean hasFallData;
    private int totalFalls;
    private int totalEmergencyFalls;
    private double maxGForce;
    private double avgGForce;
    private int daysWithFalls;
    private double avgFallsPerDay;
    private String worstEmergencyLevel; // CRITICAL, WARNING, MONITORING, NORMAL
    private String fallRiskLevel; // NONE, LOW, MODERATE, HIGH, CRITICAL
    private String fallRiskMessage;
    private List<Integer> dailyFallCounts;        // 7 values (Mon-Sun)
    private List<Integer> dailyEmergencyCounts;   // 7 values (Mon-Sun)
}
