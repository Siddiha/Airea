package service;

import dto.CoughEventRequest;
import dto.CoughEventResponse;
import model.CoughEvent;
import model.CoughStatistics;
import repository.CoughRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDateTime; // <--- NEW IMPORT
import java.time.ZoneId;      // <--- NEW IMPORT
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

    // Helper to get SL Time
    private LocalDateTime nowSL() {
        return LocalDateTime.now(ZoneId.of("Asia/Colombo"));
    }

    public CoughEventResponse saveCoughEvent(CoughEventRequest request) {
        deviceService.registerDevice(request.getDeviceId(), null, null);

        CoughEvent event = new CoughEvent();
        event.setDeviceId(request.getDeviceId());
        event.setConfidence(request.getConfidence());
        event.setRawScore(request.getRawScore());
        event.setAudioVolume(request.getAudioVolume());

        // Save with Sri Lanka Time
        event.setTimestamp(nowSL());

        CoughEvent saved = coughRepository.save(event);
        System.out.println("💾 Saved cough event - ID: " + saved.getId());
        return CoughEventResponse.fromEntity(saved);
    }

    public List<CoughEventResponse> getCoughEventsByDevice(String deviceId) {
        return coughRepository.findByDeviceId(deviceId)
                .stream()
                .map(CoughEventResponse::fromEntity)
                .collect(Collectors.toList());
    }

    // Updated to use LocalDateTime
    public List<CoughEventResponse> getCoughEventsByDeviceAndTimeRange(
            String deviceId, LocalDateTime start, LocalDateTime end) {
        return coughRepository.findByDeviceIdAndTimestampBetween(deviceId, start, end)
                .stream()
                .map(CoughEventResponse::fromEntity)
                .collect(Collectors.toList());
    }

    public CoughStatistics getStatisticsForLastHour(String deviceId) {
        LocalDateTime end = nowSL();
        LocalDateTime start = end.minusHours(1);
        return calculateStatistics(deviceId, start, end, "hour");
    }

    public CoughStatistics getStatisticsForToday(String deviceId) {
        LocalDateTime end = nowSL();
        LocalDateTime start = end.toLocalDate().atStartOfDay(); // 00:00 today
        return calculateStatistics(deviceId, start, end, "day");
    }

    public CoughStatistics getStatisticsForLastWeek(String deviceId) {
        LocalDateTime end = nowSL();
        LocalDateTime start = end.minusDays(7);
        return calculateStatistics(deviceId, start, end, "week");
    }

    // Updated private method signature to accept LocalDateTime
    private CoughStatistics calculateStatistics(
            String deviceId, LocalDateTime start, LocalDateTime end, String period) {

        CoughStatistics stats = new CoughStatistics();
        stats.setPeriod(period);

        Long total = coughRepository.countCoughsByDeviceAndTimeRange(deviceId, start, end);
        stats.setTotalCoughs(total != null ? total : 0L);

        Double avgConfidence = coughRepository.getAverageConfidence(deviceId, start, end);
        stats.setAverageConfidence(avgConfidence != null ? avgConfidence : 0.0);

        // Calculate hours difference safely for LocalDateTime
        long durationHours = ChronoUnit.HOURS.between(start, end);
        if (durationHours == 0) {
            durationHours = 1;
        }
        stats.setCoughsPerHour((double) stats.getTotalCoughs() / durationHours);

        // // No more dry/wet logic
        // stats.setDryCoughs(0L);
        // stats.setWetCoughs(0L);
        // stats.setUnknownCoughs(stats.getTotalCoughs());
        // stats.setMostCommonType("unknown");
        return stats;
    }
}
