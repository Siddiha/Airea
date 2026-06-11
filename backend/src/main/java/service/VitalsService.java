package service;

import dto.VitalsEventRequest;
import model.VitalsEvent;
import repository.VitalsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.util.LinkedHashMap;
import java.util.Map;

@Service
public class VitalsService {

    private static class RrResolution {

        private final float rr;
        private final boolean estimated;

        private RrResolution(float rr, boolean estimated) {
            this.rr = rr;
            this.estimated = estimated;
        }
    }

    @Autowired
    private VitalsRepository vitalsRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    public void processAndSaveVitals(VitalsEventRequest request) {
        RrResolution rrResolution = resolveRespiratoryRate(request);

        // Save to DB
        VitalsEvent event = new VitalsEvent();
        event.setDeviceId(request.getDeviceId());
        event.setTemp(request.getTemp());
        event.setBpm(request.getBpm());
        event.setRr(rrResolution.rr);
        event.setRrEstimated(rrResolution.estimated);
        event.setLeadsOff(request.isLeadsOff());

        VitalsEvent savedEvent = vitalsRepository.save(event);

        // Broadcast to WebSocket clients (Frontend Dashboard)
        messagingTemplate.convertAndSend("/topic/vitals/" + request.getDeviceId(), toBroadcastPayload(savedEvent));
    }

    private RrResolution resolveRespiratoryRate(VitalsEventRequest request) {
        float incomingRr = request.getRr();
        if (incomingRr > 0.0f) {
            return new RrResolution(incomingRr, false);
        }

        if (request.isLeadsOff()) {
            return new RrResolution(0.0f, false);
        }

        String deviceId = request.getDeviceId();
        if (deviceId != null && !deviceId.isBlank()) {
            var latest = vitalsRepository.findFirstByDeviceIdOrderByCreatedAtDesc(deviceId);
            if (latest.isPresent()) {
                VitalsEvent previous = latest.get();
                if (!previous.isLeadsOff() && previous.getRr() >= 8.0f && previous.getRr() <= 30.0f) {
                    return new RrResolution(previous.getRr(), previous.isRrEstimated());
                }
            }
        }

        float bpm = request.getBpm();
        if (bpm > 0.0f) {
            float estimatedRr = bpm / 4.0f;
            if (estimatedRr < 8.0f) {
                estimatedRr = 8.0f;
            } else if (estimatedRr > 30.0f) {
                estimatedRr = 30.0f;
            }
            return new RrResolution(estimatedRr, true);
        }

        return new RrResolution(0.0f, false);
    }

    private Map<String, Object> toBroadcastPayload(VitalsEvent event) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("deviceId", event.getDeviceId());
        payload.put("temp", event.getTemp());
        payload.put("bpm", event.getBpm());
        payload.put("rr", event.getRr());
        payload.put("rrEstimated", event.isRrEstimated());
        payload.put("leadsOff", event.isLeadsOff());
        payload.put("createdAt", event.getCreatedAt());
        return payload;
    }
}
