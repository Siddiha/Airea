package dto;

public class ConnectionRequestDto {
    private String doctorCode;
    private String patientCode;

    // Manual Getters 
    public String getDoctorCode() { return doctorCode; }
    public String getPatientCode() { return patientCode; }

    // Manual Setters
    public void setDoctorCode(String doctorCode) { this.doctorCode = doctorCode; }
    public void setPatientCode(String patientCode) { this.patientCode = patientCode; }
}