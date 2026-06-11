package service;

import dto.VitalsEventRequest;
import model.VitalsEvent;
import repository.VitalsRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.messaging.simp.SimpMessagingTemplate;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.verify;

@ExtendWith(MockitoExtension.class)
public class VitalsServiceTest {

    @Mock
    private VitalsRepository vitalsRepository;

    @Mock
    private SimpMessagingTemplate messagingTemplate;

    @InjectMocks
    private VitalsService vitalsService;

    private VitalsEventRequest request;

    @BeforeEach
    void setUp() {
        request = new VitalsEventRequest();
        request.setDeviceId("device-123");
        request.setTemp(36.5f);
        request.setBpm(75.0f);
        request.setRr(18.0f);
        request.setLeadsOff(false);
    }

    @Test
    void testProcessAndSaveVitals_ShouldSaveToDatabase() {
        // Act
        vitalsService.processAndSaveVitals(request);

        // Assert
        ArgumentCaptor<VitalsEvent> eventCaptor = ArgumentCaptor.forClass(VitalsEvent.class);
        verify(vitalsRepository).save(eventCaptor.capture());

        VitalsEvent savedEvent = eventCaptor.getValue();
        assertEquals("device-123", savedEvent.getDeviceId());
        assertEquals(36.5f, savedEvent.getTemp());
        assertEquals(75.0f, savedEvent.getBpm());
        assertEquals(18.0f, savedEvent.getRr());
        assertEquals(false, savedEvent.isLeadsOff());
    }

    @Test
    void testProcessAndSaveVitals_ShouldBroadcastToWebSocket() {
        // Act
        vitalsService.processAndSaveVitals(request);

        // Assert
        verify(messagingTemplate).convertAndSend(eq("/topic/vitals/device-123"), eq(request));
    }
}
