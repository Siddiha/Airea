package repository;

import model.DoctorPatientLink;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.UUID;

@Repository
public interface DoctorPatientLinkRepository extends JpaRepository<DoctorPatientLink, Long> {
    boolean existsByDoctorIdAndPatientId(UUID doctorId, UUID patientId);
}