package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoughEventRequest {
    
    private String deviceId;
    private String coughType;      // "dry", "wet", "unknown"
    private Float confidence;       // 0.0 to 1.0
    private Float rawScore;         // Raw ML score
    private Long timestamp;         // Unix timestamp (milliseconds)
    private Float audioVolume;      // Optional
}