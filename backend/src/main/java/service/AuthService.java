package service;

import config.JwtUtil;
import dto.AuthResponse;
import dto.DoctorAuthResponse;
import dto.LoginRequest;
import dto.RegisterRequest;
import dto.DoctorRegisterRequest;
import model.Doctor;
import model.Patient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import repository.DoctorRepository;
import repository.PatientRepository;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;

@Service
public class AuthService {

    @Autowired
    private PatientRepository patientRepository;

    @Autowired
    private DoctorRepository doctorRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    public AuthResponse register(RegisterRequest request) {
        // Check if email already exists
        if (patientRepository.existsByEmail(request.getEmail())) {
            // Update full_name if a non-empty name is provided and the current value is null/empty
            if (request.getFullName() != null && !request.getFullName().isEmpty()) {
                patientRepository.findByEmail(request.getEmail()).ifPresent(existing -> {
                    if (existing.getFullName() == null || existing.getFullName().isEmpty()) {
                        existing.setFullName(request.getFullName());
                        patientRepository.save(existing);
                    }
                });
            }
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
        // Ensure the device is not already linked to a DIFFERENT patient
        patientRepository.findByDeviceId(deviceId).ifPresent(existing -> {
            if (!existing.getEmail().equalsIgnoreCase(email)) {
                throw new RuntimeException("Device is already linked to another patient");
            }
        });

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

    // ========== Doctor Authentication ==========

    public DoctorAuthResponse doctorRegister(DoctorRegisterRequest request) {
        // Check if email already exists
        if (doctorRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email already registered");
        }

        // Create new doctor
        Doctor doctor = new Doctor();
        doctor.setEmail(request.getEmail());
        doctor.setPassword(passwordEncoder.encode(request.getPassword()));
        doctor.setFullName(request.getFullName());
        doctor.setSpecialization(request.getSpecialization());
        doctor.setPhoneNumber(request.getPhoneNumber());
        doctor.setHospital(request.getHospital());

        // Save doctor
        Doctor savedDoctor = doctorRepository.save(doctor);

        // Generate JWT token
        String token = jwtUtil.generateToken(savedDoctor.getEmail());

        return buildDoctorAuthResponse(savedDoctor, token);
    }

    public DoctorAuthResponse doctorLogin(LoginRequest request) {
        // Find doctor by email
        Doctor doctor = doctorRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Invalid email or password"));

        // Verify password
        if (!passwordEncoder.matches(request.getPassword(), doctor.getPassword())) {
            throw new RuntimeException("Invalid email or password");
        }

        // Check if account is active
        if (!doctor.getIsActive()) {
            throw new RuntimeException("Account is deactivated");
        }

        // Generate JWT token
        String token = jwtUtil.generateToken(doctor.getEmail());

        return buildDoctorAuthResponse(doctor, token);
    }

    public Doctor getDoctorByEmail(String email) {
        return doctorRepository.findByEmail(email)
                .orElseThrow(() -> new RuntimeException("Doctor not found"));
    }

    /**
     * Find doctor by email, or create a new record if not found.
     * This handles doctors who registered via Supabase Auth but don't have
     * a row in the doctors table yet.
     */
    public Doctor ensureDoctorExists(String email) {
        return doctorRepository.findByEmail(email).orElseGet(() -> {
            Doctor doctor = new Doctor();
            doctor.setEmail(email);
            doctor.setPassword(passwordEncoder.encode(java.util.UUID.randomUUID().toString()));
            return doctorRepository.save(doctor);
        });
    }

    /**
     * Find patient by email, or create a new record if not found.
     * This handles patients who registered via Supabase Auth but don't have
     * a row in the patients table yet.
     */
    public Patient ensurePatientExists(String email) {
        return patientRepository.findByEmail(email).orElseGet(() -> {
            Patient patient = new Patient();
            patient.setEmail(email);
            patient.setPassword(passwordEncoder.encode(java.util.UUID.randomUUID().toString()));
            return patientRepository.save(patient);
        });
    }

    public Patient savePatient(Patient patient) {
        return patientRepository.save(patient);
    }

    public Doctor saveDoctor(Doctor doctor) {
        return doctorRepository.save(doctor);
    }

    private DoctorAuthResponse buildDoctorAuthResponse(Doctor doctor, String token) {
        DoctorAuthResponse.DoctorInfo doctorInfo = DoctorAuthResponse.DoctorInfo.builder()
                .id(doctor.getId())
                .email(doctor.getEmail())
                .fullName(doctor.getFullName())
                .specialization(doctor.getSpecialization())
                .phoneNumber(doctor.getPhoneNumber())
                .hospital(doctor.getHospital())
                .build();

        return DoctorAuthResponse.builder()
                .token(token)
                .tokenType("Bearer")
                .expiresIn(jwtUtil.getExpirationInSeconds())
                .doctor(doctorInfo)
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