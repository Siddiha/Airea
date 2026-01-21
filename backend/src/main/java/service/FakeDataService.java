package service;

import dto.CoughEventRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.util.Random;

/**
 * Service to automatically generate fake cough data fo
 *r testing/demo purposes
 * This simulates real-time cough detection from ESP32 devices
 */
@Service
public class FakeDataService {

    @Autowired
    private CoughService coughService;

    private final Random random = new Random();
    private final String[] coughTypes = {"dry", "wet", "dry", "wet", "unknown"}; // More dry/wet than unknown
    private boolean isEnabled = true; // Can be toggled via property or endpoint

    /**
     * Generate fake cough data every 100-200 seconds
     * This simulates real-time cough detection from ESP32 devices
     */
    @Scheduled(fixedDelay = 150000, initialDelay = 10000) // ~150 seconds between events (100-200 range average)
    public void generatePeriodicFakeData() {
        if (!isEnabled) {
            return;
        }

        // Use default device ID
        String deviceId = "ESP32_COUGH_01";

        try {
            CoughEventRequest request = new CoughEventRequest();
            request.setDeviceId(deviceId);
            request.setCoughType(coughTypes[random.nextInt(coughTypes.length)]);
            request.setConfidence(0.6f + random.nextFloat() * 0.35f); // 0.6 to 0.95
            request.setRawScore(random.nextFloat());
            request.setAudioVolume(0.3f + random.nextFloat() * 0.5f); // 0.3 to 0.8
            request.setTimestamp(Instant.now().toEpochMilli());

            coughService.saveCoughEvent(request);
            System.out.println("🤖 Generated fake cough event: " + request.getCoughType() + " (confidence: " + request.getConfidence() + ") - SAVED TO SUPABASE");
        } catch (Exception e) {
            System.err.println("❌ Error generating fake data: " + e.getMessage());
        }
    }

    /**
     * Manually generate a batch of fake data
     *
     * @param deviceId Device ID to generate data for
     * @param count Number of events to generate
     * @return Number of events successfully created
     */
    public int generateBatchFakeData(String deviceId, int count) {
        int created = 0;

        for (int i = 0; i < count; i++) {
            try {
                CoughEventRequest request = new CoughEventRequest();
                request.setDeviceId(deviceId);
                request.setCoughType(coughTypes[random.nextInt(coughTypes.length)]);
                request.setConfidence(0.6f + random.nextFloat() * 0.35f); // 0.6 to 0.95
                request.setRawScore(random.nextFloat());
                request.setAudioVolume(0.3f + random.nextFloat() * 0.5f); // 0.3 to 0.8

                // Spread events over the last hour
                long minutesAgo = random.nextInt(60);
                request.setTimestamp(Instant.now().minusSeconds(minutesAgo * 60).toEpochMilli());

                coughService.saveCoughEvent(request);
                created++;
                System.out.println("💾 Batch saved event " + (i + 1) + "/" + count + " to Supabase");
            } catch (Exception e) {
                System.err.println("Error creating fake event " + i + ": " + e.getMessage());
            }
        }

        return created;
    }

    public void setEnabled(boolean enabled) {
        this.isEnabled = enabled;
    }

    public boolean isEnabled() {
        return isEnabled;
    }
}
