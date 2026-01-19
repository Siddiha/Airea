package security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.UUID;

@Component
public class JwtTokenProvider {

    @Value("${jwt.secret:airea-super-secret-key-change-in-production-minimum-256-bits}")
    private String jwtSecret;

    @Value("${jwt.expiration:86400000}")
    private long jwtExpirationMs;

    private SecretKey getSigningKey() {
        // Ensure the key is at least 256 bits for HS256
        String keyString = jwtSecret;
        if (keyString.length() < 32) {
            // Pad with a consistent string if too short (not recommended for production)
            keyString = keyString + "0".repeat(32 - keyString.length());
        }
        return Keys.hmacShaKeyFor(keyString.getBytes(StandardCharsets.UTF_8));
    }

    /**
     * Generate JWT token for device authentication
     */
    public String generateToken(String deviceId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + jwtExpirationMs);

        return Jwts.builder()
                .subject(deviceId)
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Generate API key (longer expiration, used for device registration)
     */
    public String generateApiKey(String deviceId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + (365L * 24 * 60 * 60 * 1000)); // 1 year

        return Jwts.builder()
                .subject(deviceId)
                .id(UUID.randomUUID().toString())
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Get device ID from JWT token
     */
    public String getDeviceIdFromToken(String token) {
        Claims claims = Jwts.parser()
                .verifyWith(getSigningKey())
                .build()
                .parseSignedClaims(token)
                .getPayload();

        return claims.getSubject();
    }

    /**
     * Validate JWT token
     */
    public boolean validateToken(String token) {
        try {
            Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token);
            return true;
        } catch (Exception ex) {
            return false;
        }
    }
}
