package dto;

import java.util.UUID;

public class ConnectedPatientDto {
    private UUID patientId;
    private String patientCode;
    private String patientName;
    private String deviceId;

    public ConnectedPatientDto(UUID patientId, String patientCode, String patientName, String deviceId) {
        this.patientId = patientId;
        this.patientCode = patientCode;
        this.patientName = patientName;
        this.deviceId = deviceId;
    }

    public UUID getPatientId() { return patientId; }
    public String getPatientCode() { return patientCode; }
    public String getPatientName() { return patientName; }
    public String getDeviceId() { return deviceId; }
}
