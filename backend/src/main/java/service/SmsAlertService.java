package service;

import com.twilio.Twilio;
import com.twilio.rest.api.v2010.account.Message;
import com.twilio.type.PhoneNumber;
import jakarta.annotation.PostConstruct;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

@Service
public class SmsAlertService {

    @Value("${twilio.account.sid:#{null}}")
    private String accountSid;

    @Value("${twilio.auth.token:#{null}}")
    private String authToken;

    @Value("${twilio.phone.number:#{null}}")
    private String twilioPhoneNumber;

    @Value("${sms.alerts.enabled:false}")
    private boolean smsEnabled;

    private boolean initialized = false;

    @PostConstruct
    public void init() {
        if (smsEnabled && accountSid != null && !accountSid.isEmpty() 
            && authToken != null && !authToken.isEmpty()) {
            try {
                Twilio.init(accountSid, authToken);
                initialized = true;
                System.out.println("✅ Twilio SMS Service Initialized");
            } catch (Exception e) {
                System.err.println("❌ Failed to initialize Twilio: " + e.getMessage());
                initialized = false;
            }
        } else {
            System.out.println("⚠️ SMS Alerts disabled or Twilio credentials not configured");
            System.out.println("   To enable, set sms.alerts.enabled=true and provide Twilio credentials");
        }
    }

    /**
     * Send emergency SMS alert to caregiver
     */
    public boolean sendEmergencyAlert(String toPhoneNumber, String patientName,
                                       String emergencyReason, String location,
                                       Float temp, Float bpm, Float rr, Float gForce) {
        
        String messageBody = buildEmergencyMessage(patientName, emergencyReason,
                                                    location, temp, bpm, rr, gForce);

        if (!initialized || !smsEnabled) {
            // Simulation mode - log what would be sent
            System.out.println("\n📱 ========== SMS SIMULATION ==========");
            System.out.println("   TO: " + toPhoneNumber);
            System.out.println("   MESSAGE:");
            System.out.println(messageBody);
            System.out.println("========================================\n");
            return false; // Simulated, not actually sent
        }

        try {
            Message message = Message.creator(
                    new PhoneNumber(toPhoneNumber),
                    new PhoneNumber(twilioPhoneNumber),
                    messageBody
            ).create();

            System.out.println("✅ Emergency SMS sent! SID: " + message.getSid());
            return true;

        } catch (Exception e) {
            System.err.println("❌ Failed to send SMS: " + e.getMessage());
            e.printStackTrace();
            return false;
        }
    }

    /**
     * Build the emergency message content
     */
    private String buildEmergencyMessage(String patientName, String emergencyReason,
                                          String location, Float temp, Float bpm, Float rr, Float gForce) {
        StringBuilder sb = new StringBuilder();
        sb.append("🚨 AIREA EMERGENCY ALERT 🚨\n\n");
        sb.append("Patient: ").append(patientName != null ? patientName : "Unknown").append("\n");
        sb.append("Event: FALL DETECTED\n");
        
        if (gForce != null) {
            sb.append("Impact: ").append(String.format("%.1fG", gForce)).append("\n");
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

        try {
            Message message = Message.creator(
                    new PhoneNumber(toPhoneNumber),
                    new PhoneNumber(twilioPhoneNumber),
                    "✅ AIREA Test Alert - SMS notifications are working correctly!"
            ).create();

            System.out.println("✅ Test SMS sent! SID: " + message.getSid());
            return true;
        } catch (Exception e) {
            System.err.println("❌ Test SMS failed: " + e.getMessage());
            return false;
        }
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
        return !initialized || !smsEnabled;
    }
}
