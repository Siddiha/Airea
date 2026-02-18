package service;

import model.PasswordResetToken;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import repository.DoctorRepository;
import repository.PasswordResetTokenRepository;
import repository.PatientRepository;

import java.security.SecureRandom;
import java.time.Instant;

@Service
public class PasswordResetService {

    @Autowired
    private PasswordResetTokenRepository tokenRepository;

    @Autowired
    private PatientRepository patientRepository;

    @Autowired
    private DoctorRepository doctorRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private EmailService emailService;

    private static final int OTP_LENGTH = 6;
    private static final int OTP_EXPIRY_MINUTES = 10;

    @Transactional
    public void requestReset(String email, String userType) {
        // Verify the email exists for the given user type
        if ("PATIENT".equalsIgnoreCase(userType)) {
            if (!patientRepository.existsByEmail(email)) {
                throw new RuntimeException("No account found with this email");
            }
        } else if ("DOCTOR".equalsIgnoreCase(userType)) {
            if (!doctorRepository.existsByEmail(email)) {
                throw new RuntimeException("No account found with this email");
            }
        } else {
            throw new RuntimeException("Invalid user type");
        }

        // Generate 6-digit OTP
        String otp = generateOtp();

        // Save token to database
        PasswordResetToken resetToken = new PasswordResetToken();
        resetToken.setEmail(email);
        resetToken.setToken(otp);
        resetToken.setUserType(userType.toUpperCase());
        resetToken.setExpiresAt(Instant.now().plusSeconds(OTP_EXPIRY_MINUTES * 60));
        tokenRepository.save(resetToken);

        // Send email
        emailService.sendPasswordResetEmail(email, otp);
    }

    public boolean verifyOtp(String email, String otp, String userType) {
        PasswordResetToken token = tokenRepository
                .findByEmailAndTokenAndUserTypeAndUsedFalse(email, otp, userType.toUpperCase())
                .orElse(null);

        if (token == null) {
            return false;
        }

        // Check if expired
        if (token.getExpiresAt().isBefore(Instant.now())) {
            return false;
        }

        return true;
    }

    @Transactional
    public void resetPassword(String email, String otp, String newPassword, String userType) {
        PasswordResetToken token = tokenRepository
                .findByEmailAndTokenAndUserTypeAndUsedFalse(email, otp, userType.toUpperCase())
                .orElseThrow(() -> new RuntimeException("Invalid or expired reset code"));

        // Check if expired
        if (token.getExpiresAt().isBefore(Instant.now())) {
            throw new RuntimeException("Reset code has expired");
        }

        // Update password
        String encodedPassword = passwordEncoder.encode(newPassword);

        if ("PATIENT".equalsIgnoreCase(userType)) {
            patientRepository.findByEmail(email).ifPresent(patient -> {
                patient.setPassword(encodedPassword);
                patientRepository.save(patient);
            });
        } else if ("DOCTOR".equalsIgnoreCase(userType)) {
            doctorRepository.findByEmail(email).ifPresent(doctor -> {
                doctor.setPassword(encodedPassword);
                doctorRepository.save(doctor);
            });
        }

        // Mark token as used
        token.setUsed(true);
        tokenRepository.save(token);
    }

    private String generateOtp() {
        SecureRandom random = new SecureRandom();
        int otp = 100000 + random.nextInt(900000); // 6-digit number
        return String.valueOf(otp);
    }
}
