package service;

import model.Device;
import repository.DeviceRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.Optional;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
public class DeviceServiceTest {

    @Mock
    private DeviceRepository deviceRepository;

    @InjectMocks
    private DeviceService deviceService;

    private Device testDevice;

    @BeforeEach
    void setUp() {
        testDevice = new Device();
        testDevice.setDeviceId("DEV123");
        testDevice.setDeviceName("Living Room Node");
        testDevice.setLocation("Living Room");
        testDevice.setIsActive(true);
    }

    @Test
    void registerDevice_WhenDeviceDoesNotExist_ShouldCreateNewDevice() {
        // Arrange
        when(deviceRepository.findByDeviceId("DEV123")).thenReturn(Optional.empty());
        when(deviceRepository.save(any(Device.class))).thenReturn(testDevice);

        // Act
        Device result = deviceService.registerDevice("DEV123", "Living Room Node", "Living Room");

        // Assert
        assertNotNull(result);
        assertEquals("DEV123", result.getDeviceId());
        assertTrue(result.getIsActive());
        verify(deviceRepository).save(any(Device.class));
    }

    @Test
    void registerDevice_WhenDeviceExists_ShouldReturnExistingDevice() {
        // Arrange
        when(deviceRepository.findByDeviceId("DEV123")).thenReturn(Optional.of(testDevice));

        // Act
        Device result = deviceService.registerDevice("DEV123", "New Name", "New Location");

        // Assert
        assertEquals("DEV123", result.getDeviceId());
        assertEquals("Living Room Node", result.getDeviceName()); // Should return existing, not updated
        verify(deviceRepository, never()).save(any(Device.class));
    }

    @Test
    void deactivateDevice_WhenDeviceExists_ShouldSetInactive() {
        // Arrange
        when(deviceRepository.findByDeviceId("DEV123")).thenReturn(Optional.of(testDevice));
        when(deviceRepository.save(any(Device.class))).thenReturn(testDevice);

        // Act
        deviceService.deactivateDevice("DEV123");

        // Assert
        assertFalse(testDevice.getIsActive());
        verify(deviceRepository).save(testDevice);
    }

    @Test
    void deactivateDevice_WhenDeviceDoesNotExist_ShouldThrowException() {
        // Arrange
        when(deviceRepository.findByDeviceId("UNKNOWN")).thenReturn(Optional.empty());

        // Act & Assert
        Exception exception = assertThrows(RuntimeException.class, () -> {
            deviceService.deactivateDevice("UNKNOWN");
        });
        assertEquals("Device not found", exception.getMessage());
        verify(deviceRepository, never()).save(any(Device.class));
    }
}
