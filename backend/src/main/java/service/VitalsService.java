package service;

import dto.VitalsEventRequest;
import model.VitalsEvent;
import repository.VitalsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

@Service
public class VitalsService {

    @Autowired
    private VitalsRepository vitalsRepository;

    @Autowired
    private SimpMessagingTemplate messagingTemplate;

    public void processAndSaveVitals(VitalsEventRequest request) {
        // Save to DB
        VitalsEvent event = new VitalsEvent();
        event.setDeviceId(request.getDeviceId());
        event.setTemp(request.getTemp());
        event.setBpm(request.getBpm());
        event.setRr(request.getRr());
        event.setLeadsOff(request.isLeadsOff());

        vitalsRepository.save(event);

        // Broadcast to WebSocket clients (Frontend Dashboard)
        messagingTemplate.convertAndSend("/topic/vitals/" + request.getDeviceId(), request);
    }
}
