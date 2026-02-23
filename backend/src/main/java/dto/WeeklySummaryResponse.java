package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.util.List;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeeklySummaryResponse {
    private String weekStart;
    private String weekEnd;
    private String deviceId;
    private int daysWithData;
    
    // Cough Summary
    private CoughWeeklySummary coughSummary;
    
    // Week over week comparison
    private WeekOverWeekComparison weekOverWeekComparison;
    
    // Daily breakdown (7 days)
    private List<DailyBreakdown> dailyBreakdown;
    
    // Vitals Summary
    private WeeklyVitalsSummary vitalsSummary;
    
    // Analysis
    private List<String> weeklyPatterns;
    private List<String> weeklyInsights;
    private List<String> recommendations;
    
    // Overall assessment
    private int severityScore;
    private String severityLevel;
    private String healthStatus;
    private boolean hasData;
    private String message;
}
