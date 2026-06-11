package repository;

import model.Patient;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;
import java.util.UUID;

@Repository
public interface PatientRepository extends JpaRepository<Patient, UUID> {

    Optional<Patient> findByEmail(String email);

    boolean existsByEmail(String email);

    Optional<Patient> findByDeviceId(String deviceId);

    Optional<Patient> findByPatientCode(String patientCode);
}