package dto;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import model.CoughEvent;
import java.time.Instant;
import java.util.UUID;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoughEventResponse {
    
    private UUID id;
    private String deviceId;
    private String coughType;
    private Float confidence;
    private Float rawScore;
    private Instant timestamp;
    private Float audioVolume;
    private Instant createdAt;
    
    public static CoughEventResponse fromEntity(CoughEvent event) {
        return new CoughEventResponse(
            event.getId(),
            event.getDeviceId(),
            event.getCoughType(),
            event.getConfidence(),
            event.getRawScore(),
            event.getTimestamp(),
            event.getAudioVolume(),
            event.getCreatedAt()
        );
    }
}