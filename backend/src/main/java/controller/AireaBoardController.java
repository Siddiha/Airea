package controller;

import model.AireaBoard;
import repository.AireaBoardRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.ZoneId; // <--- IMPORT ADDED HERE
import java.util.Optional;

@RestController
@RequestMapping("/api/board")
@CrossOrigin(origins = "*")
public class AireaBoardController {

    @Autowired
    private AireaBoardRepository boardRepository;

    @PostMapping("/status")
    public ResponseEntity<String> updateBoardStatus(@RequestBody AireaBoard payload) {
        Optional<AireaBoard> existingBoard = boardRepository.findByHardwareId(payload.getHardwareId());

        AireaBoard boardToSave = existingBoard.orElse(payload);
        if (existingBoard.isPresent()) {
            boardToSave.setStatus(payload.getStatus());
            boardToSave.setIpAddress(payload.getIpAddress());
        }

        // <--- FIXED: Forces time to Sri Lanka (UTC+5:30)
        boardToSave.setLastSeen(LocalDateTime.now(ZoneId.of("Asia/Colombo")));
        
        boardRepository.save(boardToSave);

        return ResponseEntity.ok("Board status updated successfully.");
    }

    @GetMapping("/status/{hardwareId}")
    public ResponseEntity<AireaBoard> getBoardStatus(@PathVariable String hardwareId) {
        return boardRepository.findByHardwareId(hardwareId)
                .map(ResponseEntity::ok)
                .orElseGet(() -> ResponseEntity.notFound().build());
    }
}