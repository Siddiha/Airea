package repository;

import model.VitalsEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface VitalsRepository extends JpaRepository<VitalsEvent, UUID> {

    Optional<VitalsEvent> findFirstByDeviceIdOrderByCreatedAtDesc(String deviceId);
    
    List<VitalsEvent> findByDeviceIdAndCreatedAtBetween(
            String deviceId, 
            LocalDateTime start, 
            LocalDateTime end
    );
}
