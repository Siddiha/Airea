package dto;

import java.util.UUID;

public class ConnectedDoctorDto {
    private UUID doctorId;
    private String doctorCode;
    private String doctorName;
    private String specialization;
    private String phoneNumber;
    private String hospital;

    public ConnectedDoctorDto(UUID doctorId, String doctorCode, String doctorName,
                              String specialization, String phoneNumber, String hospital) {
        this.doctorId = doctorId;
        this.doctorCode = doctorCode;
        this.doctorName = doctorName;
        this.specialization = specialization;
        this.phoneNumber = phoneNumber;
        this.hospital = hospital;
    }

    public UUID getDoctorId() { return doctorId; }
    public String getDoctorCode() { return doctorCode; }
    public String getDoctorName() { return doctorName; }
    public String getSpecialization() { return specialization; }
    public String getPhoneNumber() { return phoneNumber; }
    public String getHospital() { return hospital; }
}
