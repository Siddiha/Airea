package repository;

import model.Device;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Repository
public interface DeviceRepository extends JpaRepository<Device, UUID> {
    
    Optional<Device> findByDeviceId(String deviceId);
    
    List<Device> findByIsActive(Boolean isActive);
    
    boolean existsByDeviceId(String deviceId);
}