package service;

import config.JwtUtil;
import dto.AuthResponse;
import dto.LoginRequest;
import dto.RegisterRequest;
import model.Patient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import repository.PatientRepository;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Service
public class AuthService {

    @Autowired
    private PatientRepository patientRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    public AuthResponse register(RegisterRequest request) {
        // Check if email already exists
        if (patientRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        // Create new patient
        Patient patient = new Patient();
        patient.setEmail(request.getEmail());
        patient.setPassword(passwordEncoder.encode(request.getPassword()));
        patient.setFullName(request.getFullName());
        patient.setGender(request.getGender());
        patient.setAddress(request.getAddress());
        patient.setPhoneNumber(request.getPhoneNumber());
        patient.setAllergies(request.getAllergies());
        patient.setEmergencyContact(request.getEmergencyContact());

        // Parse date of birth if provided
        if (request.getDateOfBirth() != null && !request.getDateOfBirth().isEmpty()) {
            try {
                // Try multiple date formats
                LocalDate dob = parseDate(request.getDateOfBirth());
                patient.setDateOfBirth(dob);
            } catch (Exception e) {
                // If parsing fails, leave it null
                System.err.println("Failed to parse date of birth: " + request.getDateOfBirth());
            }
        }

        // Save patient
        Patient savedPatient = patientRepository.save(patient);

        // Generate JWT token
        String token = jwtUtil.generateToken(savedPatient.getEmail());

        return buildAuthResponse(savedPatient, token);
    }

    public AuthResponse login(LoginRequest request) {
        // Find patient by email
        Patient patient = patientRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        // Verify password
        if (!passwordEncoder.matches(request.getPassword(), patient.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }

        // Check if account is active
        if (!patient.getIsActive()) {
            throw new RuntimeException("Account is deactivated");
        }

        // Generate JWT token
        String token = jwtUtil.generateToken(patient.getEmail());

        return buildAuthResponse(patient, token);
    }

    public Patient getPatientByEmail(String email) {
        return patientRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Patient not found"));
    }

    public Patient updatePatient(String email, RegisterRequest request) {
        Patient patient = getPatientByEmail(email);

        if (request.getFullName() != null) {
            patient.setFullName(request.getFullName());
        }
        if (request.getGender() != null) {
            patient.setGender(request.getGender());
        }
        if (request.getAddress() != null) {
            patient.setAddress(request.getAddress());
        }
        if (request.getPhoneNumber() != null) {
            patient.setPhoneNumber(request.getPhoneNumber());
        }
        if (request.getAllergies() != null) {
            patient.setAllergies(request.getAllergies());
        }
        if (request.getEmergencyContact() != null) {
            patient.setEmergencyContact(request.getEmergencyContact());
        }
        if (request.getDateOfBirth() != null && !request.getDateOfBirth().isEmpty()) {
            try {
                LocalDate dob = parseDate(request.getDateOfBirth());
                patient.setDateOfBirth(dob);
            } catch (Exception e) {
                // Ignore parsing errors
            }
        }

        return patientRepository.save(patient);
    }

    public void linkDevice(String email, String deviceId) {
        Patient patient = getPatientByEmail(email);
        patient.setDeviceId(deviceId);
        patientRepository.save(patient);
    }

    private AuthResponse buildAuthResponse(Patient patient, String token) {
        AuthResponse.PatientInfo patientInfo = AuthResponse.PatientInfo.builder()
                .id(patient.getId())
                .email(patient.getEmail())
                .fullName(patient.getFullName())
                .dateOfBirth(patient.getDateOfBirth())
                .gender(patient.getGender())
                .address(patient.getAddress())
                .phoneNumber(patient.getPhoneNumber())
                .allergies(patient.getAllergies())
                .emergencyContact(patient.getEmergencyContact())
                .deviceId(patient.getDeviceId())
                .build();

        return AuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(jwtUtil.getExpirationInSeconds())
                .patient(patientInfo)
                .build();
    }

    private LocalDate parseDate(String dateStr) {
        // Try DD/MM/YYYY format first
        try {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("d/M/yyyy");
            return LocalDate.parse(dateStr, formatter);
        } catch (Exception e) {
            // Try ISO format
            return LocalDate.parse(dateStr);
        }
    }
}