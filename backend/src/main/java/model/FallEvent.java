package model;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.UUID;

@Entity
@Table(name = "fall_events")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FallEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "device_id", nullable = false)
    private String deviceId;

    @Column(name = "confidence", nullable = false)
    private Float confidence;

    // Vitals at time of fall
    private Float temp;
    private Float bpm;
    private Float rr; // Respiratory rate

    @Column(name = "leads_off")
    private Boolean leadsOff;

    // Location data
    private Double latitude;
    private Double longitude;

    @Column(name = "location_address", columnDefinition = "TEXT")
    private String locationAddress;

    // Emergency status
    @Column(name = "is_emergency")
    private Boolean isEmergency = false;

    @Column(name = "emergency_reason", columnDefinition = "TEXT")
    private String emergencyReason;

    @Column(name = "emergency_level")
    private String emergencyLevel; // CRITICAL, WARNING, MONITORING, NORMAL

    // Alert tracking
    @Column(name = "alert_sent")
    private Boolean alertSent = false;

    @Column(name = "alert_sent_at")
    private LocalDateTime alertSentAt;

    @Column(name = "alert_sent_to")
    private String alertSentTo;

    @Column(nullable = false)
    private LocalDateTime timestamp;

    @PrePersist
    protected void onCreate() {
        if (timestamp == null) {
            timestamp = LocalDateTime.now(ZoneId.of("Asia/Colombo"));
        }
    }

    // Explicit getters for boolean fields (Lombok generates isX() which might cause issues)
    public Boolean getIsEmergency() {
        return isEmergency;
    }

    public void setIsEmergency(Boolean isEmergency) {
        this.isEmergency = isEmergency;
    }

    public Boolean getAlertSent() {
        return alertSent;
    }
}
