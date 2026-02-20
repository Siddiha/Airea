package repository;

import model.VitalsEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface VitalsRepository extends JpaRepository<VitalsEvent, UUID> {
}
