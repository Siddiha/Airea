package model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.Instant;
import java.util.UUID;

@Entity
@Table(name = "cough_events")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class CoughEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String deviceId;

    // @Column(nullable = false)
    // private String coughType; // "dry", "wet", "unknown"
    @Column(nullable = false)
    private Float confidence; // 0.0 to 1.0

    private Float rawScore; // Raw ML model score

    @Column(nullable = false)
    private Instant timestamp;

    private Float audioVolume;

    @PrePersist
    protected void onCreate() {
        if (timestamp == null) {
            timestamp = Instant.now();
        }
    }
}
