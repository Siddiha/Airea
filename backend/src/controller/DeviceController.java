package controller;

import model.Device;
import service.DeviceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/device")
@CrossOrigin(origins = "*")
public class DeviceController {
    
    @Autowired
    private DeviceService deviceService;
    
    /**
     * Register a new device
     * POST /api/device/register
     */
    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> registerDevice(
            @RequestBody Map<String, String> request) {
        
        try {
            String deviceId = request.get("deviceId");
            String deviceName = request.get("deviceName");
            String location = request.get("location");
            
            Device device = deviceService.registerDevice(deviceId, deviceName, location);
            
            Map<String, Object> response = new HashMap<>();
            response.put("success", true);
            response.put("message", "Device registered successfully");
            response.put("device", device);
            
            return ResponseEntity.status(HttpStatus.CREATED).body(response);
            
        } catch (Exception e) {
            Map<String, Object> error = new HashMap<>();
            error.put("success", false);
            error.put("message", "Failed to register device: " + e.getMessage());
            
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(error);
        }
    }
    
    /**
     * Get all active devices
     * GET /api/device/active
     */
    @GetMapping("/active")
    public ResponseEntity<List<Device>> getActiveDevices() {
        List<Device> devices = deviceService.getAllActiveDevices();
        return ResponseEntity.ok(devices);
    }
    
    /**
     * Get all devices
     * GET /api/device/all
     */
    @GetMapping("/all")
    public ResponseEntity<List<Device>> getAllDevices() {
        List<Device> devices = deviceService.getAllDevices();
        return ResponseEntity.ok(devices);
    }
    
    /**
     * Get device by device ID
     * GET /api/device/{deviceId}
     */
    @GetMapping("/{deviceId}")
    public ResponseEntity<Device> getDevice(@PathVariable String deviceId) {
        Optional<Device> device = deviceService.getDeviceByDeviceId(deviceId);
        
        return device.map(ResponseEntity::ok)
                     .orElse(ResponseEntity.notFound().build());
    }
    
    /**
     * Update device information
     * PUT /api/device/{deviceId}
     */
    @PutMapping("/{deviceId}")
    public ResponseEntity<Device> updateDevice(
            @PathVariable String deviceId,
            @RequestBody Map<String, String> request) {
        
        try {
            String deviceName = request.get("deviceName");
            String location = request.get("location");
            
            Device updated = deviceService.updateDevice(deviceId, deviceName, location);
            return ResponseEntity.ok(updated);
            
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    /**
     * Deactivate a device
     * DELETE /api/device/{deviceId}
     */
    @DeleteMapping("/{deviceId}")
    public ResponseEntity<Map<String, String>> deactivateDevice(
            @PathVariable String deviceId) {
        
        try {
            deviceService.deactivateDevice(deviceId);
            
            Map<String, String> response = new HashMap<>();
            response.put("message", "Device deactivated successfully");
            
            return ResponseEntity.ok(response);
            
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}