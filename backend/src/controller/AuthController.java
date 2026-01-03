package controller;

import dto.ApiKeyResponse;
import dto.AuthRequest;
import dto.AuthResponse;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import service.AuthService;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthService authService;

    /**
     * Generate API key for a device
     * POST /api/auth/generate-key/{deviceId}
     */
    @PostMapping("/generate-key/{deviceId}")
    public ResponseEntity<?> generateApiKey(@PathVariable String deviceId) {
        try {
            ApiKeyResponse response = authService.generateApiKey(deviceId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * Authenticate device and get JWT token
     * POST /api/auth/login
     */
    @PostMapping("/login")
    public ResponseEntity<?> login(@Valid @RequestBody AuthRequest authRequest) {
        try {
            AuthResponse response = authService.authenticate(authRequest);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).body(error);
        }
    }

    /**
     * Revoke API key for a device
     * DELETE /api/auth/revoke/{deviceId}
     */
    @DeleteMapping("/revoke/{deviceId}")
    public ResponseEntity<?> revokeApiKey(@PathVariable String deviceId) {
        try {
            authService.revokeApiKey(deviceId);
            Map<String, String> response = new HashMap<>();
            response.put("message", "API key revoked successfully");
            response.put("deviceId", deviceId);
            return ResponseEntity.ok(response);
        } catch (Exception e) {
            Map<String, String> error = new HashMap<>();
            error.put("error", e.getMessage());
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body(error);
        }
    }

    /**
     * Health check for auth service
     * GET /api/auth/health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("service", "Authentication Service");
        return ResponseEntity.ok(response);
    }
}
