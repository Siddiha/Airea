package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class WeekOverWeekComparison {
    private int previousWeekTotal;
    private int currentWeekTotal;
    private int change;
    private double changePercentage;
    private String trend; // "IMPROVING", "WORSENING", "STABLE"
    private String trendMessage;
}
