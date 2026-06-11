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

    // 1. Find history ordered by newest first
    List<FallEvent> findByDeviceIdOrderByTimestampDesc(String deviceId);

    // 2. Find history between two specific dates (Fixes error on line 260)
    List<FallEvent> findByDeviceIdAndTimestampBetween(String deviceId, LocalDateTime start, LocalDateTime end);

    // 3. Find recent alerts for the cooldown check
    @Query("SELECT f FROM FallEvent f WHERE f.deviceId = :deviceId AND f.isEmergency = true AND f.timestamp >= :since")
    List<FallEvent> findRecentEmergencyAlerts(@Param("deviceId") String deviceId, @Param("since") LocalDateTime since);

    // 4. Count total falls today (Fixes error on line 265)
    @Query("SELECT COUNT(f) FROM FallEvent f WHERE f.deviceId = :deviceId AND f.timestamp >= :startOfDay")
    int countTodayFalls(@Param("deviceId") String deviceId, @Param("startOfDay") LocalDateTime startOfDay);

    // 5. Count emergency falls today (Fixes error on line 270)
    @Query("SELECT COUNT(f) FROM FallEvent f WHERE f.deviceId = :deviceId AND f.isEmergency = true AND f.timestamp >= :startOfDay")
    int countTodayEmergencyFalls(@Param("deviceId") String deviceId, @Param("startOfDay") LocalDateTime startOfDay);

    // 6. Get the single most recent fall (Fixes error on line 275)
    @Query(value = "SELECT * FROM fall_events WHERE device_id = :deviceId ORDER BY timestamp DESC LIMIT 1", nativeQuery = true)
    FallEvent findLatestByDeviceId(@Param("deviceId") String deviceId);
}
