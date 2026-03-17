package controller;

import dto.ConnectionRequestDto;
import dto.ConnectedPatientDto;
import dto.ConnectedDoctorDto;
import model.Doctor;
import model.Patient;
import model.DoctorPatientLink;
import repository.DoctorRepository;
import repository.PatientRepository;
import repository.DoctorPatientLinkRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/connections")
public class ConnectionController {

    private final DoctorPatientLinkRepository linkRepository;
    private final DoctorRepository doctorRepository;
    private final PatientRepository patientRepository;

    public ConnectionController(
            DoctorPatientLinkRepository linkRepository, 
            DoctorRepository doctorRepository, 
            PatientRepository patientRepository) {
        this.linkRepository = linkRepository;
        this.doctorRepository = doctorRepository;
        this.patientRepository = patientRepository;
    }

    @PostMapping("/add-by-code")
    public ResponseEntity<String> connectByCode(@RequestBody ConnectionRequestDto request) {
        try {
            Doctor doctor = doctorRepository.findByDoctorCode(request.getDoctorCode())
                .orElseThrow(() -> new RuntimeException("Error: Doctor code not found."));

            Patient patient = patientRepository.findByPatientCode(request.getPatientCode())
                .orElseThrow(() -> new RuntimeException("Error: Patient code not found."));

            if (linkRepository.existsByDoctorIdAndPatientId(doctor.getId(), patient.getId())) {
                return ResponseEntity.badRequest().body("Error: This doctor and patient are already connected.");
            }

            DoctorPatientLink newLink = new DoctorPatientLink();
            newLink.setDoctorId(doctor.getId());
            newLink.setPatientId(patient.getId());

            linkRepository.save(newLink);

            return ResponseEntity.ok("Success: Connected " + request.getDoctorCode() + " and " + request.getPatientCode());

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @GetMapping("/doctor/{doctorCode}/patients")
    public ResponseEntity<?> getConnectedPatients(@PathVariable String doctorCode) {
        try {
            Doctor doctor = doctorRepository.findByDoctorCode(doctorCode)
                .orElseThrow(() -> new RuntimeException("Doctor code not found."));

            List<DoctorPatientLink> links = linkRepository.findByDoctorId(doctor.getId());

            List<ConnectedPatientDto> patients = new ArrayList<>();
            for (DoctorPatientLink link : links) {
                Optional<Patient> patientOpt = patientRepository.findById(link.getPatientId());
                patientOpt.ifPresent(patient -> patients.add(new ConnectedPatientDto(
                    patient.getId(),
                    patient.getPatientCode(),
                    patient.getFullName() != null ? patient.getFullName() : "Unknown",
                    patient.getDeviceId() != null ? patient.getDeviceId() : ""
                )));
            }

            return ResponseEntity.ok(patients);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @GetMapping("/patient/{patientCode}/doctors")
    public ResponseEntity<?> getConnectedDoctors(@PathVariable String patientCode) {
        try {
            Patient patient = patientRepository.findByPatientCode(patientCode)
                .orElseThrow(() -> new RuntimeException("Patient code not found."));

            List<DoctorPatientLink> links = linkRepository.findByPatientId(patient.getId());

            List<ConnectedDoctorDto> doctors = new ArrayList<>();
            for (DoctorPatientLink link : links) {
                Optional<Doctor> doctorOpt = doctorRepository.findById(link.getDoctorId());
                doctorOpt.ifPresent(doctor -> doctors.add(new ConnectedDoctorDto(
                    doctor.getId(),
                    doctor.getDoctorCode(),
                    doctor.getFullName() != null ? doctor.getFullName() : "Unknown",
                    doctor.getSpecialization() != null ? doctor.getSpecialization() : "",
                    doctor.getPhoneNumber() != null ? doctor.getPhoneNumber() : "",
                    doctor.getHospital() != null ? doctor.getHospital() : ""
                )));
            }

            return ResponseEntity.ok(doctors);

        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }

    @DeleteMapping("/disconnect")
    public ResponseEntity<String> disconnectPatient(
            @RequestParam String doctorCode,
            @RequestParam String patientId) {
        try {
            Doctor doctor = doctorRepository.findByDoctorCode(doctorCode)
                .orElseThrow(() -> new RuntimeException("Doctor code not found."));

            java.util.UUID patientUuid = java.util.UUID.fromString(patientId);

            Optional<DoctorPatientLink> link = linkRepository.findByDoctorIdAndPatientId(
                doctor.getId(), patientUuid);

            if (link.isEmpty()) {
                return ResponseEntity.badRequest().body("Error: Connection not found.");
            }

            linkRepository.delete(link.get());
            return ResponseEntity.ok("Success: Patient disconnected.");

        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body("Error: Invalid patient ID format.");
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(e.getMessage());
        }
    }
}