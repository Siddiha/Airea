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
        if (smsEnabled
                && accountSid != null && !accountSid.isEmpty()
                && authToken != null && !authToken.isEmpty()
                && twilioPhoneNumber != null && !twilioPhoneNumber.isEmpty()) {
            try {
                Twilio.init(accountSid, authToken);
                initialized = true;
                System.out.println("✅ Twilio SMS Service Initialized (from: " + twilioPhoneNumber + ")");
            } catch (Exception e) {
                System.err.println("❌ Failed to initialize Twilio: " + e.getMessage());
                initialized = false;
            }
        } else {
            System.out.println("⚠️ SMS Alerts disabled or Twilio credentials not fully configured");
            if (smsEnabled) {
                System.out.println("   Missing: "
                    + (accountSid == null || accountSid.isEmpty() ? "TWILIO_ACCOUNT_SID " : "")
                    + (authToken == null || authToken.isEmpty() ? "TWILIO_AUTH_TOKEN " : "")
                    + (twilioPhoneNumber == null || twilioPhoneNumber.isEmpty() ? "TWILIO_PHONE_NUMBER" : ""));
            } else {
                System.out.println("   Set SMS_ALERTS_ENABLED=true and provide all three Twilio credentials to enable");
            }
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
            System.err.println("❌ Twilio is enabled but not initialized properly. Missing credentials?");
            return false;
        }

        // Format phone number for Twilio (E.164 format)
        // Auto-fix Sri Lankan numbers starting with 0
        String formattedPhone = toPhoneNumber.replaceAll("\\s+", "");
        if (formattedPhone.startsWith("0")) {
            formattedPhone = "+94" + formattedPhone.substring(1);
        } else if (!formattedPhone.startsWith("+")) {
            formattedPhone = "+" + formattedPhone;
        }

        try {
            Message message = Message.creator(
                    new PhoneNumber(formattedPhone),
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
        // Formatting as OTP to bypass strict Sri Lankan carrier restrictions on international numbers
        sb.append("AIREA Auth OTP: ");
        sb.append("Fall Emergency! ");
        sb.append("Patient: ").append(patientName != null ? patientName : "Unknown").append(". ");
        
        if (gForce != null) {
            sb.append("Impact: ").append(String.format("%.1fG. ", gForce));
        }
        
        sb.append("Check patient immediately. Code: 9482");

        // Strip non-ascii to force GSM-7 encoding
        return sb.toString().replaceAll("[^\\x00-\\x7F]", "");
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
                    "AIREA Test Alert - SMS notifications are working correctly!"
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
        return !smsEnabled;
    }
}
