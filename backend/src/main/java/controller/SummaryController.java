package controller;

import dto.DailySummaryResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import service.SummaryService;

import java.time.LocalDate;

@RestController
@RequestMapping("/api/summary")
@CrossOrigin(origins = "*")
public class SummaryController {

    @Autowired
    private SummaryService summaryService;

    @GetMapping("/daily/{deviceId}")
    public ResponseEntity<DailySummaryResponse> getDailySummary(
            @PathVariable String deviceId,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date
    ) {
        try {
            DailySummaryResponse summary = summaryService.generateDailySummary(deviceId, date);
            return ResponseEntity.ok(summary);
        } catch (Exception e) {
            System.err.println("Error generating daily summary: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.internalServerError().build();
        }
    }
}
