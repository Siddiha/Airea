package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyBreakdown {
    private String date;
    private String dayName; // "Monday", "Tuesday", etc.
    private int dayIndex; // 0 = Monday, 6 = Sunday
    private int totalCoughs;
    private int dayCoughs;
    private int nightCoughs;
    private double nightPercentage;
    private boolean hasData;
    
    // Daily vitals averages
    private Double avgHeartRate;
    private Double avgTemperature;
    private Double avgRespiratoryRate;
    
    // Daily status
    private String severityLevel;
}
