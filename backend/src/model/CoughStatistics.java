package model;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoughStatistics {
    
    private Long totalCoughs;
    private Long dryCoughs;
    private Long wetCoughs;
    private Long unknownCoughs;
    private Double averageConfidence;
    private Double coughsPerHour;
    private String mostCommonType;
    
    // Time period
    private String period; // "hour", "day", "week"
}