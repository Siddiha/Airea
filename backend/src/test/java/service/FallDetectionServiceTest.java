package service;

import dto.EmergencyAlertResponse;
import dto.FallEventRequest;
import model.FallEvent;
import model.Patient;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.test.util.ReflectionTestUtils;
import repository.FallRepository;
import repository.PatientRepository;

import java.util.Collections;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class FallDetectionServiceTest {

    @Mock
    private FallRepository fallRepository;

    @Mock
    private PatientRepository patientRepository;

    @Mock
    private SmsAlertService smsAlertService;

    @InjectMocks
    private FallDetectionService fallDetectionService;

    private FallEventRequest normalFallReq;
    private FallEventRequest criticalFallReq;
    private Patient testPatient;
    private FallEvent savedFallEvent;

    @BeforeEach
    void setUp() {
        // Set cooldown minutes using reflection since it's a @Value property
        ReflectionTestUtils.setField(fallDetectionService, "alertCooldownMinutes", 5);

        testPatient = new Patient();
        testPatient.setDeviceId("DEV123");
        testPatient.setFullName("John Doe");
        testPatient.setEmergencyContact("+1234567890");

        savedFallEvent = new FallEvent();
        savedFallEvent.setId(java.util.UUID.randomUUID());

        // Basic fall, normal vitals
        normalFallReq = new FallEventRequest();
        normalFallReq.setDeviceId("DEV123");
        normalFallReq.setGForce(1.5f);
        normalFallReq.setTemp(36.5f);
        normalFallReq.setBpm(75f);
        normalFallReq.setRr(16f);
        normalFallReq.setLeadsOff(false);

        // Severe fall, critical vitals (Hypothermia + Bradycardia)
        criticalFallReq = new FallEventRequest();
        criticalFallReq.setDeviceId("DEV123");
        criticalFallReq.setGForce(3.5f);
        criticalFallReq.setTemp(34.0f); // Critical low
        criticalFallReq.setBpm(35f);    // Critical low
        criticalFallReq.setRr(10f);
        criticalFallReq.setLeadsOff(false);
    }

    @Test
    void processFallEvent_WithNormalVitals_ShouldNotTriggerEmergency() {
        when(fallRepository.save(any(FallEvent.class))).thenReturn(savedFallEvent);

        EmergencyAlertResponse response = fallDetectionService.processFallEvent(normalFallReq);

        assertNotNull(response);
        assertTrue(response.isFallDetected());
        assertFalse(response.isEmergency());
        assertEquals("NORMAL", response.getEmergencyLevel());
        verify(smsAlertService, never()).sendEmergencyAlert(anyString(), anyString(), anyString(), anyString(), anyFloat(), anyFloat(), anyFloat(), anyFloat());
    }

    @Test
    void processFallEvent_WithCriticalVitals_ShouldTriggerEmergencyAndSendSms() {
        when(fallRepository.save(any(FallEvent.class))).thenReturn(savedFallEvent);
        when(fallRepository.findRecentEmergencyAlerts(anyString(), any())).thenReturn(Collections.emptyList()); // No cooldown
        when(patientRepository.findByDeviceId("DEV123")).thenReturn(Optional.of(testPatient));
        when(smsAlertService.sendEmergencyAlert(anyString(), anyString(), anyString(), any(), anyFloat(), anyFloat(), anyFloat(), anyFloat())).thenReturn(true);

        EmergencyAlertResponse response = fallDetectionService.processFallEvent(criticalFallReq);

        assertNotNull(response);
        assertTrue(response.isEmergency());
        assertEquals("CRITICAL", response.getEmergencyLevel());
        assertTrue(response.isAlertSent());
        assertEquals("+1234567890", response.getAlertSentTo());
        verify(smsAlertService).sendEmergencyAlert(eq("+1234567890"), eq("John Doe"), anyString(), any(), anyFloat(), anyFloat(), anyFloat(), anyFloat());
    }

    @Test
    void processFallEvent_DuringCooldownPeriod_ShouldNotSendDuplicateSms() {
        when(fallRepository.save(any(FallEvent.class))).thenReturn(savedFallEvent);
        // Simulate an existing alert within the last 5 minutes
        when(fallRepository.findRecentEmergencyAlerts(anyString(), any())).thenReturn(Collections.singletonList(new FallEvent()));
        
        EmergencyAlertResponse response = fallDetectionService.processFallEvent(criticalFallReq);

        assertTrue(response.isEmergency());
        assertFalse(response.isAlertSent()); // Alert blocked by cooldown
        verify(smsAlertService, never()).sendEmergencyAlert(anyString(), anyString(), anyString(), anyString(), anyFloat(), anyFloat(), anyFloat(), anyFloat());
    }

    @Test
    void processFallEvent_WhenPatientHasNoEmergencyContact_ShouldNotSendSms() {
        testPatient.setEmergencyContact(null); // Remove contact
        when(fallRepository.save(any(FallEvent.class))).thenReturn(savedFallEvent);
        when(fallRepository.findRecentEmergencyAlerts(anyString(), any())).thenReturn(Collections.emptyList());
        when(patientRepository.findByDeviceId("DEV123")).thenReturn(Optional.of(testPatient));

        EmergencyAlertResponse response = fallDetectionService.processFallEvent(criticalFallReq);

        assertTrue(response.isEmergency());
        assertFalse(response.isAlertSent());
        verify(smsAlertService, never()).sendEmergencyAlert(anyString(), anyString(), anyString(), anyString(), anyFloat(), anyFloat(), anyFloat(), anyFloat());
    }
}
