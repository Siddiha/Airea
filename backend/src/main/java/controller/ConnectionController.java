package controller;

import dto.ConnectionRequestDto;
import model.Doctor;
import model.Patient;
import model.DoctorPatientLink;
import repository.DoctorRepository;
import repository.PatientRepository;
import repository.DoctorPatientLinkRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

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
            // Translate Doctor Code to UUID
            Doctor doctor = doctorRepository.findByDoctorCode(request.getDoctorCode())
                .orElseThrow(() -> new RuntimeException("Error: Doctor code not found."));

            // Translate Patient Code to UUID
            Patient patient = patientRepository.findByPatientCode(request.getPatientCode())
                .orElseThrow(() -> new RuntimeException("Error: Patient code not found."));

            // Check existing connection using UUIDs
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
}