package controller;

import dto.VitalsEventRequest;
import service.VitalsService;
import repository.VitalsRepository; // Added this import
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/vitals")
@CrossOrigin(origins = "*")
public class VitalsController {

    @Autowired
    private VitalsRepository vitalsRepository;

    @Autowired // <--- THIS WAS MISSING
    private VitalsService vitalsService;

    @PostMapping("/event")
    public ResponseEntity<String> receiveVitals(@RequestBody VitalsEventRequest request) {
        try {
            vitalsService.processAndSaveVitals(request);
            return ResponseEntity.ok("Vitals Logged Successfully");
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body("Error: " + e.getMessage());
        }
    }

    @GetMapping("/latest/{deviceId}")
    public ResponseEntity<?> getLatestVitals(@PathVariable String deviceId) {
        return vitalsRepository.findFirstByDeviceIdOrderByCreatedAtDesc(deviceId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
