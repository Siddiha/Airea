package model;

import jakarta.persistence.*;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.UUID;

@Entity
@Table(name = "vitals_event")
public class VitalsEvent {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(name = "device_id")
    private String deviceId;

    private float temp;
    private float bpm;
    private float rr;

    @Column(name = "rr_estimated")
    private Boolean rrEstimated;

    @Column(name = "leads_off")
    private boolean leadsOff;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        if (createdAt == null) {
            createdAt = LocalDateTime.now(ZoneId.of("Asia/Colombo"));
        }
        if (rrEstimated == null) {
            rrEstimated = false;
        }
    }

    // Manual Getters and Setters (Bypassing Lombok)
    public UUID getId() {
        return id;
    }

    public void setId(UUID id) {
        this.id = id;
    }

    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public float getTemp() {
        return temp;
    }

    public void setTemp(float temp) {
        this.temp = temp;
    }

    public float getBpm() {
        return bpm;
    }

    public void setBpm(float bpm) {
        this.bpm = bpm;
    }

    public float getRr() {
        return rr;
    }

    public void setRr(float rr) {
        this.rr = rr;
    }

    public boolean isRrEstimated() {
        return Boolean.TRUE.equals(rrEstimated);
    }

    public void setRrEstimated(Boolean rrEstimated) {
        this.rrEstimated = rrEstimated;
    }

    public boolean isLeadsOff() {
        return leadsOff;
    }

    public void setLeadsOff(boolean leadsOff) {
        this.leadsOff = leadsOff;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
