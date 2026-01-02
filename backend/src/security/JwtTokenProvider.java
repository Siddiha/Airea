package security;

import io.jsonwebtoken.*;
import io.jsonwebtoken.security.Keys;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;

@Component
public class JwtTokenProvider {

    @Value("${jwt.secret:airea-super-secret-key-change-this-in-production-minimum-256-bits}")
    private String jwtSecret;

    @Value("${jwt.expiration:86400000}") // 24 hours in milliseconds
    private long jwtExpirationMs;

    private SecretKey getSigningKey() {
        // Create a secure key from the secret
        byte[] keyBytes = jwtSecret.getBytes(StandardCharsets.UTF_8);
        return Keys.hmacShaKeyFor(keyBytes);
    }

    /**
     * Generate JWT token for a device
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
     * Generate long-lived API key for device (1 year)
     */
    public String generateApiKey(String deviceId) {
        Date now = new Date();
        Date expiryDate = new Date(now.getTime() + 31536000000L); // 1 year

        return Jwts.builder()
                .subject(deviceId)
                .claim("type", "API_KEY")
                .issuedAt(now)
                .expiration(expiryDate)
                .signWith(getSigningKey())
                .compact();
    }

    /**
     * Extract deviceId from token
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
        } catch (MalformedJwtException ex) {
            System.err.println("Invalid JWT token: " + ex.getMessage());
        } catch (ExpiredJwtException ex) {
            System.err.println("Expired JWT token: " + ex.getMessage());
        } catch (UnsupportedJwtException ex) {
            System.err.println("Unsupported JWT token: " + ex.getMessage());
        } catch (IllegalArgumentException ex) {
            System.err.println("JWT claims string is empty: " + ex.getMessage());
        }
        return false;
    }

    /**
     * Check if token is expired
     */
    public boolean isTokenExpired(String token) {
        try {
            Claims claims = Jwts.parser()
                    .verifyWith(getSigningKey())
                    .build()
                    .parseSignedClaims(token)
                    .getPayload();

            return claims.getExpiration().before(new Date());
        } catch (Exception e) {
            return true;
        }
    }
}
