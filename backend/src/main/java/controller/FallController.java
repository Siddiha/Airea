package controller;

import dto.EmergencyAlertResponse;
import dto.FallEventRequest;
import model.FallEvent;
import service.FallDetectionService;
import service.SmsAlertService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/fall")
@CrossOrigin(origins = "*")
public class FallController {

    @Autowired
    private FallDetectionService fallDetectionService;

    @Autowired
    private SmsAlertService smsAlertService;

    private static final ZoneId SL_ZONE = ZoneId.of("Asia/Colombo");

    /**
     * Health check endpoint
     * GET /api/fall/health
     */
    @GetMapping("/health")
    public ResponseEntity<Map<String, Object>> healthCheck() {
        Map<String, Object> status = new HashMap<>();
        status.put("service", "Fall Detection Service");
        status.put("status", "UP");
        status.put("smsEnabled", smsAlertService.isEnabled());
        status.put("smsSimulationMode", smsAlertService.isSimulationMode());
        status.put("timestamp", LocalDateTime.now(SL_ZONE).toString());
        return ResponseEntity.ok(status);
    }

    /**
     * Receive fall event from ESP32
     * POST /api/fall/event
     * 
     * Request body example:
     * {
     *   "deviceId": "ESP32_COUGH_01",
     *   "gForce": 3.5,
     *   "temp": 38.5,
     *   "bpm": 45,
     *   "rr": 8,
     *   "leadsOff": false,
     *   "latitude": 6.9271,
     *   "longitude": 79.8612
     * }
     */
    @PostMapping("/event")
    public ResponseEntity<EmergencyAlertResponse> receiveFallEvent(@RequestBody FallEventRequest request) {
        try {
            System.out.println("\n📥 ========== INCOMING FALL EVENT ==========");
            System.out.println("   From device: " + request.getDeviceId());
            System.out.println("   Time: " + LocalDateTime.now(SL_ZONE));
            System.out.println("============================================\n");

            EmergencyAlertResponse response = fallDetectionService.processFallEvent(request);

            return ResponseEntity.ok(response);

        } catch (Exception e) {
            System.err.println("❌ Error processing fall event: " + e.getMessage());
            e.printStackTrace();

            return ResponseEntity.internalServerError()
                    .body(EmergencyAlertResponse.builder()
                            .fallDetected(true)
                            .isEmergency(false)
                            .emergencyLevel("ERROR")
                            .message("Error processing fall event: " + e.getMessage())
                            .build());
        }
    }

    /**
     * Get fall history for a device
     * GET /api/fall/history/{deviceId}
     */
    @GetMapping("/history/{deviceId}")
    public ResponseEntity<List<FallEvent>> getFallHistory(@PathVariable String deviceId) {
        List<FallEvent> history = fallDetectionService.getFallHistory(deviceId);
        return ResponseEntity.ok(history);
    }

    /**
     * Get fall history for a device within time range
     * GET /api/fall/history/{deviceId}/range?start=...&end=...
     */
    @GetMapping("/history/{deviceId}/range")
    public ResponseEntity<List<FallEvent>> getFallHistoryByRange(
            @PathVariable String deviceId,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime start,
            @RequestParam(required = false) @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime end) {
        
        if (end == null) {
            end = LocalDateTime.now(SL_ZONE);
        }
        if (start == null) {
            start = end.minusDays(7); // Default to last 7 days
        }

        List<FallEvent> history = fallDetectionService.getFallHistory(deviceId, start, end);
        return ResponseEntity.ok(history);
    }

    /**
     * Get today's fall statistics for a device
     * GET /api/fall/stats/today/{deviceId}
     */
    @GetMapping("/stats/today/{deviceId}")
    public ResponseEntity<Map<String, Object>> getTodayStats(@PathVariable String deviceId) {
        Map<String, Object> stats = new HashMap<>();
        stats.put("deviceId", deviceId);
        stats.put("totalFalls", fallDetectionService.getTodayFallCount(deviceId));
        stats.put("emergencyFalls", fallDetectionService.getTodayEmergencyCount(deviceId));
        stats.put("date", LocalDateTime.now(SL_ZONE).toLocalDate().toString());
        return ResponseEntity.ok(stats);
    }

    /**
     * Get latest fall event for a device
     * GET /api/fall/latest/{deviceId}
     */
    @GetMapping("/latest/{deviceId}")
    public ResponseEntity<?> getLatestFall(@PathVariable String deviceId) {
        FallEvent latest = fallDetectionService.getLatestFall(deviceId);
        if (latest == null) {
            Map<String, String> response = new HashMap<>();
            response.put("message", "No fall events found for device: " + deviceId);
            return ResponseEntity.ok(response);
        }
        return ResponseEntity.ok(latest);
    }

    /**
     * Test SMS alert (for verification during setup)
     * POST /api/fall/test-sms?phoneNumber=+94771234567
     */
    @PostMapping("/test-sms")
    public ResponseEntity<Map<String, Object>> testSmsAlert(@RequestParam String phoneNumber) {
        Map<String, Object> response = new HashMap<>();

        System.out.println("📱 Testing SMS to: " + phoneNumber);

        if (smsAlertService.isSimulationMode()) {
            response.put("success", false);
            response.put("simulationMode", true);
            response.put("message", "SMS service is in simulation mode. Configure Twilio credentials to enable.");
            return ResponseEntity.ok(response);
        }

        boolean sent = smsAlertService.sendTestSms(phoneNumber);
        response.put("success", sent);
        response.put("simulationMode", false);
        response.put("message", sent ? "Test SMS sent successfully to " + phoneNumber : "Failed to send test SMS");

        return ResponseEntity.ok(response);
    }

    /**
     * Manually trigger a test emergency (for testing without device)
     * POST /api/fall/test-emergency
     */
    @PostMapping("/test-emergency")
    public ResponseEntity<EmergencyAlertResponse> testEmergencyAlert(@RequestBody FallEventRequest request) {
        System.out.println("\n🧪 ========== TEST EMERGENCY TRIGGER ==========");
        System.out.println("   This is a TEST - processing as real event");
        System.out.println("===============================================\n");

        // Process as a normal fall event
        EmergencyAlertResponse response = fallDetectionService.processFallEvent(request);
        return ResponseEntity.ok(response);
    }
}
