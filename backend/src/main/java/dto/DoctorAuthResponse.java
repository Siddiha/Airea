package dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class DoctorAuthResponse {

    private String token;
    private String tokenType = "Bearer";
    private Long expiresIn;
    private DoctorInfo doctor;

    @Data
    @Builder
    @NoArgsConstructor
    @AllArgsConstructor
    public static class DoctorInfo {
        private UUID id;
        private String email;
        private String fullName;
        private String specialization;
        private String phoneNumber;
        private String hospital;
    }
}
