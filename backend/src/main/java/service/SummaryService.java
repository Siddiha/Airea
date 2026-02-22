package service;

import dto.*;
import model.CoughEvent;
import model.VitalsEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import repository.CoughRepository;
import repository.VitalsRepository;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class SummaryService {

    @Autowired
    private CoughRepository coughRepository;
    
    @Autowired
    private VitalsRepository vitalsRepository;

    private static final ZoneId SRI_LANKA_ZONE = ZoneId.of("Asia/Colombo");
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");
    
    // Clinical Ranges for Vitals
    // Heart Rate (bpm)
    private static final double HR_NORMAL_MIN = 60.0;
    private static final double HR_NORMAL_MAX = 100.0;
    private static final double HR_BRADYCARDIA = 50.0;
    private static final double HR_TACHYCARDIA = 110.0;
    
    // Temperature (°C)
    private static final double TEMP_NORMAL_MIN = 36.1;
    private static final double TEMP_NORMAL_MAX = 37.5;
    private static final double TEMP_FEVER = 37.8;
    private static final double TEMP_HIGH_FEVER = 38.5;
    private static final double TEMP_HYPOTHERMIA = 35.0;
    
    // Respiratory Rate (breaths/min)
    private static final double RR_NORMAL_MIN = 12.0;
    private static final double RR_NORMAL_MAX = 20.0;
    private static final double RR_TACHYPNEA = 24.0;
    private static final double RR_DEPRESSION = 10.0;

    public DailySummaryResponse generateDailySummary(String deviceId, LocalDate date) {
        DailySummaryResponse response = new DailySummaryResponse();
        response.setDate(date.format(DATE_FORMATTER));
        response.setDeviceId(deviceId);

        // Get cough events for the day
        List<CoughEvent> events = getCoughEventsForDay(deviceId, date);
        
        // Always calculate vitals summary (even if no cough data)
        VitalsSummary vitalsSummary = calculateVitalsSummary(deviceId, date);

        if (events.isEmpty()) {
            response.setHasData(vitalsSummary.isHasVitalsData()); // Has data if vitals exist
            response.setMessage(vitalsSummary.isHasVitalsData() 
                ? "No cough data, but vitals recorded" 
                : "No cough or vitals data available for this date");
            response.setTotalCoughs(0);
            response.setCoughFrequency(0.0);
            response.setAvgConfidence(0.0);
            response.setAvgVolume(0.0);
            response.setNightCoughs(0);
            response.setDayCoughs(0);
            response.setNightPercentage(0.0);
            response.setPeakHour(0);
            response.setHourlyDistribution(generateEmptyHourlyDistribution());
            response.setPatterns(new ArrayList<>());
            response.setVitalsSummary(vitalsSummary);
            response.setSeverityScore(vitalsSummary.getVitalsSeverityScore());
            response.setSeverityLevel(getSeverityLevel(vitalsSummary.getVitalsSeverityScore()));
            response.setHealthStatus(vitalsSummary.isHasVitalsData() 
                ? vitalsSummary.getVitalsStatus() 
                : "No data");
            response.setInsights(generateVitalsOnlyInsights(vitalsSummary));
            response.setRecommendations(generateVitalsOnlyRecommendations(vitalsSummary));
            response.setComparison(new DailyComparison(0, 0, 0.0, "STABLE"));
            return response;
        }

        // Calculate basic statistics
        int totalCoughs = events.size();
        double avgConfidence = events.stream()
                .mapToDouble(e -> e.getConfidence() != null ? e.getConfidence() * 100 : 0)
                .average()
                .orElse(0);
        double avgVolume = events.stream()
                .filter(e -> e.getAudioVolume() != null)
                .mapToDouble(CoughEvent::getAudioVolume)
                .average()
                .orElse(0);

        // Calculate hourly distribution
        List<HourlyDistribution> hourlyDist = calculateHourlyDistribution(events);

        // Calculate day/night split
        Map<String, Integer> dayNightSplit = calculateDayNightSplit(events);
        int nightCoughs = dayNightSplit.get("night");
        int dayCoughs = dayNightSplit.get("day");
        double nightPercentage = (totalCoughs > 0) ? (nightCoughs * 100.0 / totalCoughs) : 0;

        // Find peak hour
        int peakHour = findPeakHour(hourlyDist);

        // Detect patterns
        List<CoughPattern> patterns = detectPatterns(events, hourlyDist, nightPercentage);

        // Vitals summary already calculated at the top of the method

        // Calculate severity (now includes vitals)
        int coughSeverityScore = calculateCoughSeverityScore(totalCoughs, nightPercentage, patterns);
        int vitalsSeverityScore = vitalsSummary.getVitalsSeverityScore();
        int severityScore = calculateCombinedSeverityScore(coughSeverityScore, vitalsSeverityScore);
        String severityLevel = getSeverityLevel(severityScore);
        String healthStatus = getHealthStatus(severityLevel, totalCoughs, vitalsSummary);

        // Generate insights (now includes vitals)
        List<HealthInsight> insights = generateInsights(totalCoughs, nightPercentage, patterns, severityLevel, vitalsSummary);

        // Generate recommendations (now includes vitals)
        List<String> recommendations = generateRecommendations(severityLevel, nightPercentage, totalCoughs, vitalsSummary);

        // Compare with yesterday
        DailyComparison comparison = compareWithYesterday(deviceId, date, totalCoughs);

        // Build response
        response.setTotalCoughs(totalCoughs);
        response.setCoughFrequency(Math.round(totalCoughs / 24.0 * 100.0) / 100.0);
        response.setAvgConfidence(Math.round(avgConfidence * 10.0) / 10.0);
        response.setAvgVolume(Math.round(avgVolume * 100.0) / 100.0);
        response.setNightCoughs(nightCoughs);
        response.setDayCoughs(dayCoughs);
        response.setNightPercentage(Math.round(nightPercentage * 10.0) / 10.0);
        response.setPeakHour(peakHour);
        response.setHourlyDistribution(hourlyDist);
        response.setPatterns(patterns);
        response.setVitalsSummary(vitalsSummary);
        response.setSeverityScore(severityScore);
        response.setSeverityLevel(severityLevel);
        response.setHealthStatus(healthStatus);
        response.setInsights(insights);
        response.setRecommendations(recommendations);
        response.setComparison(comparison);
        response.setHasData(true);
        response.setMessage("Summary generated successfully");

        return response;
    }

    private List<CoughEvent> getCoughEventsForDay(String deviceId, LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();

        return coughRepository.findByDeviceIdAndTimestampBetween(
                deviceId,
                startOfDay,
                endOfDay
        );
    }

    private List<HourlyDistribution> calculateHourlyDistribution(List<CoughEvent> events) {
        Map<Integer, Long> hourCounts = events.stream()
                .collect(Collectors.groupingBy(
                        event -> event.getTimestamp().getHour(),
                        Collectors.counting()
                ));

        List<HourlyDistribution> distribution = new ArrayList<>();
        int total = events.size();

        for (int hour = 0; hour < 24; hour++) {
            int count = hourCounts.getOrDefault(hour, 0L).intValue();
            double percentage = total > 0 ? Math.round(count * 1000.0 / total) / 10.0 : 0;
            distribution.add(new HourlyDistribution(hour, count, percentage));
        }

        return distribution;
    }

    private List<HourlyDistribution> generateEmptyHourlyDistribution() {
        List<HourlyDistribution> distribution = new ArrayList<>();
        for (int hour = 0; hour < 24; hour++) {
            distribution.add(new HourlyDistribution(hour, 0, 0.0));
        }
        return distribution;
    }

    private Map<String, Integer> calculateDayNightSplit(List<CoughEvent> events) {
        int nightCoughs = 0;
        int dayCoughs = 0;

        for (CoughEvent event : events) {
            int hour = event.getTimestamp().getHour();
            if (hour >= 22 || hour < 6) {
                nightCoughs++;
            } else {
                dayCoughs++;
            }
        }

        Map<String, Integer> result = new HashMap<>();
        result.put("night", nightCoughs);
        result.put("day", dayCoughs);
        return result;
    }

    private int findPeakHour(List<HourlyDistribution> hourlyDist) {
        return hourlyDist.stream()
                .max(Comparator.comparingInt(HourlyDistribution::getCount))
                .map(HourlyDistribution::getHour)
                .orElse(0);
    }

    private List<CoughPattern> detectPatterns(List<CoughEvent> events, List<HourlyDistribution> hourlyDist, double nightPercentage) {
        List<CoughPattern> patterns = new ArrayList<>();

        // Pattern 1: Nocturnal pattern (high night coughs)
        if (nightPercentage > 40) {
            patterns.add(new CoughPattern(
                    "NOCTURNAL",
                    String.format("High nocturnal coughing activity (%.1f%% at night)", nightPercentage),
                    Math.min(nightPercentage, 100.0)
            ));
        }

        // Pattern 2: Cluster pattern (multiple consecutive hours with high activity)
        long hoursWithCoughs = hourlyDist.stream().filter(h -> h.getCount() >= 5).count();
        if (hoursWithCoughs >= 3) {
            patterns.add(new CoughPattern(
                    "CLUSTER",
                    String.format("Cough episodes detected in %d different hours", hoursWithCoughs),
                    75.0
            ));
        }

        // Pattern 3: Spike pattern (sudden high activity)
        HourlyDistribution peakHourDist = hourlyDist.stream()
                .max(Comparator.comparingInt(HourlyDistribution::getCount))
                .orElse(null);
        if (peakHourDist != null && peakHourDist.getPercentage() > 30) {
            patterns.add(new CoughPattern(
                    "SPIKE",
                    "Sudden spike in cough frequency detected",
                    70.0
            ));
        }

        return patterns;
    }

    private int calculateCoughSeverityScore(int totalCoughs, double nightPercentage, List<CoughPattern> patterns) {
        double score = 0;

        // Base score from cough count (0-50 points)
        if (totalCoughs < 10) score += 10;
        else if (totalCoughs < 30) score += 25;
        else if (totalCoughs < 50) score += 40;
        else score += 50;

        // Night percentage (0-25 points)
        score += (nightPercentage / 100.0) * 25;

        // Patterns (0-25 points)
        score += patterns.size() * 8.33;

        return Math.min((int) Math.round(score), 100);
    }
    
    private int calculateCombinedSeverityScore(int coughScore, int vitalsScore) {
        // Weight: Cough 50%, Vitals 50% (RR has higher weight within vitals)
        return (int) Math.round((coughScore * 0.5) + (vitalsScore * 0.5));
    }

    private String getSeverityLevel(int score) {
        if (score < 30) return "GOOD";
        else if (score < 50) return "MODERATE";
        else if (score < 70) return "HIGH";
        else return "SEVERE";
    }

    private String getHealthStatus(String level, int totalCoughs, VitalsSummary vitals) {
        StringBuilder status = new StringBuilder();
        
        switch (level) {
            case "GOOD":
                status.append("Health status good");
                break;
            case "MODERATE":
                status.append("Moderate concerns - Continue monitoring");
                break;
            case "HIGH":
                status.append("Elevated concerns - Consider medical consultation");
                break;
            case "SEVERE":
                status.append("Significant concerns - Medical attention recommended");
                break;
            default:
                status.append("Status unknown");
        }
        
        // Add vitals context if available
        if (vitals != null && vitals.isHasVitalsData()) {
            if (vitals.getAnomalies() != null && !vitals.getAnomalies().isEmpty()) {
                long criticalCount = vitals.getAnomalies().stream()
                    .filter(a -> "CRITICAL".equals(a.getSeverity()))
                    .count();
                if (criticalCount > 0) {
                    status.append(" | ").append(criticalCount).append(" critical vital reading(s)");
                }
            }
        }
        
        return status.toString();
    }

    private List<HealthInsight> generateInsights(int totalCoughs, double nightPercentage, List<CoughPattern> patterns, String severityLevel, VitalsSummary vitals) {
        List<HealthInsight> insights = new ArrayList<>();

        // High cough count insight
        if (totalCoughs > 50) {
            insights.add(new HealthInsight(
                    "High Daily Cough Count",
                    "Total cough count exceeds 50 per day, indicating possible respiratory irritation.",
                    "MODERATE",
                    "ALERT"
            ));
        } else if (totalCoughs > 100) {
            insights.add(new HealthInsight(
                    "Very High Cough Frequency",
                    "Cough count above 100 suggests significant respiratory distress. Medical consultation recommended.",
                    "HIGH",
                    "ALERT"
            ));
        }

        // Nocturnal pattern insight
        if (nightPercentage > 50) {
            insights.add(new HealthInsight(
                    "Significant Nocturnal Coughing",
                    "More than half of coughs occur at night, which may disrupt sleep quality.",
                    "MODERATE",
                    "PATTERN"
            ));
        }

        // Cluster pattern insight
        boolean hasCluster = patterns.stream().anyMatch(p -> p.getType().equals("CLUSTER"));
        if (hasCluster) {
            insights.add(new HealthInsight(
                    "Cough Episodes Detected",
                    "Multiple cough clusters throughout the day suggest episodic irritation or allergic response.",
                    "MODERATE",
                    "PATTERN"
            ));
        }

        // Positive insight for low coughs
        if (totalCoughs < 10) {
            insights.add(new HealthInsight(
                    "Low Cough Activity",
                    "Minimal coughing indicates good respiratory health.",
                    "INFO",
                    "POSITIVE"
            ));
        }
        
        // Add vitals-based insights
        if (vitals != null && vitals.isHasVitalsData()) {
            // Heart rate insights
            if (vitals.getHeartRate() != null) {
                String hrStatus = vitals.getHeartRate().getStatus();
                if ("HIGH".equals(hrStatus) || "CRITICAL".equals(hrStatus)) {
                    insights.add(new HealthInsight(
                        "Elevated Heart Rate",
                        String.format("Average heart rate: %.0f bpm - %s", 
                            vitals.getHeartRate().getAverage(),
                            vitals.getHeartRate().getStatusMessage()),
                        hrStatus.equals("CRITICAL") ? "HIGH" : "MODERATE",
                        "VITAL"
                    ));
                } else if ("LOW".equals(hrStatus)) {
                    insights.add(new HealthInsight(
                        "Low Heart Rate",
                        String.format("Average heart rate: %.0f bpm - %s", 
                            vitals.getHeartRate().getAverage(),
                            vitals.getHeartRate().getStatusMessage()),
                        "MODERATE",
                        "VITAL"
                    ));
                }
            }
            
            // Temperature insights
            if (vitals.getTemperature() != null) {
                String tempStatus = vitals.getTemperature().getStatus();
                double avgTemp = vitals.getTemperature().getAverage();
                
                if ("HIGH".equals(tempStatus)) {
                    insights.add(new HealthInsight(
                        "Elevated Temperature",
                        String.format("Average temperature: %.1f°C - %s", 
                            avgTemp,
                            vitals.getTemperature().getStatusMessage()),
                        "MODERATE",
                        "VITAL"
                    ));
                } else if ("CRITICAL".equals(tempStatus)) {
                    // Distinguish between high fever and hypothermia
                    if (avgTemp >= TEMP_HIGH_FEVER) {
                        insights.add(new HealthInsight(
                            "High Fever Detected",
                            String.format("Temperature reached %.1f°C - Immediate attention recommended", 
                                vitals.getTemperature().getMax()),
                            "HIGH",
                            "VITAL"
                        ));
                    } else if (avgTemp <= TEMP_HYPOTHERMIA) {
                        insights.add(new HealthInsight(
                            "Hypothermia Risk Detected",
                            String.format("Temperature dropped to %.1f°C - Immediate warming needed", 
                                vitals.getTemperature().getMin()),
                            "HIGH",
                            "VITAL"
                        ));
                    }
                } else if ("LOW".equals(tempStatus)) {
                    insights.add(new HealthInsight(
                        "Below Normal Temperature",
                        String.format("Average temperature: %.1f°C - Monitor for hypothermia", 
                            avgTemp),
                        "MODERATE",
                        "VITAL"
                    ));
                }
            }
            
            // Respiratory rate insights (higher priority for respiratory system)
            if (vitals.getRespiratoryRate() != null) {
                String rrStatus = vitals.getRespiratoryRate().getStatus();
                if ("HIGH".equals(rrStatus) || "CRITICAL".equals(rrStatus)) {
                    insights.add(new HealthInsight(
                        "Abnormal Breathing Rate",
                        String.format("Average respiratory rate: %.0f breaths/min - %s. This is significant for respiratory health.", 
                            vitals.getRespiratoryRate().getAverage(),
                            vitals.getRespiratoryRate().getStatusMessage()),
                        "HIGH",
                        "VITAL"
                    ));
                } else if ("LOW".equals(rrStatus)) {
                    insights.add(new HealthInsight(
                        "Low Respiratory Rate",
                        String.format("Average respiratory rate: %.0f breaths/min - Monitor for respiratory depression", 
                            vitals.getRespiratoryRate().getAverage()),
                        "HIGH",
                        "VITAL"
                    ));
                }
            }
            
            // Combined cough + fever insight
            if (totalCoughs > 30 && vitals.getTemperature() != null && 
                vitals.getTemperature().getAverage() >= TEMP_FEVER) {
                insights.add(new HealthInsight(
                    "Cough with Fever",
                    "Combination of frequent coughing and elevated temperature may indicate infection. Medical consultation advised.",
                    "HIGH",
                    "COMBINED"
                ));
            }
        }

        return insights;
    }

    private List<String> generateRecommendations(String severityLevel, double nightPercentage, int totalCoughs, VitalsSummary vitals) {
        List<String> recommendations = new ArrayList<>();

        switch (severityLevel) {
            case "GOOD":
                recommendations.add("Maintain current health practices");
                recommendations.add("Continue regular monitoring");
                break;
            case "MODERATE":
                recommendations.add("Stay well hydrated throughout the day");
                recommendations.add("Avoid known irritants (smoke, dust, strong odors)");
                recommendations.add("Continue monitoring your symptoms");
                recommendations.add("Keep a diary of potential triggers (food, environment)");
                break;
            case "HIGH":
                recommendations.add("Consider scheduling a medical consultation");
                recommendations.add("Monitor for additional symptoms (fever, shortness of breath)");
                recommendations.add("Ensure proper indoor air quality");
                recommendations.add("Avoid strenuous physical activity if coughing worsens");
                break;
            case "SEVERE":
                recommendations.add("Seek medical attention as soon as possible");
                recommendations.add("Monitor oxygen levels if equipment available");
                recommendations.add("Rest and avoid physical exertion");
                recommendations.add("Keep emergency contacts readily available");
                break;
        }

        // Night-specific recommendations
        if (nightPercentage > 40) {
            recommendations.add("Elevate your head while sleeping");
            recommendations.add("Use a humidifier in your bedroom");
            recommendations.add("Avoid eating 2-3 hours before bedtime");
        }
        
        // Vitals-specific recommendations
        if (vitals != null && vitals.isHasVitalsData()) {
            // Fever recommendations
            if (vitals.getTemperature() != null && vitals.getTemperature().getAverage() >= TEMP_FEVER) {
                recommendations.add("Monitor temperature regularly");
                recommendations.add("Stay well-rested and keep hydrated");
                if (vitals.getTemperature().getMax() >= TEMP_HIGH_FEVER) {
                    recommendations.add("Consider fever-reducing medication after consulting healthcare provider");
                }
            }
            
            // Respiratory rate recommendations (high priority)
            if (vitals.getRespiratoryRate() != null) {
                if (vitals.getRespiratoryRate().getAverage() >= RR_TACHYPNEA) {
                    recommendations.add("Practice slow, deep breathing exercises");
                    recommendations.add("Avoid triggers that may increase breathing rate");
                }
                if (vitals.getRespiratoryRate().getAverage() <= RR_DEPRESSION) {
                    recommendations.add("Monitor breathing closely - seek immediate medical attention if worsens");
                }
            }
            
            // Heart rate recommendations
            if (vitals.getHeartRate() != null) {
                if (vitals.getHeartRate().getAverage() >= HR_TACHYCARDIA) {
                    recommendations.add("Avoid caffeine and stimulants");
                    recommendations.add("Practice relaxation techniques");
                }
            }
        }

        return recommendations;
    }

    private DailyComparison compareWithYesterday(String deviceId, LocalDate date, int todayCoughs) {
        LocalDate yesterday = date.minusDays(1);
        List<CoughEvent> yesterdayEvents = getCoughEventsForDay(deviceId, yesterday);
        int yesterdayCoughs = yesterdayEvents.size();

        int change = todayCoughs - yesterdayCoughs;
        double percentageChange = yesterdayCoughs > 0
                ? Math.round((change * 100.0 / yesterdayCoughs) * 10.0) / 10.0
                : 0.0;

        String trend;
        if (change > 0) trend = "INCREASING";
        else if (change < 0) trend = "DECREASING";
        else trend = "STABLE";

        return new DailyComparison(yesterdayCoughs, change, percentageChange, trend);
    }
    
    // ==================== VITALS CALCULATION METHODS ====================
    
    private VitalsSummary calculateVitalsSummary(String deviceId, LocalDate date) {
        VitalsSummary summary = new VitalsSummary();
        
        // Get vitals for the day
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();
        List<VitalsEvent> vitalsEvents = vitalsRepository.findByDeviceIdAndCreatedAtBetween(
                deviceId, startOfDay, endOfDay);
        
        if (vitalsEvents.isEmpty()) {
            summary.setHasVitalsData(false);
            summary.setVitalsMessage("No vitals recorded for this date");
            summary.setTotalReadings(0);
            summary.setHeartRate(createEmptySingleVitalSummary("Heart Rate"));
            summary.setTemperature(createEmptySingleVitalSummary("Temperature"));
            summary.setRespiratoryRate(createEmptySingleVitalSummary("Respiratory Rate"));
            summary.setHourlyVitals(generateEmptyHourlyVitals());
            summary.setAnomalies(new ArrayList<>());
            summary.setVitalsSeverityScore(0);
            summary.setVitalsStatus("No vitals data");
            return summary;
        }
        
        summary.setHasVitalsData(true);
        summary.setTotalReadings(vitalsEvents.size());
        
        // Calculate individual vital summaries
        summary.setHeartRate(calculateHeartRateSummary(vitalsEvents));
        summary.setTemperature(calculateTemperatureSummary(vitalsEvents));
        summary.setRespiratoryRate(calculateRespiratoryRateSummary(vitalsEvents));
        
        // Generate hourly data for combined chart
        summary.setHourlyVitals(calculateHourlyVitals(vitalsEvents));
        
        // Detect anomalies
        List<VitalsAnomaly> anomalies = detectVitalsAnomalies(vitalsEvents);
        summary.setAnomalies(anomalies);
        
        // Calculate vitals severity score
        int vitalsScore = calculateVitalsSeverityScore(summary);
        summary.setVitalsSeverityScore(vitalsScore);
        summary.setVitalsStatus(getVitalsStatus(summary));
        summary.setVitalsMessage(String.format("%d readings recorded", vitalsEvents.size()));
        
        return summary;
    }
    
    private SingleVitalSummary createEmptySingleVitalSummary(String vitalName) {
        return new SingleVitalSummary(0, 0, 0, "UNKNOWN", "No " + vitalName.toLowerCase() + " data", 0, 0);
    }
    
    private SingleVitalSummary calculateHeartRateSummary(List<VitalsEvent> events) {
        // Filter out invalid readings (leads off)
        List<VitalsEvent> validEvents = events.stream()
                .filter(e -> !e.isLeadsOff() && e.getBpm() > 0)
                .collect(Collectors.toList());
        
        if (validEvents.isEmpty()) {
            return new SingleVitalSummary(0, 0, 0, "UNKNOWN", "No valid heart rate readings (leads off)", 0, 0);
        }
        
        double avg = validEvents.stream().mapToDouble(VitalsEvent::getBpm).average().orElse(0);
        double min = validEvents.stream().mapToDouble(VitalsEvent::getBpm).min().orElse(0);
        double max = validEvents.stream().mapToDouble(VitalsEvent::getBpm).max().orElse(0);
        
        // Determine status based on average
        String status;
        String statusMessage;
        int anomalyCount = 0;
        
        if (avg < HR_BRADYCARDIA) {
            status = "CRITICAL";
            statusMessage = "Bradycardia detected - heart rate very low";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getBpm() < HR_BRADYCARDIA).count();
        } else if (avg < HR_NORMAL_MIN) {
            status = "LOW";
            statusMessage = "Below normal range";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getBpm() < HR_NORMAL_MIN).count();
        } else if (avg > HR_TACHYCARDIA) {
            status = "CRITICAL";
            statusMessage = "Tachycardia detected - heart rate very high";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getBpm() > HR_TACHYCARDIA).count();
        } else if (avg > HR_NORMAL_MAX) {
            status = "HIGH";
            statusMessage = "Above normal range";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getBpm() > HR_NORMAL_MAX).count();
        } else {
            status = "NORMAL";
            statusMessage = "Within normal range (60-100 bpm)";
        }
        
        return new SingleVitalSummary(
                Math.round(avg * 10.0) / 10.0,
                Math.round(min * 10.0) / 10.0,
                Math.round(max * 10.0) / 10.0,
                status,
                statusMessage,
                validEvents.size(),
                anomalyCount
        );
    }
    
    private SingleVitalSummary calculateTemperatureSummary(List<VitalsEvent> events) {
        List<VitalsEvent> validEvents = events.stream()
                .filter(e -> e.getTemp() > 30 && e.getTemp() < 45) // Filter unrealistic readings
                .collect(Collectors.toList());
        
        if (validEvents.isEmpty()) {
            return new SingleVitalSummary(0, 0, 0, "UNKNOWN", "No valid temperature readings", 0, 0);
        }
        
        double avg = validEvents.stream().mapToDouble(VitalsEvent::getTemp).average().orElse(0);
        double min = validEvents.stream().mapToDouble(VitalsEvent::getTemp).min().orElse(0);
        double max = validEvents.stream().mapToDouble(VitalsEvent::getTemp).max().orElse(0);
        
        String status;
        String statusMessage;
        int anomalyCount = 0;
        
        if (avg >= TEMP_HIGH_FEVER) {
            status = "CRITICAL";
            statusMessage = "High fever - immediate attention needed";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getTemp() >= TEMP_HIGH_FEVER).count();
        } else if (avg >= TEMP_FEVER) {
            status = "HIGH";
            statusMessage = "Fever detected";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getTemp() >= TEMP_FEVER).count();
        } else if (avg <= TEMP_HYPOTHERMIA) {
            status = "CRITICAL";
            statusMessage = "Hypothermia risk - temperature very low";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getTemp() <= TEMP_HYPOTHERMIA).count();
        } else if (avg < TEMP_NORMAL_MIN) {
            status = "LOW";
            statusMessage = "Below normal range";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getTemp() < TEMP_NORMAL_MIN).count();
        } else if (avg > TEMP_NORMAL_MAX) {
            status = "HIGH";
            statusMessage = "Slightly elevated";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getTemp() > TEMP_NORMAL_MAX).count();
        } else {
            status = "NORMAL";
            statusMessage = "Within normal range (36.1-37.5°C)";
        }
        
        return new SingleVitalSummary(
                Math.round(avg * 10.0) / 10.0,
                Math.round(min * 10.0) / 10.0,
                Math.round(max * 10.0) / 10.0,
                status,
                statusMessage,
                validEvents.size(),
                anomalyCount
        );
    }
    
    private SingleVitalSummary calculateRespiratoryRateSummary(List<VitalsEvent> events) {
        List<VitalsEvent> validEvents = events.stream()
                .filter(e -> e.getRr() > 0 && e.getRr() < 60) // Filter unrealistic readings
                .collect(Collectors.toList());
        
        if (validEvents.isEmpty()) {
            return new SingleVitalSummary(0, 0, 0, "UNKNOWN", "No valid respiratory rate readings", 0, 0);
        }
        
        double avg = validEvents.stream().mapToDouble(VitalsEvent::getRr).average().orElse(0);
        double min = validEvents.stream().mapToDouble(VitalsEvent::getRr).min().orElse(0);
        double max = validEvents.stream().mapToDouble(VitalsEvent::getRr).max().orElse(0);
        
        String status;
        String statusMessage;
        int anomalyCount = 0;
        
        if (avg >= RR_TACHYPNEA) {
            status = "CRITICAL";
            statusMessage = "Tachypnea - rapid breathing detected";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getRr() >= RR_TACHYPNEA).count();
        } else if (avg > RR_NORMAL_MAX) {
            status = "HIGH";
            statusMessage = "Elevated breathing rate";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getRr() > RR_NORMAL_MAX).count();
        } else if (avg <= RR_DEPRESSION) {
            status = "CRITICAL";
            statusMessage = "Respiratory depression - breathing rate very low";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getRr() <= RR_DEPRESSION).count();
        } else if (avg < RR_NORMAL_MIN) {
            status = "LOW";
            statusMessage = "Below normal range";
            anomalyCount = (int) validEvents.stream().filter(e -> e.getRr() < RR_NORMAL_MIN).count();
        } else {
            status = "NORMAL";
            statusMessage = "Within normal range (12-20 breaths/min)";
        }
        
        return new SingleVitalSummary(
                Math.round(avg * 10.0) / 10.0,
                Math.round(min * 10.0) / 10.0,
                Math.round(max * 10.0) / 10.0,
                status,
                statusMessage,
                validEvents.size(),
                anomalyCount
        );
    }
    
    private List<VitalsHourlyData> calculateHourlyVitals(List<VitalsEvent> events) {
        Map<Integer, List<VitalsEvent>> hourlyGroups = events.stream()
                .filter(e -> e.getCreatedAt() != null)
                .collect(Collectors.groupingBy(e -> e.getCreatedAt().getHour()));
        
        List<VitalsHourlyData> hourlyData = new ArrayList<>();
        
        for (int hour = 0; hour < 24; hour++) {
            List<VitalsEvent> hourEvents = hourlyGroups.getOrDefault(hour, new ArrayList<>());
            
            if (hourEvents.isEmpty()) {
                hourlyData.add(new VitalsHourlyData(hour, null, null, null, 0));
            } else {
                Double avgHR = hourEvents.stream()
                        .filter(e -> !e.isLeadsOff() && e.getBpm() > 0)
                        .mapToDouble(VitalsEvent::getBpm)
                        .average()
                        .orElse(Double.NaN);
                
                Double avgTemp = hourEvents.stream()
                        .filter(e -> e.getTemp() > 30 && e.getTemp() < 45)
                        .mapToDouble(VitalsEvent::getTemp)
                        .average()
                        .orElse(Double.NaN);
                
                Double avgRR = hourEvents.stream()
                        .filter(e -> e.getRr() > 0 && e.getRr() < 60)
                        .mapToDouble(VitalsEvent::getRr)
                        .average()
                        .orElse(Double.NaN);
                
                hourlyData.add(new VitalsHourlyData(
                        hour,
                        Double.isNaN(avgHR) ? null : Math.round(avgHR * 10.0) / 10.0,
                        Double.isNaN(avgTemp) ? null : Math.round(avgTemp * 10.0) / 10.0,
                        Double.isNaN(avgRR) ? null : Math.round(avgRR * 10.0) / 10.0,
                        hourEvents.size()
                ));
            }
        }
        
        return hourlyData;
    }
    
    private List<VitalsHourlyData> generateEmptyHourlyVitals() {
        List<VitalsHourlyData> hourlyData = new ArrayList<>();
        for (int hour = 0; hour < 24; hour++) {
            hourlyData.add(new VitalsHourlyData(hour, null, null, null, 0));
        }
        return hourlyData;
    }
    
    private List<VitalsAnomaly> detectVitalsAnomalies(List<VitalsEvent> events) {
        List<VitalsAnomaly> anomalies = new ArrayList<>();
        DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm");
        
        for (VitalsEvent event : events) {
            if (event.getCreatedAt() == null) continue;
            String timestamp = event.getCreatedAt().format(timeFormatter);
            
            // Heart rate anomalies
            if (!event.isLeadsOff() && event.getBpm() > 0) {
                if (event.getBpm() < HR_BRADYCARDIA) {
                    anomalies.add(new VitalsAnomaly(
                            "HEART_RATE",
                            "WARNING",
                            "Bradycardia",
                            event.getBpm(),
                            timestamp,
                            String.format("Heart rate dropped to %.0f bpm", event.getBpm())
                    ));
                } else if (event.getBpm() > HR_TACHYCARDIA) {
                    anomalies.add(new VitalsAnomaly(
                            "HEART_RATE",
                            "WARNING",
                            "Tachycardia",
                            event.getBpm(),
                            timestamp,
                            String.format("Heart rate elevated to %.0f bpm", event.getBpm())
                    ));
                }
            }
            
            // Temperature anomalies
            if (event.getTemp() > 30 && event.getTemp() < 45) {
                if (event.getTemp() >= TEMP_HIGH_FEVER) {
                    anomalies.add(new VitalsAnomaly(
                            "TEMPERATURE",
                            "CRITICAL",
                            "High Fever",
                            event.getTemp(),
                            timestamp,
                            String.format("Temperature reached %.1f°C", event.getTemp())
                    ));
                } else if (event.getTemp() >= TEMP_FEVER) {
                    anomalies.add(new VitalsAnomaly(
                            "TEMPERATURE",
                            "WARNING",
                            "Fever",
                            event.getTemp(),
                            timestamp,
                            String.format("Elevated temperature: %.1f°C", event.getTemp())
                    ));
                } else if (event.getTemp() <= TEMP_HYPOTHERMIA) {
                    anomalies.add(new VitalsAnomaly(
                            "TEMPERATURE",
                            "CRITICAL",
                            "Hypothermia",
                            event.getTemp(),
                            timestamp,
                            String.format("Low temperature: %.1f°C", event.getTemp())
                    ));
                }
            }
            
            // Respiratory rate anomalies (higher priority)
            if (event.getRr() > 0 && event.getRr() < 60) {
                if (event.getRr() >= RR_TACHYPNEA) {
                    anomalies.add(new VitalsAnomaly(
                            "RESPIRATORY_RATE",
                            "CRITICAL",
                            "Tachypnea",
                            event.getRr(),
                            timestamp,
                            String.format("Rapid breathing: %.0f breaths/min", event.getRr())
                    ));
                } else if (event.getRr() <= RR_DEPRESSION) {
                    anomalies.add(new VitalsAnomaly(
                            "RESPIRATORY_RATE",
                            "CRITICAL",
                            "Respiratory Depression",
                            event.getRr(),
                            timestamp,
                            String.format("Very slow breathing: %.0f breaths/min", event.getRr())
                    ));
                }
            }
        }
        
        // Limit anomalies to most significant ones (avoid flooding)
        if (anomalies.size() > 20) {
            // Prioritize CRITICAL over WARNING, and RR over others
            anomalies.sort((a, b) -> {
                int severityCompare = b.getSeverity().compareTo(a.getSeverity());
                if (severityCompare != 0) return severityCompare;
                // Prioritize respiratory rate
                if (a.getType().equals("RESPIRATORY_RATE") && !b.getType().equals("RESPIRATORY_RATE")) return -1;
                if (!a.getType().equals("RESPIRATORY_RATE") && b.getType().equals("RESPIRATORY_RATE")) return 1;
                return 0;
            });
            anomalies = anomalies.subList(0, 20);
        }
        
        return anomalies;
    }
    
    private int calculateVitalsSeverityScore(VitalsSummary summary) {
        double score = 0;
        
        // Heart rate contribution (0-25 points)
        if (summary.getHeartRate() != null && !"UNKNOWN".equals(summary.getHeartRate().getStatus())) {
            switch (summary.getHeartRate().getStatus()) {
                case "NORMAL": score += 5; break;
                case "LOW": case "HIGH": score += 15; break;
                case "CRITICAL": score += 25; break;
            }
        }
        
        // Temperature contribution (0-25 points)
        if (summary.getTemperature() != null && !"UNKNOWN".equals(summary.getTemperature().getStatus())) {
            switch (summary.getTemperature().getStatus()) {
                case "NORMAL": score += 5; break;
                case "LOW": case "HIGH": score += 15; break;
                case "CRITICAL": score += 25; break;
            }
        }
        
        // Respiratory rate contribution (0-50 points) - HIGHER WEIGHT for respiratory system
        if (summary.getRespiratoryRate() != null && !"UNKNOWN".equals(summary.getRespiratoryRate().getStatus())) {
            switch (summary.getRespiratoryRate().getStatus()) {
                case "NORMAL": score += 10; break;
                case "LOW": case "HIGH": score += 30; break;
                case "CRITICAL": score += 50; break;
            }
        }
        
        return Math.min((int) Math.round(score), 100);
    }
    
    private String getVitalsStatus(VitalsSummary summary) {
        int score = summary.getVitalsSeverityScore();
        
        boolean hasCritical = (summary.getHeartRate() != null && "CRITICAL".equals(summary.getHeartRate().getStatus())) ||
                             (summary.getTemperature() != null && "CRITICAL".equals(summary.getTemperature().getStatus())) ||
                             (summary.getRespiratoryRate() != null && "CRITICAL".equals(summary.getRespiratoryRate().getStatus()));
        
        if (hasCritical) {
            return "Critical vital signs detected - Medical attention recommended";
        } else if (score < 30) {
            return "Vitals within normal range";
        } else if (score < 50) {
            return "Some vital signs slightly elevated - Continue monitoring";
        } else if (score < 70) {
            return "Elevated vital signs - Consider medical consultation";
        } else {
            return "Significant vital sign abnormalities - Seek medical attention";
        }
    }
    
    private List<HealthInsight> generateVitalsOnlyInsights(VitalsSummary vitals) {
        List<HealthInsight> insights = new ArrayList<>();
        
        if (vitals == null || !vitals.isHasVitalsData()) {
            return insights;
        }
        
        // Add vitals-based insights
        if (vitals.getHeartRate() != null && !"NORMAL".equals(vitals.getHeartRate().getStatus()) 
            && !"UNKNOWN".equals(vitals.getHeartRate().getStatus())) {
            insights.add(new HealthInsight(
                    vitals.getHeartRate().getStatus().equals("CRITICAL") ? "Critical Heart Rate" : "Abnormal Heart Rate",
                    vitals.getHeartRate().getStatusMessage(),
                    vitals.getHeartRate().getStatus().equals("CRITICAL") ? "HIGH" : "MODERATE",
                    "VITAL"
            ));
        }
        
        if (vitals.getTemperature() != null && !"NORMAL".equals(vitals.getTemperature().getStatus())
            && !"UNKNOWN".equals(vitals.getTemperature().getStatus())) {
            insights.add(new HealthInsight(
                    vitals.getTemperature().getStatus().equals("CRITICAL") ? "Critical Temperature" : "Abnormal Temperature",
                    vitals.getTemperature().getStatusMessage(),
                    vitals.getTemperature().getStatus().equals("CRITICAL") ? "HIGH" : "MODERATE",
                    "VITAL"
            ));
        }
        
        if (vitals.getRespiratoryRate() != null && !"NORMAL".equals(vitals.getRespiratoryRate().getStatus())
            && !"UNKNOWN".equals(vitals.getRespiratoryRate().getStatus())) {
            insights.add(new HealthInsight(
                    vitals.getRespiratoryRate().getStatus().equals("CRITICAL") ? "Critical Respiratory Rate" : "Abnormal Respiratory Rate",
                    vitals.getRespiratoryRate().getStatusMessage(),
                    "HIGH", // Always high priority for respiratory
                    "VITAL"
            ));
        }
        
        if (insights.isEmpty() && vitals.isHasVitalsData()) {
            insights.add(new HealthInsight(
                    "Vitals Normal",
                    "All vital signs are within normal range",
                    "INFO",
                    "POSITIVE"
            ));
        }
        
        return insights;
    }
    
    private List<String> generateVitalsOnlyRecommendations(VitalsSummary vitals) {
        List<String> recommendations = new ArrayList<>();
        
        if (vitals == null || !vitals.isHasVitalsData()) {
            recommendations.add("Ensure device is worn properly to record vitals");
            return recommendations;
        }
        
        boolean hasIssues = false;
        
        if (vitals.getTemperature() != null && 
            ("HIGH".equals(vitals.getTemperature().getStatus()) || "CRITICAL".equals(vitals.getTemperature().getStatus()))) {
            recommendations.add("Monitor temperature regularly");
            recommendations.add("Stay hydrated and rest");
            hasIssues = true;
        }
        
        if (vitals.getRespiratoryRate() != null && 
            ("HIGH".equals(vitals.getRespiratoryRate().getStatus()) || "CRITICAL".equals(vitals.getRespiratoryRate().getStatus()))) {
            recommendations.add("Practice calm, controlled breathing");
            recommendations.add("Avoid physical exertion");
            hasIssues = true;
        }
        
        if (vitals.getHeartRate() != null && 
            ("HIGH".equals(vitals.getHeartRate().getStatus()) || "CRITICAL".equals(vitals.getHeartRate().getStatus()))) {
            recommendations.add("Rest and avoid stimulants");
            hasIssues = true;
        }
        
        if (!hasIssues) {
            recommendations.add("Continue regular monitoring");
            recommendations.add("Maintain healthy lifestyle habits");
        }
        
        return recommendations;
    }
}
