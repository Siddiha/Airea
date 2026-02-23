package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailySummaryResponse {
    private String date;
    private String deviceId;
    
    // Cough data
    private int totalCoughs;
    private double coughFrequency;
    private double avgConfidence;
    private double avgVolume;
    private int nightCoughs;
    private int dayCoughs;
    private double nightPercentage;
    private int peakHour;
    private List<HourlyDistribution> hourlyDistribution;
    private List<CoughPattern> patterns;
    
    // Vitals data (NEW)
    private VitalsSummary vitalsSummary;
    
    // Combined health assessment
    private int severityScore;
    private String severityLevel;
    private String healthStatus;
    private List<HealthInsight> insights;
    private List<String> recommendations;
    private DailyComparison comparison;
    private boolean hasData;
    private String message;
}
