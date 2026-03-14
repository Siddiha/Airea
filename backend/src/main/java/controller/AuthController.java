package controller;

import dto.AuthResponse;
import dto.DoctorAuthResponse;
import dto.DoctorRegisterRequest;
import dto.LoginRequest;
import dto.RegisterRequest;
import jakarta.validation.Valid;
import model.Doctor;
import model.Patient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import service.AuthService;

import service.PasswordResetService;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

    @Autowired
    private PasswordResetService passwordResetService;

    @PostMapping("/register")
    public ResponseEntity<?> register(@Valid @RequestBody RegisterRequest request) {
        try {
            AuthResponse response = authService.register(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody LoginRequest request) {
        try {
            AuthResponse response = authService.login(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @GetMapping("/profile")
    public ResponseEntity<?> getProfile(@RequestHeader("Authorization") String authHeader) {
        try {
            String email = extractEmailFromToken(authHeader);
            Patient patient = authService.getPatientByEmail(email);

            return ResponseEntity.ok(Map.of(
                    "id", patient.getId(),
                    "email", patient.getEmail(),
                    "fullName", patient.getFullName() != null ? patient.getFullName() : "",
                    "dateOfBirth", patient.getDateOfBirth() != null ? patient.getDateOfBirth().toString() : "",
                    "gender", patient.getGender() != null ? patient.getGender() : "",
                    "address", patient.getAddress() != null ? patient.getAddress() : "",
                    "phoneNumber", patient.getPhoneNumber() != null ? patient.getPhoneNumber() : "",
                    "allergies", patient.getAllergies() != null ? patient.getAllergies() : "",
                    "emergencyContact", patient.getEmergencyContact() != null ? patient.getEmergencyContact() : "",
                    "deviceId", patient.getDeviceId() != null ? patient.getDeviceId() : ""
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "error", true,
                    "message", "Invalid or expired token"
            ));
        }
    }

    @PutMapping("/profile")
    public ResponseEntity<?> updateProfile(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody RegisterRequest request) {
        try {
            String email = extractEmailFromToken(authHeader);
            Patient patient = authService.updatePatient(email, request);

            return ResponseEntity.ok(Map.of(
                    "message", "Profile updated successfully",
                    "id", patient.getId(),
                    "email", patient.getEmail(),
                    "fullName", patient.getFullName() != null ? patient.getFullName() : "",
                    "dateOfBirth", patient.getDateOfBirth() != null ? patient.getDateOfBirth().toString() : "",
                    "gender", patient.getGender() != null ? patient.getGender() : "",
                    "address", patient.getAddress() != null ? patient.getAddress() : ""
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @PostMapping("/link-device")
    public ResponseEntity<?> linkDevice(
            @RequestHeader("Authorization") String authHeader,
            @RequestBody Map<String, String> request) {
        try {
            String email = extractEmailFromToken(authHeader);
            String deviceId = request.get("deviceId");

            if (deviceId == null || deviceId.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", true,
                        "message", "Device ID is required"
                ));
            }

            authService.linkDevice(email, deviceId);

            return ResponseEntity.ok(Map.of(
                    "message", "Device linked successfully",
                    "deviceId", deviceId
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    // ========== Doctor Authentication Endpoints ==========

    @PostMapping("/doctor/register")
    public ResponseEntity<?> doctorRegister(@Valid @RequestBody DoctorRegisterRequest request) {
        try {
            DoctorAuthResponse response = authService.doctorRegister(request);
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @PostMapping("/doctor/login")
    public ResponseEntity<?> doctorLogin(@Valid @RequestBody LoginRequest request) {
        try {
            DoctorAuthResponse response = authService.doctorLogin(request);
            return ResponseEntity.ok(response);
        } catch (RuntimeException e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @GetMapping("/doctor/profile")
    public ResponseEntity<?> getDoctorProfile(@RequestHeader("Authorization") String authHeader) {
        try {
            String email = extractEmailFromToken(authHeader);
            Doctor doctor = authService.getDoctorByEmail(email);

            return ResponseEntity.ok(Map.of(
                    "id", doctor.getId(),
                    "email", doctor.getEmail(),
                    "fullName", doctor.getFullName() != null ? doctor.getFullName() : "",
                    "specialization", doctor.getSpecialization() != null ? doctor.getSpecialization() : "",
                    "phoneNumber", doctor.getPhoneNumber() != null ? doctor.getPhoneNumber() : "",
                    "hospital", doctor.getHospital() != null ? doctor.getHospital() : ""
            ));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(Map.of(
                    "error", true,
                    "message", "Invalid or expired token"
            ));
        }
    }

    // ========== Password Reset Endpoints ==========

    @PostMapping("/forgot-password")
    public ResponseEntity<?> forgotPassword(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String userType = request.get("userType");

            if (email == null || email.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", true,
                        "message", "Email is required"
                ));
            }
            if (userType == null || userType.isEmpty()) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", true,
                        "message", "User type is required"
                ));
            }

            passwordResetService.requestReset(email, userType);
            return ResponseEntity.ok(Map.of(
                    "message", "Verification code sent to your email"
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<?> verifyOtp(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String otp = request.get("otp");
            String userType = request.get("userType");

            boolean valid = passwordResetService.verifyOtp(email, otp, userType);

            if (valid) {
                return ResponseEntity.ok(Map.of(
                        "message", "OTP verified successfully",
                        "valid", true
                ));
            } else {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", true,
                        "message", "Invalid or expired verification code",
                        "valid", false
                ));
            }
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @PostMapping("/reset-password")
    public ResponseEntity<?> resetPassword(@RequestBody Map<String, String> request) {
        try {
            String email = request.get("email");
            String otp = request.get("otp");
            String newPassword = request.get("newPassword");
            String userType = request.get("userType");

            if (newPassword == null || newPassword.length() < 6) {
                return ResponseEntity.badRequest().body(Map.of(
                        "error", true,
                        "message", "Password must be at least 6 characters"
                ));
            }

            passwordResetService.resetPassword(email, otp, newPassword, userType);
            return ResponseEntity.ok(Map.of(
                    "message", "Password reset successfully"
            ));
        } catch (RuntimeException e) {
            return ResponseEntity.badRequest().body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @GetMapping("/health")
    public ResponseEntity<?> healthCheck() {
        return ResponseEntity.ok(Map.of(
                "status", "OK",
                "service", "Authentication Service",
                "timestamp", System.currentTimeMillis()
        ));
    }

    private String extractEmailFromToken(String authHeader) {
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            throw new RuntimeException("Invalid authorization header");
        }
        // For now, we'll parse the JWT token directly
        // In a more complete implementation, this would use JwtUtil
        String token = authHeader.substring(7);
        // Extract email from token - this should be done via JwtUtil injection
        // For simplicity, we'll use a workaround here
        return extractEmailFromJwt(token);
    }

    @Autowired
    private config.JwtUtil jwtUtil;

    private String extractEmailFromJwt(String token) {
        return jwtUtil.extractEmail(token);
    }

    @GetMapping("/patient/code")
    public ResponseEntity<?> getPatientCode(@RequestParam String email) {
        try {
            Patient patient = authService.getPatientByEmail(email);
            String code = patient.getPatientCode();
            if (code == null || code.isEmpty()) {
                code = "P" + java.util.UUID.randomUUID().toString().substring(0, 6).toUpperCase();
                patient.setPatientCode(code);
                authService.savePatient(patient);
            }
            return ResponseEntity.ok(Map.of("code", code));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }

    @GetMapping("/doctor/code")
    public ResponseEntity<?> getDoctorCode(@RequestParam String email) {
        try {
            Doctor doctor = authService.getDoctorByEmail(email);
            String code = doctor.getDoctorCode();
            if (code == null || code.isEmpty()) {
                code = "D" + java.util.UUID.randomUUID().toString().substring(0, 6).toUpperCase();
                doctor.setDoctorCode(code);
                authService.saveDoctor(doctor);
            }
            return ResponseEntity.ok(Map.of("code", code));
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(Map.of(
                    "error", true,
                    "message", e.getMessage()
            ));
        }
    }
}