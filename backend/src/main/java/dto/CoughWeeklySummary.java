package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoughWeeklySummary {
    private int totalCoughs;
    private double avgCoughsPerDay;
    private int totalDayCoughs;
    private int totalNightCoughs;
    private double nightCoughPercentage;
    private String severityLevel;
    private int peakDay; // 0 = Monday, 6 = Sunday (day index with most coughs)
    private String peakDayName; // "Monday", "Tuesday", etc.
    private int peakDayCoughs;
    private int lowestDay;
    private String lowestDayName;
    private int lowestDayCoughs;
}
