package repository;

import model.CoughEvent;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.Instant;
import java.util.List;
import java.util.UUID;

@Repository
public interface CoughRepository extends JpaRepository<CoughEvent, UUID> {
    
    List<CoughEvent> findByDeviceId(String deviceId);
    
    List<CoughEvent> findByDeviceIdAndTimestampBetween(
        String deviceId, 
        Instant start, 
        Instant end
    );
    
    List<CoughEvent> findByDeviceIdAndCoughType(String deviceId, String coughType);
    
    @Query("SELECT COUNT(c) FROM CoughEvent c WHERE c.deviceId = :deviceId " +
           "AND c.timestamp BETWEEN :start AND :end")
    Long countCoughsByDeviceAndTimeRange(
        @Param("deviceId") String deviceId,
        @Param("start") Instant start,
        @Param("end") Instant end
    );
    
    @Query("SELECT c.coughType, COUNT(c) FROM CoughEvent c " +
           "WHERE c.deviceId = :deviceId AND c.timestamp BETWEEN :start AND :end " +
           "GROUP BY c.coughType")
    List<Object[]> countCoughsByType(
        @Param("deviceId") String deviceId,
        @Param("start") Instant start,
        @Param("end") Instant end
    );
    
    @Query("SELECT AVG(c.confidence) FROM CoughEvent c " +
           "WHERE c.deviceId = :deviceId AND c.timestamp BETWEEN :start AND :end")
    Double getAverageConfidence(
        @Param("deviceId") String deviceId,
        @Param("start") Instant start,
        @Param("end") Instant end
    );
}