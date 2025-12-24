package service;

import dto.CoughEventRequest;
import dto.CoughEventResponse;
import model.CoughEvent;
import model.CoughStatistics;
import repository.CoughRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class CoughService {
    
    @Autowired
    private CoughRepository coughRepository;
    
    @Autowired
    private DeviceService deviceService;
    
    public CoughEventResponse saveCoughEvent(CoughEventRequest request) {
        // Auto-register device if it doesn't exist
        deviceService.registerDevice(request.getDeviceId(), null, null);
        
        // Create cough event
        CoughEvent event = new CoughEvent();
        event.setDeviceId(request.getDeviceId());
        event.setCoughType(request.getCoughType());
        event.setConfidence(request.getConfidence());
        event.setRawScore(request.getRawScore());
        event.setAudioVolume(request.getAudioVolume());
        
        // Set timestamp
        if (request.getTimestamp() != null) {
            event.setTimestamp(Instant.ofEpochMilli(request.getTimestamp()));
        } else {
            event.setTimestamp(Instant.now());
        }
        
        CoughEvent saved = coughRepository.save(event);
        return CoughEventResponse.fromEntity(saved);
    }
    
    public List<CoughEventResponse> getCoughEventsByDevice(String deviceId) {
        return coughRepository.findByDeviceId(deviceId)
            .stream()
            .map(CoughEventResponse::fromEntity)
            .collect(Collectors.toList());
    }
    
    public List<CoughEventResponse> getCoughEventsByDeviceAndTimeRange(
            String deviceId, Instant start, Instant end) {
        return coughRepository.findByDeviceIdAndTimestampBetween(deviceId, start, end)
            .stream()
            .map(CoughEventResponse::fromEntity)
            .collect(Collectors.toList());
    }
    
    public CoughStatistics getStatisticsForLastHour(String deviceId) {
        Instant end = Instant.now();
        Instant start = end.minus(1, ChronoUnit.HOURS);
        return calculateStatistics(deviceId, start, end, "hour");
    }
    
    public CoughStatistics getStatisticsForToday(String deviceId) {
        Instant end = Instant.now();
        Instant start = end.truncatedTo(ChronoUnit.DAYS);
        return calculateStatistics(deviceId, start, end, "day");
    }
    
    public CoughStatistics getStatisticsForLastWeek(String deviceId) {
        Instant end = Instant.now();
        Instant start = end.minus(7, ChronoUnit.DAYS);
        return calculateStatistics(deviceId, start, end, "week");
    }
    
    private CoughStatistics calculateStatistics(
            String deviceId, Instant start, Instant end, String period) {
        
        CoughStatistics stats = new CoughStatistics();
        stats.setPeriod(period);
        
        // Total coughs
        Long total = coughRepository.countCoughsByDeviceAndTimeRange(deviceId, start, end);
        stats.setTotalCoughs(total != null ? total : 0L);
        
        // Coughs by type
        List<Object[]> coughsByType = coughRepository.countCoughsByType(deviceId, start, end);
        long dry = 0, wet = 0, unknown = 0;
        String mostCommon = "none";
        long maxCount = 0;
        
        for (Object[] row : coughsByType) {
            String type = (String) row[0];
            Long count = (Long) row[1];
            
            if ("dry".equalsIgnoreCase(type)) {
                dry = count;
            } else if ("wet".equalsIgnoreCase(type)) {
                wet = count;
            } else {
                unknown = count;
            }
            
            if (count > maxCount) {
                maxCount = count;
                mostCommon = type;
            }
        }
        
        stats.setDryCoughs(dry);
        stats.setWetCoughs(wet);
        stats.setUnknownCoughs(unknown);
        stats.setMostCommonType(mostCommon);
        
        // Average confidence
        Double avgConfidence = coughRepository.getAverageConfidence(deviceId, start, end);
        stats.setAverageConfidence(avgConfidence != null ? avgConfidence : 0.0);
        
        // Coughs per hour
        long durationHours = ChronoUnit.HOURS.between(start, end);
        if (durationHours == 0) durationHours = 1;
        stats.setCoughsPerHour((double) stats.getTotalCoughs() / durationHours);
        
        return stats;
    }
}