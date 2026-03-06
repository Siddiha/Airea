package service;

import dto.EmergencyAlertResponse;
import dto.FallEventRequest;
import model.FallEvent;
import model.Patient;
import repository.FallRepository;
import repository.PatientRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class FallDetectionService {

    @Autowired
    private FallRepository fallRepository;

    @Autowired
    private PatientRepository patientRepository;

    @Autowired
    private SmsAlertService smsAlertService;

    // ==================== CLINICAL THRESHOLDS ====================
    // Heart Rate (bpm) - Based on adult normal ranges
    private static final double HR_CRITICAL_LOW = 40.0;   // Severe bradycardia
    private static final double HR_CRITICAL_HIGH = 150.0; // Severe tachycardia
    private static final double HR_WARNING_LOW = 50.0;    // Bradycardia
    private static final double HR_WARNING_HIGH = 120.0;  // Tachycardia

    // Temperature (°C) - Normal: 36.1-37.2°C
    private static final double TEMP_CRITICAL_LOW = 35.0;  // Hypothermia
    private static final double TEMP_CRITICAL_HIGH = 39.5; // High fever
    private static final double TEMP_WARNING_LOW = 35.5;
    private static final double TEMP_WARNING_HIGH = 38.5;

    // Respiratory Rate (breaths/min) - Normal adult: 12-20
    private static final double RR_CRITICAL_LOW = 8.0;    // Respiratory depression
    private static final double RR_CRITICAL_HIGH = 30.0;  // Severe tachypnea
    private static final double RR_WARNING_LOW = 10.0;
    private static final double RR_WARNING_HIGH = 24.0;

    // G-Force threshold for severe fall
    private static final double GFORCE_SEVERE = 3.0;
    private static final double GFORCE_MODERATE = 2.0;

    // Cooldown period to prevent duplicate alerts (in minutes)
    @Value("${fall.detection.alert.cooldown.minutes:5}")
    private int alertCooldownMinutes;

    private static final ZoneId SL_ZONE = ZoneId.of("Asia/Colombo");

    /**
     * Main entry point: Process incoming fall event from ESP32
     */
    public EmergencyAlertResponse processFallEvent(FallEventRequest request) {
        System.out.println("\n🚨 ========== FALL EVENT RECEIVED ==========");
        System.out.println("   Device: " + request.getDeviceId());
        System.out.println("   G-Force: " + request.getGForce());
        System.out.println("   Vitals - Temp: " + request.getTemp() +
                          ", BPM: " + request.getBpm() +
                          ", RR: " + request.getRr());
        System.out.println("   Leads Off: " + request.getLeadsOff());
        if (request.getLatitude() != null && request.getLongitude() != null) {
            System.out.println("   Location: " + request.getLatitude() + ", " + request.getLongitude());
        }
        System.out.println("=============================================\n");

        // Step 1: Create the fall event entity
        FallEvent fallEvent = createFallEvent(request);

        // Step 2: Analyze vitals for abnormalities
        VitalsAnalysisResult vitalsAnalysis = analyzeVitals(request);
        System.out.println("📊 Vitals Analysis: " + vitalsAnalysis.getEmergencyLevel());
        System.out.println("   Reason: " + vitalsAnalysis.getSummary());

        // Step 3: Determine if this is a true emergency
        boolean isEmergency = determineEmergency(request, vitalsAnalysis);

        // Step 4: Update fall event with emergency status
        fallEvent.setIsEmergency(isEmergency);
        fallEvent.setEmergencyReason(vitalsAnalysis.getSummary());
        fallEvent.setEmergencyLevel(vitalsAnalysis.getEmergencyLevel());

        // Step 5: Send alert if emergency confirmed and not in cooldown
        boolean alertSent = false;
        String alertSentTo = null;
        boolean alertSkippedCooldown = false;

        if (isEmergency) {
            if (!isInCooldownPeriod(request.getDeviceId())) {
                AlertResult alertResult = sendEmergencyAlert(request, vitalsAnalysis, fallEvent);
                alertSent = alertResult.success;
                alertSentTo = alertResult.sentTo;

                fallEvent.setAlertSent(alertSent);
                fallEvent.setAlertSentTo(alertSentTo);
                if (alertSent) {
                    fallEvent.setAlertSentAt(LocalDateTime.now(SL_ZONE));
                }
            } else {
                alertSkippedCooldown = true;
                System.out.println("⏳ Alert skipped - within " + alertCooldownMinutes + " minute cooldown period");
            }
        }

        // Step 6: Save the fall event to database
        FallEvent savedEvent = fallRepository.save(fallEvent);
        System.out.println("💾 Fall event saved with ID: " + savedEvent.getId());

        // Step 7: Build and return response
        String locationStr = formatLocation(request.getLatitude(), request.getLongitude());
        
        return EmergencyAlertResponse.builder()
                .fallDetected(true)
                .isEmergency(isEmergency)
                .emergencyLevel(vitalsAnalysis.getEmergencyLevel())
                .abnormalVitals(vitalsAnalysis.getAbnormalVitals())
                .emergencyReason(vitalsAnalysis.getSummary())
                .alertSent(alertSent)
                .alertSentTo(alertSentTo)
                .fallEventId(savedEvent.getId().toString())
                .temp(request.getTemp())
                .bpm(request.getBpm())
                .rr(request.getRr())
                .gForce(request.getGForce())
                .location(locationStr)
                .message(buildResponseMessage(isEmergency, alertSent, alertSkippedCooldown, vitalsAnalysis))
                .build();
    }

    /**
     * Create FallEvent entity from request
     */
    private FallEvent createFallEvent(FallEventRequest request) {
        FallEvent event = new FallEvent();
        event.setDeviceId(request.getDeviceId());
        event.setGForce(request.getGForce());
        event.setTemp(request.getTemp());
        event.setBpm(request.getBpm());
        event.setRr(request.getRr());
        event.setLeadsOff(request.getLeadsOff());
        event.setLatitude(request.getLatitude());
        event.setLongitude(request.getLongitude());

        // Convert coordinates to address string if available
        if (request.getLatitude() != null && request.getLongitude() != null) {
            event.setLocationAddress(formatLocation(request.getLatitude(), request.getLongitude()));
        }

        return event;
    }

    /**
     * Analyze vitals for abnormalities - Core clinical logic
     */
    private VitalsAnalysisResult analyzeVitals(FallEventRequest request) {
        List<String> abnormalVitals = new ArrayList<>();
        List<String> criticalVitals = new ArrayList<>();

        // Check if we have reliable heart data
        boolean hasReliableHeartData = !request.getLeadsOff() && 
                                       request.getBpm() != null && 
                                       request.getBpm() > 0;

        // ===== Heart Rate Analysis =====
        if (hasReliableHeartData) {
            float bpm = request.getBpm();
            if (bpm < HR_CRITICAL_LOW) {
                criticalVitals.add("SEVERE BRADYCARDIA (" + (int)bpm + " bpm)");
                abnormalVitals.add("Heart Rate: " + (int)bpm + " bpm (Critical Low)");
            } else if (bpm > HR_CRITICAL_HIGH) {
                criticalVitals.add("SEVERE TACHYCARDIA (" + (int)bpm + " bpm)");
                abnormalVitals.add("Heart Rate: " + (int)bpm + " bpm (Critical High)");
            } else if (bpm < HR_WARNING_LOW) {
                abnormalVitals.add("Heart Rate: " + (int)bpm + " bpm (Low)");
            } else if (bpm > HR_WARNING_HIGH) {
                abnormalVitals.add("Heart Rate: " + (int)bpm + " bpm (High)");
            }
        } else if (request.getLeadsOff()) {
            abnormalVitals.add("Heart Rate: Unavailable (leads off)");
        }

        // ===== Temperature Analysis =====
        Float temp = request.getTemp();
        if (temp != null && temp > 30 && temp < 45) { // Valid range check
            if (temp <= TEMP_CRITICAL_LOW) {
                criticalVitals.add("HYPOTHERMIA (" + String.format("%.1f", temp) + "°C)");
                abnormalVitals.add("Temperature: " + String.format("%.1f", temp) + "°C (Critical Low)");
            } else if (temp >= TEMP_CRITICAL_HIGH) {
                criticalVitals.add("HIGH FEVER (" + String.format("%.1f", temp) + "°C)");
                abnormalVitals.add("Temperature: " + String.format("%.1f", temp) + "°C (Critical High)");
            } else if (temp < TEMP_WARNING_LOW) {
                abnormalVitals.add("Temperature: " + String.format("%.1f", temp) + "°C (Low)");
            } else if (temp > TEMP_WARNING_HIGH) {
                abnormalVitals.add("Temperature: " + String.format("%.1f", temp) + "°C (Elevated)");
            }
        }

        // ===== Respiratory Rate Analysis =====
        Float rr = request.getRr();
        if (rr != null && rr > 0 && rr < 60) { // Valid range check
            if (rr <= RR_CRITICAL_LOW) {
                criticalVitals.add("RESPIRATORY DEPRESSION (" + rr.intValue() + "/min)");
                abnormalVitals.add("Respiratory Rate: " + rr.intValue() + "/min (Critical Low)");
            } else if (rr >= RR_CRITICAL_HIGH) {
                criticalVitals.add("SEVERE TACHYPNEA (" + rr.intValue() + "/min)");
                abnormalVitals.add("Respiratory Rate: " + rr.intValue() + "/min (Critical High)");
            } else if (rr < RR_WARNING_LOW) {
                abnormalVitals.add("Respiratory Rate: " + rr.intValue() + "/min (Low)");
            } else if (rr > RR_WARNING_HIGH) {
                abnormalVitals.add("Respiratory Rate: " + rr.intValue() + "/min (High)");
            }
        }

        // ===== Determine Emergency Level =====
        String emergencyLevel;
        String summary;

        if (!criticalVitals.isEmpty()) {
            emergencyLevel = "CRITICAL";
            summary = "CRITICAL: " + String.join(", ", criticalVitals);
        } else if (abnormalVitals.size() >= 2) {
            emergencyLevel = "WARNING";
            summary = "WARNING: Multiple abnormal vitals - " + String.join("; ", abnormalVitals);
        } else if (!abnormalVitals.isEmpty()) {
            emergencyLevel = "MONITORING";
            summary = "MONITORING: " + abnormalVitals.get(0);
        } else {
            emergencyLevel = "NORMAL";
            summary = "Vitals within normal range after fall";
        }

        return new VitalsAnalysisResult(abnormalVitals, criticalVitals, emergencyLevel, summary);
    }

    /**
     * Determine if this fall + vitals combination is a true emergency
     */
    private boolean determineEmergency(FallEventRequest request, VitalsAnalysisResult analysis) {
        Float gForce = request.getGForce() != null ? request.getGForce() : 0f;

        // CRITICAL vitals = Always emergency
        if ("CRITICAL".equals(analysis.getEmergencyLevel())) {
            System.out.println("🚨 EMERGENCY CONFIRMED: Critical vitals detected!");
            return true;
        }

        // Severe fall (high G-force) + any abnormal vital = emergency
        if (gForce >= GFORCE_SEVERE && !analysis.getAbnormalVitals().isEmpty()) {
            System.out.println("🚨 EMERGENCY CONFIRMED: Severe fall (" + gForce + "G) with abnormal vitals!");
            return true;
        }

        // Multiple abnormal vitals after any fall = emergency
        if (analysis.getAbnormalVitals().size() >= 2 && gForce >= GFORCE_MODERATE) {
            System.out.println("🚨 EMERGENCY CONFIRMED: Multiple abnormal vitals after moderate fall!");
            return true;
        }

        // Severe fall + leads off = potential emergency (can't verify vitals, err on caution)
        if (request.getLeadsOff() && gForce >= GFORCE_SEVERE) {
            System.out.println("🚨 EMERGENCY CONFIRMED: Severe fall, unable to verify vitals (leads off)");
            return true;
        }

        // Not an emergency
        System.out.println("✅ Fall recorded, but vitals appear stable - no emergency alert needed");
        return false;
    }

    /**
     * Check if we're within the cooldown period for this device (prevent alert spam)
     */
    private boolean isInCooldownPeriod(String deviceId) {
        LocalDateTime since = LocalDateTime.now(SL_ZONE).minusMinutes(alertCooldownMinutes);
        List<FallEvent> recentAlerts = fallRepository.findRecentEmergencyAlerts(deviceId, since);
        return !recentAlerts.isEmpty();
    }

    /**
     * Send emergency alert to caregiver
     */
    private AlertResult sendEmergencyAlert(FallEventRequest request, 
                                           VitalsAnalysisResult analysis,
                                           FallEvent fallEvent) {
        // Find patient by device ID
        Optional<Patient> patientOpt = patientRepository.findByDeviceId(request.getDeviceId());

        if (patientOpt.isEmpty()) {
            System.out.println("⚠️ No patient found for device: " + request.getDeviceId());
            System.out.println("   Alert cannot be sent - device not linked to a patient");
            return new AlertResult(false, null);
        }

        Patient patient = patientOpt.get();
        String emergencyContact = patient.getEmergencyContact();

        if (emergencyContact == null || emergencyContact.trim().isEmpty()) {
            System.out.println("⚠️ No emergency contact configured for patient: " + patient.getFullName());
            System.out.println("   Alert cannot be sent - please configure emergency contact in app");
            return new AlertResult(false, null);
        }

        // Format location with Google Maps link
        String location = formatLocation(request.getLatitude(), request.getLongitude());

        // Send SMS via Twilio (or simulation)
        System.out.println("📤 Sending emergency alert to: " + emergencyContact);
        boolean sent = smsAlertService.sendEmergencyAlert(
                emergencyContact,
                patient.getFullName(),
                analysis.getSummary(),
                location,
                request.getTemp(),
                request.getBpm(),
                request.getRr(),
                request.getGForce()
        );

        if (sent) {
            System.out.println("✅ Emergency SMS sent successfully!");
        } else if (smsAlertService.isSimulationMode()) {
            System.out.println("📱 SMS simulated (Twilio not configured)");
        } else {
            System.out.println("❌ Failed to send emergency SMS");
        }

        return new AlertResult(sent || smsAlertService.isSimulationMode(), emergencyContact);
    }

    /**
     * Format coordinates into a readable location string with Google Maps link
     */
    private String formatLocation(Double lat, Double lng) {
        if (lat == null || lng == null) {
            return "Location not available";
        }
        return String.format("%.6f, %.6f\nhttps://maps.google.com/?q=%.6f,%.6f",
                             lat, lng, lat, lng);
    }

    /**
     * Build appropriate response message
     */
    private String buildResponseMessage(boolean isEmergency, boolean alertSent, boolean alertSkippedCooldown,
                                        VitalsAnalysisResult analysis) {
        if (!isEmergency) {
            return "Fall recorded - Vitals within acceptable range, no emergency alert triggered";
        }
        
        if (alertSkippedCooldown) {
            return "EMERGENCY DETECTED - Alert skipped (cooldown period active): " + analysis.getSummary();
        } else if (alertSent) {
            return "EMERGENCY DETECTED - Alert sent to caregiver: " + analysis.getSummary();
        } else {
            return "EMERGENCY DETECTED - Alert failed or configuration missing: " + analysis.getSummary();
        }
    }

    // ==================== PUBLIC QUERY METHODS ====================

    /**
     * Get fall history for a device
     */
    public List<FallEvent> getFallHistory(String deviceId) {
        return fallRepository.findByDeviceIdOrderByTimestampDesc(deviceId);
    }

    /**
     * Get fall history for a device within time range
     */
    public List<FallEvent> getFallHistory(String deviceId, LocalDateTime start, LocalDateTime end) {
        return fallRepository.findByDeviceIdAndTimestampBetween(deviceId, start, end);
    }

    /**
     * Get today's fall count for a device
     */
    public int getTodayFallCount(String deviceId) {
        LocalDateTime startOfDay = LocalDateTime.now(SL_ZONE).withHour(0).withMinute(0).withSecond(0).withNano(0);
        return fallRepository.countTodayFalls(deviceId, startOfDay);
    }

    /**
     * Get today's emergency fall count for a device
     */
    public int getTodayEmergencyCount(String deviceId) {
        LocalDateTime startOfDay = LocalDateTime.now(SL_ZONE).withHour(0).withMinute(0).withSecond(0).withNano(0);
        return fallRepository.countTodayEmergencyFalls(deviceId, startOfDay);
    }

    /**
     * Get the latest fall event for a device
     */
    public FallEvent getLatestFall(String deviceId) {
        return fallRepository.findLatestByDeviceId(deviceId);
    }

    // ==================== Inner Classes ====================

    private static class VitalsAnalysisResult {
        private final List<String> abnormalVitals;
        private final List<String> criticalVitals;
        private final String emergencyLevel;
        private final String summary;

        public VitalsAnalysisResult(List<String> abnormalVitals, List<String> criticalVitals,
                                    String emergencyLevel, String summary) {
            this.abnormalVitals = abnormalVitals;
            this.criticalVitals = criticalVitals;
            this.emergencyLevel = emergencyLevel;
            this.summary = summary;
        }

        public List<String> getAbnormalVitals() { return abnormalVitals; }
        public List<String> getCriticalVitals() { return criticalVitals; }
        public String getEmergencyLevel() { return emergencyLevel; }
        public String getSummary() { return summary; }
    }

    private static class AlertResult {
        public final boolean success;
        public final String sentTo;

        public AlertResult(boolean success, String sentTo) {
            this.success = success;
            this.sentTo = sentTo;
        }
    }
}
