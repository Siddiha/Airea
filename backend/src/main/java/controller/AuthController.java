package controller;

import dto.AuthResponse;
import dto.LoginRequest;
import dto.RegisterRequest;
import jakarta.validation.Valid;
import model.Patient;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import service.AuthService;

import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthService authService;

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
}