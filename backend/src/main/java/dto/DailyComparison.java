package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class DailyComparison {
    private int yesterdayCoughs;
    private int change;
    private double percentageChange;
    private String trend;
}
