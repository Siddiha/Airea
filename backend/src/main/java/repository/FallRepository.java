package repository;

import model.FallEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

@Repository
public interface FallRepository extends JpaRepository<FallEvent, UUID> {

    List<FallEvent> findByDeviceIdOrderByTimestampDesc(String deviceId);

    List<FallEvent> findByDeviceIdAndTimestampBetween(
            String deviceId, LocalDateTime start, LocalDateTime end);

    // Find recent emergency falls to prevent duplicate alerts (within cooldown period)
    @Query("SELECT f FROM FallEvent f WHERE f.deviceId = :deviceId " +
           "AND f.timestamp > :since AND f.isEmergency = true AND f.alertSent = true")
    List<FallEvent> findRecentEmergencyAlerts(
            @Param("deviceId") String deviceId, 
            @Param("since") LocalDateTime since);

    // Count falls for a device today
    @Query("SELECT COUNT(f) FROM FallEvent f WHERE f.deviceId = :deviceId " +
           "AND f.timestamp >= :startOfDay")
    int countTodayFalls(
            @Param("deviceId") String deviceId, 
            @Param("startOfDay") LocalDateTime startOfDay);

    // Count emergency falls for a device today
    @Query("SELECT COUNT(f) FROM FallEvent f WHERE f.deviceId = :deviceId " +
           "AND f.timestamp >= :startOfDay AND f.isEmergency = true")
    int countTodayEmergencyFalls(
            @Param("deviceId") String deviceId, 
            @Param("startOfDay") LocalDateTime startOfDay);

    // Get latest fall event for a device
    @Query("SELECT f FROM FallEvent f WHERE f.deviceId = :deviceId ORDER BY f.timestamp DESC LIMIT 1")
    FallEvent findLatestByDeviceId(@Param("deviceId") String deviceId);
}
