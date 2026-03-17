package service;

import dto.EmergencyAlertResponse;
import dto.FallEventRequest;
import model.FallEvent;
import model.Patient;
import repository.FallRepository;
import repository.PatientRepository;
import repository.VitalsRepository;
import model.VitalsEvent;
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

    @Autowired
    private VitalsRepository vitalsRepository;

    // ==================== CLINICAL THRESHOLDS ====================
    private static final double HR_CRITICAL_LOW = 40.0;
    private static final double HR_CRITICAL_HIGH = 150.0;
    private static final double HR_WARNING_LOW = 50.0;
    private static final double HR_WARNING_HIGH = 120.0;

    private static final double TEMP_CRITICAL_LOW = 35.0;
    private static final double TEMP_CRITICAL_HIGH = 39.5;
    private static final double TEMP_WARNING_LOW = 35.5;
    private static final double TEMP_WARNING_HIGH = 38.5;

    private static final double RR_CRITICAL_LOW = 8.0;
    private static final double RR_CRITICAL_HIGH = 30.0;
    private static final double RR_WARNING_LOW = 10.0;
    private static final double RR_WARNING_HIGH = 24.0;

    // --- NEW: AI Confidence thresholds instead of G-Force ---
    private static final double CONFIDENCE_SEVERE = 0.90; // 90% AI Confidence
    private static final double CONFIDENCE_MODERATE = 0.70; // 70% AI Confidence

    @Value("${fall.detection.alert.cooldown.minutes:5}")
    private int alertCooldownMinutes;

    private static final ZoneId SL_ZONE = ZoneId.of("Asia/Colombo");

    public EmergencyAlertResponse processFallEvent(FallEventRequest request) {
        System.out.println("\n🚨 ========== FALL EVENT RECEIVED ==========");
        System.out.println("   Device: " + request.getDeviceId());

        // Print Confidence instead of G-Force
        double confPercent = request.getConfidence() != null ? request.getConfidence() * 100.0 : 0.0;
        System.out.println("   AI Confidence: " + String.format("%.1f%%", confPercent));

        System.out.println("   Vitals - Temp: " + request.getTemp()
                + ", BPM: " + request.getBpm()
                + ", RR: " + request.getRr());
        System.out.println("   Leads Off: " + request.getLeadsOff());
        if (request.getLatitude() != null && request.getLongitude() != null) {
            System.out.println("   Location: " + request.getLatitude() + ", " + request.getLongitude());
        }
        System.out.println("=============================================\n");

        FallEvent fallEvent = createFallEvent(request);
        VitalsAnalysisResult vitalsAnalysis = analyzeVitals(request);

        System.out.println("📊 Vitals Analysis: " + vitalsAnalysis.getEmergencyLevel());
        System.out.println("   Reason: " + vitalsAnalysis.getSummary());

        boolean isEmergency = determineEmergency(request, vitalsAnalysis);

        fallEvent.setIsEmergency(isEmergency);
        fallEvent.setEmergencyReason(vitalsAnalysis.getSummary());
        fallEvent.setEmergencyLevel(vitalsAnalysis.getEmergencyLevel());

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

        FallEvent savedEvent = fallRepository.save(fallEvent);
        System.out.println("💾 Fall event saved with ID: " + savedEvent.getId());

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
                .confidence(request.getConfidence()) // Swapped from G-Force
                .location(locationStr)
                .message(buildResponseMessage(isEmergency, alertSent, alertSkippedCooldown, vitalsAnalysis))
                .build();
    }

    private FallEvent createFallEvent(FallEventRequest request) {
        FallEvent event = new FallEvent();
        event.setDeviceId(request.getDeviceId());
        event.setConfidence(request.getConfidence()); // Swapped from G-Force
        event.setTemp(request.getTemp());
        event.setBpm(request.getBpm());
        event.setRr(request.getRr());
        event.setLeadsOff(request.getLeadsOff());
        event.setLatitude(request.getLatitude());
        event.setLongitude(request.getLongitude());

        if (request.getLatitude() != null && request.getLongitude() != null) {
            event.setLocationAddress(formatLocation(request.getLatitude(), request.getLongitude()));
        }

        return event;
    }

    private VitalsAnalysisResult analyzeVitals(FallEventRequest request) {
        List<String> abnormalVitals = new ArrayList<>();
        List<String> criticalVitals = new ArrayList<>();

        boolean hasReliableHeartData = !request.getLeadsOff() && request.getBpm() != null && request.getBpm() > 0;

        if (hasReliableHeartData) {
            float bpm = request.getBpm();
            if (bpm < HR_CRITICAL_LOW) {
                criticalVitals.add("SEVERE BRADYCARDIA (" + (int) bpm + " bpm)");
                abnormalVitals.add("Heart Rate: " + (int) bpm + " bpm (Critical Low)");
            } else if (bpm > HR_CRITICAL_HIGH) {
                criticalVitals.add("SEVERE TACHYCARDIA (" + (int) bpm + " bpm)");
                abnormalVitals.add("Heart Rate: " + (int) bpm + " bpm (Critical High)");
            } else if (bpm < HR_WARNING_LOW) {
                abnormalVitals.add("Heart Rate: " + (int) bpm + " bpm (Low)");
            } else if (bpm > HR_WARNING_HIGH) {
                abnormalVitals.add("Heart Rate: " + (int) bpm + " bpm (High)");
            }
        } else if (request.getLeadsOff()) {
            abnormalVitals.add("Heart Rate: Unavailable (leads off)");
        }

        Float temp = request.getTemp();
        if (temp != null && temp > 30 && temp < 45) {
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

        Float rr = request.getRr();
        if (rr != null && rr > 0 && rr < 60) {
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

    private boolean determineEmergency(FallEventRequest request, VitalsAnalysisResult analysis) {
        Float confidence = request.getConfidence() != null ? request.getConfidence() : 0f;

        if ("CRITICAL".equals(analysis.getEmergencyLevel())) {
            System.out.println("🚨 EMERGENCY CONFIRMED: Critical vitals detected!");
            return true;
        }

        if (confidence >= CONFIDENCE_SEVERE && !analysis.getAbnormalVitals().isEmpty()) {
            System.out.println("🚨 EMERGENCY CONFIRMED: High AI Confidence fall (" + String.format("%.1f%%", confidence * 100) + ") with abnormal vitals!");
            return true;
        }

        if (analysis.getAbnormalVitals().size() >= 2 && confidence >= CONFIDENCE_MODERATE) {
            System.out.println("🚨 EMERGENCY CONFIRMED: Multiple abnormal vitals after AI detected fall!");
            return true;
        }

        if (request.getLeadsOff() && confidence >= CONFIDENCE_SEVERE) {
            System.out.println("🚨 EMERGENCY CONFIRMED: High AI Confidence fall, unable to verify vitals (leads off)");
            return true;
        }

        System.out.println("✅ AI Fall recorded, but vitals appear stable - no emergency alert needed");
        return false;
    }

    private boolean isInCooldownPeriod(String deviceId) {
        LocalDateTime since = LocalDateTime.now(SL_ZONE).minusMinutes(alertCooldownMinutes);
        List<FallEvent> recentAlerts = fallRepository.findRecentEmergencyAlerts(deviceId, since);
        return !recentAlerts.isEmpty();
    }

    private AlertResult sendEmergencyAlert(FallEventRequest request,
            VitalsAnalysisResult analysis,
            FallEvent fallEvent) {
        Optional<Patient> patientOpt = patientRepository.findByDeviceId(request.getDeviceId());

        if (patientOpt.isEmpty()) {
            System.out.println("⚠️ No patient found for device: " + request.getDeviceId());
            return new AlertResult(false, null);
        }

        Patient patient = patientOpt.get();
        String emergencyContact = patient.getEmergencyContact();

        if (emergencyContact == null || emergencyContact.trim().isEmpty()) {
            System.out.println("⚠️ No emergency contact configured for patient: " + patient.getFullName());
            return new AlertResult(false, null);
        }

        String location = formatLocation(request.getLatitude(), request.getLongitude());

        System.out.println("📤 Sending emergency SMS to: " + emergencyContact);
        boolean sent = smsAlertService.sendEmergencyAlert(
                emergencyContact,
                patient.getFullName(),
                analysis.getSummary(),
                location,
                request.getTemp(),
                request.getBpm(),
                request.getRr(),
                request.getConfidence() // Passed Confidence instead of G-Force to SMS
        );

        if (sent) {
            System.out.println("✅ Emergency SMS sent successfully!");
        } else if (smsAlertService.isSimulationMode()) {
            System.out.println("📱 SMS simulated (Twilio not configured/disabled in env variables)");
        } else {
            System.out.println("❌ Failed to send emergency SMS");
        }

        return new AlertResult(sent, emergencyContact);
    }

    private String formatLocation(Double lat, Double lng) {
        if (lat == null || lng == null) {
            return "Location not available";
        }
        return String.format("%.6f, %.6f\nhttps://maps.google.com/?q=%.6f,%.6f",
                lat, lng, lat, lng);
    }

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

    public List<FallEvent> getFallHistory(String deviceId) {
        return fallRepository.findByDeviceIdOrderByTimestampDesc(deviceId);
    }

    public List<FallEvent> getFallHistory(String deviceId, LocalDateTime start, LocalDateTime end) {
        return fallRepository.findByDeviceIdAndTimestampBetween(deviceId, start, end);
    }

    public int getTodayFallCount(String deviceId) {
        LocalDateTime startOfDay = LocalDateTime.now(SL_ZONE).withHour(0).withMinute(0).withSecond(0).withNano(0);
        return fallRepository.countTodayFalls(deviceId, startOfDay);
    }

    public int getTodayEmergencyCount(String deviceId) {
        LocalDateTime startOfDay = LocalDateTime.now(SL_ZONE).withHour(0).withMinute(0).withSecond(0).withNano(0);
        return fallRepository.countTodayEmergencyFalls(deviceId, startOfDay);
    }

    public FallEvent getLatestFall(String deviceId) {
        return fallRepository.findLatestByDeviceId(deviceId);
    }

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

        public List<String> getAbnormalVitals() {
            return abnormalVitals;
        }

        public List<String> getCriticalVitals() {
            return criticalVitals;
        }

        public String getEmergencyLevel() {
            return emergencyLevel;
        }

        public String getSummary() {
            return summary;
        }
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
