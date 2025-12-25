package controller;

import dto.CoughEventRequest;
import dto.CoughEventResponse;
import model.CoughStatistics;
import service.CoughService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.web.bind.annotation.*;
import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/cough")
@CrossOrigin(origins = "*")
public class CoughController {
    
    @Autowired
    private CoughService coughService;
    
    @Autowired
    private SimpMessagingTemplate messagingTemplate;
    
    /**
     * Health check endpoint
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, String>> healthCheck() {
        Map<String, String> response = new HashMap<>();
        response.put("status", "healthy");
        response.put("service", "Airea Cough Monitor API");
        response.put("timestamp", Instant.now().toString());
        return ResponseEntity.ok(response);
    }
    
    /**
     * ESP32 submits cough event
     * POST /api/cough/event
     */
    @PostMapping("/event")
    public ResponseEntity<CoughEventResponse> submitCoughEvent(
            @RequestBody CoughEventRequest request) {
        
        try {
            CoughEventResponse response = coughService.saveCoughEvent(request);
            
            // Send real-time update via WebSocket
            messagingTemplate.convertAndSend(
                "/topic/cough/" + request.getDeviceId(), 
                response
            );
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
            
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).build();
        }
    }
    
    /**
     * Get all cough events for a device
     * GET /api/cough/device/{deviceId}
     */
    @GetMapping("/device/{deviceId}")
    public ResponseEntity<List<CoughEventResponse>> getCoughEvents(
            @PathVariable String deviceId) {
        
        List<CoughEventResponse> events = coughService.getCoughEventsByDevice(deviceId);
        return ResponseEntity.ok(events);
    }
    
    /**
     * Get cough events within time range
     * GET /api/cough/device/{deviceId}/range?start=...&end=...
     */
    @GetMapping("/device/{deviceId}/range")
    public ResponseEntity<List<CoughEventResponse>> getCoughEventsByRange(
            @PathVariable String deviceId,
            @RequestParam Long start,
            @RequestParam Long end) {
        
        Instant startTime = Instant.ofEpochMilli(start);
        Instant endTime = Instant.ofEpochMilli(end);
        
        List<CoughEventResponse> events = 
                coughService.getCoughEventsByDeviceAndTimeRange(deviceId, startTime, endTime);
        
        return ResponseEntity.ok(events);
    }
    
    /**
     * Get hourly statistics
     * GET /api/cough/stats/{deviceId}/hour
     */
    @GetMapping("/stats/{deviceId}/hour")
    public ResponseEntity<CoughStatistics> getHourlyStats(@PathVariable String deviceId) {
        CoughStatistics stats = coughService.getStatisticsForLastHour(deviceId);
        return ResponseEntity.ok(stats);
    }
    
    /**
     * Get today's statistics
     * GET /api/cough/stats/{deviceId}/today
     */
    @GetMapping("/stats/{deviceId}/today")
    public ResponseEntity<CoughStatistics> getTodayStats(@PathVariable String deviceId) {
        CoughStatistics stats = coughService.getStatisticsForToday(deviceId);
        return ResponseEntity.ok(stats);
    }
    
    /**
     * Get weekly statistics
     * GET /api/cough/stats/{deviceId}/week
     */
    @GetMapping("/stats/{deviceId}/week")
    public ResponseEntity<CoughStatistics> getWeeklyStats(@PathVariable String deviceId) {
        CoughStatistics stats = coughService.getStatisticsForLastWeek(deviceId);
        return ResponseEntity.ok(stats);
    }
}