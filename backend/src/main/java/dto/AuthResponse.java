package dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class AuthResponse {

    private String token;
    private String tokenType = "Bearer";
    private Long expiresIn; // Token expiration in seconds
    private PatientInfo patient;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class PatientInfo {
        private UUID id;
        private String email;
        private String fullName;
        private LocalDate dateOfBirth;
        private String gender;
        private String address;
        private String phoneNumber;
        private String allergies;
        private String emergencyContact;
        private String deviceId;
    }
}