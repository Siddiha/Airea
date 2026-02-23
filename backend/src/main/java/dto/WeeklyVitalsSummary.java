package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeeklyVitalsSummary {
    private boolean hasVitalsData;
    private int totalReadings;
    private int daysWithVitalsData;
    private String vitalsMessage;
    
    // Heart Rate Weekly Summary
    private WeeklyVitalStats heartRate;
    
    // Temperature Weekly Summary
    private WeeklyVitalStats temperature;
    
    // Respiratory Rate Weekly Summary
    private WeeklyVitalStats respiratoryRate;
    
    // Overall vitals status
    private int vitalsSeverityScore;
    private String vitalsStatus;
    
    // Daily averages for chart (7 values, null if no data for that day)
    private List<Double> dailyHeartRateAverages;
    private List<Double> dailyTemperatureAverages;
    private List<Double> dailyRespiratoryRateAverages;
    
    // Anomalies detected across the week
    private List<VitalsAnomaly> weeklyAnomalies;
}
