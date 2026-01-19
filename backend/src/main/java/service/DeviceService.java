package service;

import model.Device;
import repository.DeviceRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class DeviceService {
    
    @Autowired
    private DeviceRepository deviceRepository;
    
    public Device registerDevice(String deviceId, String deviceName, String location) {
        Optional<Device> existing = deviceRepository.findByDeviceId(deviceId);
        
        if (existing.isPresent()) {
            return existing.get();
        }
        
        Device device = new Device();
        device.setDeviceId(deviceId);
        device.setDeviceName(deviceName);
        device.setLocation(location);
        device.setIsActive(true);
        
        return deviceRepository.save(device);
    }
    
    public List<Device> getAllActiveDevices() {
        return deviceRepository.findByIsActive(true);
    }
    
    public List<Device> getAllDevices() {
        return deviceRepository.findAll();
    }
    
    public Optional<Device> getDeviceByDeviceId(String deviceId) {
        return deviceRepository.findByDeviceId(deviceId);
    }
    
    public Device updateDevice(String deviceId, String deviceName, String location) {
        Device device = deviceRepository.findByDeviceId(deviceId)
                .orElseThrow(() -> new RuntimeException("Device not found"));
        
        if (deviceName != null) {
            device.setDeviceName(deviceName);
        }
        if (location != null) {
            device.setLocation(location);
        }
        
        return deviceRepository.save(device);
    }
    
    public void deactivateDevice(String deviceId) {
        Device device = deviceRepository.findByDeviceId(deviceId)
                .orElseThrow(() -> new RuntimeException("Device not found"));
        
        device.setIsActive(false);
        deviceRepository.save(device);
    }
}