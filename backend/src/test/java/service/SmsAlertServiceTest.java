package service;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;

import static org.junit.jupiter.api.Assertions.*;

@ExtendWith(MockitoExtension.class)
public class SmsAlertServiceTest {

    @InjectMocks
    private SmsAlertService smsAlertService;

    @BeforeEach
    void setUp() {
        // Set environment variables via reflection for simulation mode
        ReflectionTestUtils.setField(smsAlertService, "smsEnabled", false);
        ReflectionTestUtils.setField(smsAlertService, "notifyUserId", "user123");
        ReflectionTestUtils.setField(smsAlertService, "notifyApiKey", "api_key_123");
        ReflectionTestUtils.setField(smsAlertService, "notifySenderId", "NotifyDEMO");
        
        // Call init to set initialized flag based on our mock props
        smsAlertService.init(); 
    }

    @Test
    void isEnabled_WhenSmsDisabled_ShouldReturnFalse() {
        assertFalse(smsAlertService.isEnabled());
    }

    @Test
    void isSimulationMode_WhenSmsDisabled_ShouldReturnTrue() {
        assertTrue(smsAlertService.isSimulationMode());
    }

    @Test
    void sendEmergencyAlert_WhenSimulationMode_ShouldReturnFalseAndNotSend() {
        // Act
        boolean result = smsAlertService.sendEmergencyAlert(
            "+1234567890", 
            "John Doe", 
            "Critical High Temp", 
            "1.23, 4.56", 
            39.5f, 
            90f, 
            16f, 
            0.95f,
            "EMERGENCY_FALL"
        );

        // Assert
        assertFalse(result, "Simulation mode should return false instead of executing the HTTP call.");
    }

    @Test
    void init_WhenSmsEnabledButCredentialsMissing_ShouldNotInitialize() {
        // Arrange
        ReflectionTestUtils.setField(smsAlertService, "smsEnabled", true);
        ReflectionTestUtils.setField(smsAlertService, "notifyUserId", null); // Missing
        ReflectionTestUtils.setField(smsAlertService, "notifyApiKey", "api_key_123");
        
        // Act
        smsAlertService.init();
        
        // Assert
        assertFalse(smsAlertService.isEnabled(), "Service should not be enabled/initialized if missing API credentials");
    }
}
