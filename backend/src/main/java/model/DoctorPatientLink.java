package model;

import jakarta.persistence.*;
import java.util.UUID;

@Entity
@Table(name = "doctor_patient_links")
public class DoctorPatientLink {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "doctor_id")
    private UUID doctorId;

    @Column(name = "patient_id")
    private UUID patientId;

    public void setDoctorId(UUID doctorId) { this.doctorId = doctorId; }
    public void setPatientId(UUID patientId) { this.patientId = patientId; }
}