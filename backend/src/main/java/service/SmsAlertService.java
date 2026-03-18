package service;

import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.HashMap;
import java.util.Map;

@Service
public class SmsAlertService {

    @Value("${notify.user.id:#{null}}")
    private String notifyUserId;

    @Value("${notify.api.key:#{null}}")
    private String notifyApiKey;

    @Value("${notify.sender.id:NotifyDEMO}")
    private String notifySenderId;

    @Value("${sms.alerts.enabled:false}")
    private boolean smsEnabled;

    private boolean initialized = false;
    private final RestTemplate restTemplate = new RestTemplate();
    private static final String NOTIFY_API_URL = "https://app.notify.lk/api/v1/send";

    @PostConstruct
    public void init() {
        if (smsEnabled
                && notifyUserId != null && !notifyUserId.isEmpty()
                && notifyApiKey != null && !notifyApiKey.isEmpty()) {
            initialized = true;
            System.out.println("✅ Notify.lk SMS Service Initialized (Sender ID: " + notifySenderId + ")");
        } else {
            System.out.println("⚠️ SMS Alerts disabled or Notify.lk credentials not fully configured");
            if (smsEnabled) {
                System.out.println("   Missing Notify.lk Credentials check NOTIFY_USER_ID and NOTIFY_API_KEY");
            } else {
                System.out.println("   Set SMS_ALERTS_ENABLED=true and provide Notify.lk credentials to enable");
            }
        }
    }

    /**
     * Send emergency SMS alert to caregiver
     */
    public boolean sendEmergencyAlert(String toPhoneNumber, String patientName,
                                       String emergencyReason, String location,
                                       Float temp, Float bpm, Float rr, Float confidence, String alertType) {
        
        String messageBody = buildEmergencyMessage(patientName, emergencyReason,
                                                    location, temp, bpm, rr, confidence, alertType);

        if (!smsEnabled) {
            // Simulation mode - log what would be sent
            System.out.println("\n📱 ========== SMS SIMULATION ==========");
            System.out.println("   TO: " + toPhoneNumber);
            System.out.println("   MESSAGE:");
            System.out.println(messageBody);
            System.out.println("========================================\n");
            return false; // Simulated, not actually sent
        }

        if (!initialized) {
            System.err.println("❌ Notify.lk SMS is enabled but not initialized properly. Missing credentials?");
            return false;
        }

        return sendViaNotifyLk(toPhoneNumber, messageBody);
    }

    /**
     * Executes the HTTP request to the Notify.lk API
     */
    private boolean sendViaNotifyLk(String toPhoneNumber, String messageBody) {
        // Format phone number for Notify.lk (e.g. 9471XXXXXXX)
        String formattedPhone = toPhoneNumber.replaceAll("[^0-9]", "");
        if (formattedPhone.startsWith("0")) {
            formattedPhone = "94" + formattedPhone.substring(1);
        } else if (formattedPhone.startsWith("+94")) {
            formattedPhone = formattedPhone.substring(1); // Remove '+'
        } else if (!formattedPhone.startsWith("94")) {
            // Assume it's a local number without '0' prefix, prepend '94'
            formattedPhone = "94" + formattedPhone;
        }


        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, String> requestBody = new HashMap<>();
            requestBody.put("user_id", notifyUserId);
            requestBody.put("api_key", notifyApiKey);
            requestBody.put("sender_id", notifySenderId);
            requestBody.put("to", formattedPhone);
            requestBody.put("message", messageBody);

            HttpEntity<Map<String, String>> request = new HttpEntity<>(requestBody, headers);

            ResponseEntity<Map> response = restTemplate.postForEntity(NOTIFY_API_URL, request, Map.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                String status = (String) response.getBody().get("status");
                if ("success".equalsIgnoreCase(status)) {
                    System.out.println("✅ Emergency SMS sent via Notify.lk!");
                    return true;
                } else {
                    System.err.println("❌ Notify.lk API returned failure: " + response.getBody());
                }
            } else {
                System.err.println("❌ Failed to send SMS via Notify.lk, HTTP Status: " + response.getStatusCode());
            }
        } catch (Exception e) {
            System.err.println("❌ Exception occurred while sending SMS via Notify.lk: " + e.getMessage());
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Build the emergency message content
     */
    private String buildEmergencyMessage(String patientName, String emergencyReason,
                                          String location, Float temp, Float bpm, Float rr, Float confidence, String alertType) {
        StringBuilder sb = new StringBuilder();
        
        sb.append("🚨 AIREA EMERGENCY ALERT 🚨\n\n");
        sb.append("Patient: ").append(patientName != null ? patientName : "Unknown").append("\n");
        sb.append("Event: ").append(alertType != null ? alertType : "FALL DETECTED").append("\n");
        
        if (confidence != null) {
            sb.append("AI Confidence: ").append(String.format("%.1f%%", confidence * 100)).append("\n");
        }
        
        sb.append("\nStatus: ").append(emergencyReason != null ? emergencyReason : "Emergency").append("\n\n");

        sb.append("📊 Vitals at Fall:\n");
        if (temp != null && temp > 30 && temp < 45) {
            sb.append("• Temp: ").append(String.format("%.1f°C", temp)).append("\n");
        }
        if (bpm != null && bpm > 0) {
            sb.append("• Heart Rate: ").append(String.format("%.0f bpm", bpm)).append("\n");
        }
        if (rr != null && rr > 0) {
            sb.append("• Resp Rate: ").append(String.format("%.0f /min", rr)).append("\n");
        }

        sb.append("\n📍 Location:\n");
        sb.append(location != null && !location.isEmpty() ? location : "Unknown");
        sb.append("\n\n⚠️ Please check on the patient immediately!");

        return sb.toString();
    }

    /**
     * Send a test SMS to verify configuration
     */
    public boolean sendTestSms(String toPhoneNumber) {
        if (!initialized) {
            System.out.println("📱 [TEST SMS SIMULATION] Would send to: " + toPhoneNumber);
            return false;
        }

        String testMessage = "✅ AIREA Test Alert - SMS notifications via Notify.lk are working correctly!";
        boolean result = sendViaNotifyLk(toPhoneNumber, testMessage);
        
        if (result) {
            System.out.println("✅ Test SMS sent to " + toPhoneNumber);
        } else {
            System.err.println("❌ Test SMS failed to " + toPhoneNumber);
        }
        
        return result;
    }

    /**
     * Check if SMS service is enabled and initialized
     */
    public boolean isEnabled() {
        return smsEnabled && initialized;
    }

    /**
     * Check if SMS service is in simulation mode
     */
    public boolean isSimulationMode() {
        return !smsEnabled;
    }
}
