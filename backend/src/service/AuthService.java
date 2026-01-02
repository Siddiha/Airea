package service;

import dto.ApiKeyResponse;
import dto.AuthRequest;
import dto.AuthResponse;
import model.Device;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import repository.DeviceRepository;
import security.JwtTokenProvider;

import java.time.Instant;
import java.util.Optional;

@Service
public class AuthService {

    @Autowired
    private DeviceRepository deviceRepository;

    @Autowired
    private JwtTokenProvider jwtTokenProvider;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Value("${jwt.expiration:86400000}")
    private long jwtExpirationMs;

    /**
     * Generate API key for a device
     */
    public ApiKeyResponse generateApiKey(String deviceId) {
        Optional<Device> deviceOpt = deviceRepository.findByDeviceId(deviceId);

        if (deviceOpt.isEmpty()) {
            throw new RuntimeException("Device not found: " + deviceId);
        }

        Device device = deviceOpt.get();

        // Generate raw API key (this will be shown to user ONCE)
        String rawApiKey = jwtTokenProvider.generateApiKey(deviceId);

        // Hash the API key before storing
        String hashedApiKey = passwordEncoder.encode(rawApiKey);

        device.setApiKey(hashedApiKey);
        device.setApiKeyCreatedAt(Instant.now());
        deviceRepository.save(device);

        return new ApiKeyResponse(
            deviceId,
            rawApiKey,
            "IMPORTANT: Save this API key securely. It will not be shown again!"
        );
    }

    /**
     * Authenticate device and return JWT token
     */
    public AuthResponse authenticate(AuthRequest authRequest) {
        // Find device
        Optional<Device> deviceOpt = deviceRepository.findByDeviceId(authRequest.getDeviceId());

        if (deviceOpt.isEmpty()) {
            throw new RuntimeException("Invalid credentials");
        }

        Device device = deviceOpt.get();

        // Check if device is active
        if (!device.getIsActive()) {
            throw new RuntimeException("Device is deactivated");
        }

        // Verify API key
        if (device.getApiKey() == null) {
            throw new RuntimeException("Device has no API key. Please generate one first.");
        }

        if (!passwordEncoder.matches(authRequest.getApiKey(), device.getApiKey())) {
            throw new RuntimeException("Invalid credentials");
        }

        // Generate JWT token
        String token = jwtTokenProvider.generateToken(authRequest.getDeviceId());

        return new AuthResponse(
            token,
            authRequest.getDeviceId(),
            jwtExpirationMs / 1000 // Convert to seconds
        );
    }

    /**
     * Validate token and get device ID
     */
    public String validateTokenAndGetDeviceId(String token) {
        if (token == null || !jwtTokenProvider.validateToken(token)) {
            return null;
        }
        return jwtTokenProvider.getDeviceIdFromToken(token);
    }

    /**
     * Revoke device API key
     */
    public void revokeApiKey(String deviceId) {
        Optional<Device> deviceOpt = deviceRepository.findByDeviceId(deviceId);

        if (deviceOpt.isPresent()) {
            Device device = deviceOpt.get();
            device.setApiKey(null);
            device.setApiKeyCreatedAt(null);
            deviceRepository.save(device);
        }
    }
}
