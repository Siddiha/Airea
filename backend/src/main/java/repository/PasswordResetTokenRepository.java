package repository;

import model.PasswordResetToken;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;
import java.util.UUID;

public interface PasswordResetTokenRepository extends JpaRepository<PasswordResetToken, UUID> {

    Optional<PasswordResetToken> findByEmailAndTokenAndUserTypeAndUsedFalse(
            String email, String token, String userType);

    void deleteByEmail(String email);
}
