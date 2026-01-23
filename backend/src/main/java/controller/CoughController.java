package controller;

import dto.CoughEventResponse;
import dto.CoughEventRequest;
import model.CoughStatistics;
import service.CoughService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime; // Correct Import
import java.time.ZoneId;      // Correct Import
import java.util.List;

@RestController
@RequestMapping("/api/cough")
@CrossOrigin(origins = "*")
public class CoughController {

    @Autowired
    private CoughService coughService;

    @GetMapping("/health")
    public ResponseEntity<String> healthCheck() {
        return ResponseEntity.ok("Cough Monitor API is running (SL Time Mode)");
    }

    @PostMapping("/event")
    public ResponseEntity<CoughEventResponse> receiveCoughEvent(@RequestBody CoughEventRequest request) {
        return new ResponseEntity<>(coughService.saveCoughEvent(request), HttpStatus.CREATED);
    }

    @GetMapping("/device/{deviceId}")
    public ResponseEntity<List<CoughEventResponse>> getEventsByDevice(@PathVariable String deviceId) {
        return ResponseEntity.ok(coughService.getCoughEventsByDevice(deviceId));
    }

    // --- THIS WAS THE PROBLEM AREA ---
    @GetMapping("/device/{deviceId}/range")
    public ResponseEntity<List<CoughEventResponse>> getEventsByRange(
            @PathVariable String deviceId,
            @RequestParam(required = false) LocalDateTime start,
            @RequestParam(required = false) LocalDateTime end
    ) {
        // Fix: Use LocalDateTime instead of Instant
        if (end == null) {
            end = LocalDateTime.now(ZoneId.of("Asia/Colombo"));
        }
        if (start == null) {
            start = end.minusHours(24);
        }

        return ResponseEntity.ok(coughService.getCoughEventsByDeviceAndTimeRange(deviceId, start, end));
    }
    // --------------------------------

    @GetMapping("/stats/{deviceId}/hour")
    public ResponseEntity<CoughStatistics> getHourlyStats(@PathVariable String deviceId) {
        return ResponseEntity.ok(coughService.getStatisticsForLastHour(deviceId));
    }

    @GetMapping("/stats/{deviceId}/day")
    public ResponseEntity<CoughStatistics> getTodayStats(@PathVariable String deviceId) {
        return ResponseEntity.ok(coughService.getStatisticsForToday(deviceId));
    }

    @GetMapping("/stats/{deviceId}/week")
    public ResponseEntity<CoughStatistics> getWeeklyStats(@PathVariable String deviceId) {
        return ResponseEntity.ok(coughService.getStatisticsForLastWeek(deviceId));
    }
}
