package service;

import dto.*;
import model.CoughEvent;
import model.FallEvent;
import model.VitalsEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import repository.CoughRepository;
import repository.FallRepository;
import repository.VitalsRepository;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;
import java.util.Arrays;

@Service
public class SummaryService {

    @Autowired
    private CoughRepository coughRepository;

    @Autowired
    private VitalsRepository vitalsRepository;

    @Autowired
    private FallRepository fallRepository;

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

        // Calculate fall events summary
        FallEventsSummary fallEventsSummary = calculateFallEventsSummary(deviceId, date);

        if (events.isEmpty()) {
            boolean hasAnyData = vitalsSummary.isHasVitalsData() || fallEventsSummary.isHasFallData();
            response.setHasData(hasAnyData);
            if (vitalsSummary.isHasVitalsData() && fallEventsSummary.isHasFallData()) {
                response.setMessage("No cough data, but vitals and fall events recorded");
            } else if (vitalsSummary.isHasVitalsData()) {
                response.setMessage("No cough data, but vitals recorded");
            } else if (fallEventsSummary.isHasFallData()) {
                response.setMessage("No cough data, but fall events recorded");
            } else {
                response.setMessage("No cough or vitals data available for this date");
            }
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
            response.setFallEventsSummary(fallEventsSummary);
            response.setSeverityScore(vitalsSummary.getVitalsSeverityScore());
            response.setSeverityLevel(getSeverityLevel(vitalsSummary.getVitalsSeverityScore()));
            response.setHealthStatus(vitalsSummary.isHasVitalsData()
                    ? vitalsSummary.getVitalsStatus()
                    : fallEventsSummary.isHasFallData() ? "Fall Events Recorded" : "No data");
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
        response.setFallEventsSummary(fallEventsSummary);
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
        if (totalCoughs < 10) {
            score += 10; 
        }else if (totalCoughs < 30) {
            score += 25; 
        }else if (totalCoughs < 50) {
            score += 40; 
        }else {
            score += 50;
        }

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
        if (score < 30) {
            return "GOOD"; 
        }else if (score < 50) {
            return "MODERATE"; 
        }else if (score < 70) {
            return "HIGH"; 
        }else {
            return "SEVERE";
        }
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
            if (totalCoughs > 30 && vitals.getTemperature() != null
                    && vitals.getTemperature().getAverage() >= TEMP_FEVER) {
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
        if (change > 0) {
            trend = "INCREASING"; 
        }else if (change < 0) {
            trend = "DECREASING"; 
        }else {
            trend = "STABLE";
        }

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
            if (event.getCreatedAt() == null) {
                continue;
            }
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
                if (severityCompare != 0) {
                    return severityCompare;
                }
                // Prioritize respiratory rate
                if (a.getType().equals("RESPIRATORY_RATE") && !b.getType().equals("RESPIRATORY_RATE")) {
                    return -1;
                }
                if (!a.getType().equals("RESPIRATORY_RATE") && b.getType().equals("RESPIRATORY_RATE")) {
                    return 1;
                }
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
                case "NORMAL":
                    score += 5;
                    break;
                case "LOW":
                case "HIGH":
                    score += 15;
                    break;
                case "CRITICAL":
                    score += 25;
                    break;
            }
        }

        // Temperature contribution (0-25 points)
        if (summary.getTemperature() != null && !"UNKNOWN".equals(summary.getTemperature().getStatus())) {
            switch (summary.getTemperature().getStatus()) {
                case "NORMAL":
                    score += 5;
                    break;
                case "LOW":
                case "HIGH":
                    score += 15;
                    break;
                case "CRITICAL":
                    score += 25;
                    break;
            }
        }

        // Respiratory rate contribution (0-50 points) - HIGHER WEIGHT for respiratory system
        if (summary.getRespiratoryRate() != null && !"UNKNOWN".equals(summary.getRespiratoryRate().getStatus())) {
            switch (summary.getRespiratoryRate().getStatus()) {
                case "NORMAL":
                    score += 10;
                    break;
                case "LOW":
                case "HIGH":
                    score += 30;
                    break;
                case "CRITICAL":
                    score += 50;
                    break;
            }
        }

        return Math.min((int) Math.round(score), 100);
    }

    private String getVitalsStatus(VitalsSummary summary) {
        int score = summary.getVitalsSeverityScore();

        boolean hasCritical = (summary.getHeartRate() != null && "CRITICAL".equals(summary.getHeartRate().getStatus()))
                || (summary.getTemperature() != null && "CRITICAL".equals(summary.getTemperature().getStatus()))
                || (summary.getRespiratoryRate() != null && "CRITICAL".equals(summary.getRespiratoryRate().getStatus()));

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

        if (vitals.getTemperature() != null
                && ("HIGH".equals(vitals.getTemperature().getStatus()) || "CRITICAL".equals(vitals.getTemperature().getStatus()))) {
            recommendations.add("Monitor temperature regularly");
            recommendations.add("Stay hydrated and rest");
            hasIssues = true;
        }

        if (vitals.getRespiratoryRate() != null
                && ("HIGH".equals(vitals.getRespiratoryRate().getStatus()) || "CRITICAL".equals(vitals.getRespiratoryRate().getStatus()))) {
            recommendations.add("Practice calm, controlled breathing");
            recommendations.add("Avoid physical exertion");
            hasIssues = true;
        }

        if (vitals.getHeartRate() != null
                && ("HIGH".equals(vitals.getHeartRate().getStatus()) || "CRITICAL".equals(vitals.getHeartRate().getStatus()))) {
            recommendations.add("Rest and avoid stimulants");
            hasIssues = true;
        }

        if (!hasIssues) {
            recommendations.add("Continue regular monitoring");
            recommendations.add("Maintain healthy lifestyle habits");
        }

        return recommendations;
    }

    // ==================== WEEKLY SUMMARY METHODS ====================
    public WeeklySummaryResponse generateWeeklySummary(String deviceId, LocalDate weekStart) {
        WeeklySummaryResponse response = new WeeklySummaryResponse();
        LocalDate weekEnd = weekStart.plusDays(6);

        response.setWeekStart(weekStart.format(DATE_FORMATTER));
        response.setWeekEnd(weekEnd.format(DATE_FORMATTER));
        response.setDeviceId(deviceId);

        // Day names for reference
        String[] dayNames = {"Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"};

        // Collect data for each day of the week
        List<DailyBreakdown> dailyBreakdowns = new ArrayList<>();
        List<Double> dailyHeartRateAverages = new ArrayList<>();
        List<Double> dailyTemperatureAverages = new ArrayList<>();
        List<Double> dailyRespiratoryRateAverages = new ArrayList<>();

        int totalCoughs = 0;
        int totalDayCoughs = 0;
        int totalNightCoughs = 0;
        int daysWithData = 0;
        int daysWithVitalsData = 0;
        int totalVitalsReadings = 0;

        // Weekly vitals aggregation
        List<Double> allHeartRates = new ArrayList<>();
        List<Double> allTemperatures = new ArrayList<>();
        List<Double> allRespiratoryRates = new ArrayList<>();
        List<VitalsAnomaly> allAnomalies = new ArrayList<>();

        int peakDayIndex = 0;
        int peakDayCoughs = 0;
        int lowestDayIndex = 0;
        int lowestDayCoughs = Integer.MAX_VALUE;
        boolean firstDayWithData = true;

        // Process each day
        for (int i = 0; i < 7; i++) {
            LocalDate currentDate = weekStart.plusDays(i);
            String dayName = dayNames[i];

            // Get cough events for this day
            List<CoughEvent> dayEvents = getCoughEventsForDay(deviceId, currentDate);

            // Get vitals for this day
            LocalDateTime startOfDay = currentDate.atStartOfDay();
            LocalDateTime endOfDay = currentDate.plusDays(1).atStartOfDay();
            List<VitalsEvent> dayVitals = vitalsRepository.findByDeviceIdAndCreatedAtBetween(
                    deviceId, startOfDay, endOfDay);

            DailyBreakdown breakdown = new DailyBreakdown();
            breakdown.setDate(currentDate.format(DATE_FORMATTER));
            breakdown.setDayName(dayName);
            breakdown.setDayIndex(i);

            int dayCoughs = dayEvents.size();
            breakdown.setTotalCoughs(dayCoughs);
            breakdown.setHasData(!dayEvents.isEmpty() || !dayVitals.isEmpty());

            if (!dayEvents.isEmpty()) {
                daysWithData++;
                totalCoughs += dayCoughs;

                // Calculate day/night split
                Map<String, Integer> dayNightSplit = calculateDayNightSplit(dayEvents);
                int nightCoughs = dayNightSplit.get("night");
                int dayTimeCoughs = dayNightSplit.get("day");

                breakdown.setDayCoughs(dayTimeCoughs);
                breakdown.setNightCoughs(nightCoughs);
                breakdown.setNightPercentage(dayCoughs > 0 ? Math.round(nightCoughs * 1000.0 / dayCoughs) / 10.0 : 0);

                totalDayCoughs += dayTimeCoughs;
                totalNightCoughs += nightCoughs;

                // Track peak and lowest days
                if (dayCoughs > peakDayCoughs) {
                    peakDayCoughs = dayCoughs;
                    peakDayIndex = i;
                }
                if (dayCoughs < lowestDayCoughs) {
                    lowestDayCoughs = dayCoughs;
                    lowestDayIndex = i;
                }

                // Calculate daily severity
                int dailySeverity = calculateCoughSeverityScore(dayCoughs, breakdown.getNightPercentage(), new ArrayList<>());
                breakdown.setSeverityLevel(getSeverityLevel(dailySeverity));
            } else {
                breakdown.setDayCoughs(0);
                breakdown.setNightCoughs(0);
                breakdown.setNightPercentage(0);
                breakdown.setSeverityLevel("GOOD");
            }

            // Process vitals for this day
            if (!dayVitals.isEmpty()) {
                daysWithVitalsData++;
                totalVitalsReadings += dayVitals.size();

                // Heart rate
                List<VitalsEvent> validHREvents = dayVitals.stream()
                        .filter(e -> !e.isLeadsOff() && e.getBpm() > 0)
                        .collect(Collectors.toList());
                if (!validHREvents.isEmpty()) {
                    double avgHR = validHREvents.stream().mapToDouble(VitalsEvent::getBpm).average().orElse(0);
                    breakdown.setAvgHeartRate(Math.round(avgHR * 10.0) / 10.0);
                    dailyHeartRateAverages.add(avgHR);
                    validHREvents.forEach(e -> allHeartRates.add((double) e.getBpm()));
                } else {
                    dailyHeartRateAverages.add(null);
                }

                // Temperature
                List<VitalsEvent> validTempEvents = dayVitals.stream()
                        .filter(e -> e.getTemp() > 30 && e.getTemp() < 45)
                        .collect(Collectors.toList());
                if (!validTempEvents.isEmpty()) {
                    double avgTemp = validTempEvents.stream().mapToDouble(VitalsEvent::getTemp).average().orElse(0);
                    breakdown.setAvgTemperature(Math.round(avgTemp * 10.0) / 10.0);
                    dailyTemperatureAverages.add(avgTemp);
                    validTempEvents.forEach(e -> allTemperatures.add((double) e.getTemp()));
                } else {
                    dailyTemperatureAverages.add(null);
                }

                // Respiratory rate
                List<VitalsEvent> validRREvents = dayVitals.stream()
                        .filter(e -> e.getRr() > 0 && e.getRr() < 60)
                        .collect(Collectors.toList());
                if (!validRREvents.isEmpty()) {
                    double avgRR = validRREvents.stream().mapToDouble(VitalsEvent::getRr).average().orElse(0);
                    breakdown.setAvgRespiratoryRate(Math.round(avgRR * 10.0) / 10.0);
                    dailyRespiratoryRateAverages.add(avgRR);
                    validRREvents.forEach(e -> allRespiratoryRates.add((double) e.getRr()));
                } else {
                    dailyRespiratoryRateAverages.add(null);
                }

                // Collect anomalies
                List<VitalsAnomaly> dayAnomalies = detectVitalsAnomalies(dayVitals);
                allAnomalies.addAll(dayAnomalies);
            } else {
                dailyHeartRateAverages.add(null);
                dailyTemperatureAverages.add(null);
                dailyRespiratoryRateAverages.add(null);
            }

            dailyBreakdowns.add(breakdown);
        }

        response.setDailyBreakdown(dailyBreakdowns);
        response.setDaysWithData(daysWithData);

        // Build Cough Weekly Summary
        CoughWeeklySummary coughSummary = new CoughWeeklySummary();
        coughSummary.setTotalCoughs(totalCoughs);
        coughSummary.setAvgCoughsPerDay(daysWithData > 0 ? Math.round(totalCoughs * 10.0 / daysWithData) / 10.0 : 0);
        coughSummary.setTotalDayCoughs(totalDayCoughs);
        coughSummary.setTotalNightCoughs(totalNightCoughs);
        coughSummary.setNightCoughPercentage(totalCoughs > 0 ? Math.round(totalNightCoughs * 1000.0 / totalCoughs) / 10.0 : 0);
        coughSummary.setSeverityLevel(determineWeeklyCoughSeverity(totalCoughs, coughSummary.getNightCoughPercentage()));
        coughSummary.setPeakDay(peakDayIndex);
        coughSummary.setPeakDayName(dayNames[peakDayIndex]);
        coughSummary.setPeakDayCoughs(peakDayCoughs);
        coughSummary.setLowestDay(lowestDayIndex);
        coughSummary.setLowestDayName(dayNames[lowestDayIndex]);
        coughSummary.setLowestDayCoughs(lowestDayCoughs == Integer.MAX_VALUE ? 0 : lowestDayCoughs);
        response.setCoughSummary(coughSummary);

        // Build Week Over Week Comparison
        WeekOverWeekComparison comparison = compareWithPreviousWeek(deviceId, weekStart, totalCoughs);
        response.setWeekOverWeekComparison(comparison);

        // Build Weekly Vitals Summary
        WeeklyVitalsSummary vitalsSummary = buildWeeklyVitalsSummary(
                allHeartRates, allTemperatures, allRespiratoryRates,
                dailyHeartRateAverages, dailyTemperatureAverages, dailyRespiratoryRateAverages,
                daysWithVitalsData, totalVitalsReadings, allAnomalies);
        response.setVitalsSummary(vitalsSummary);

        // Calculate weekly fall events summary
        WeeklyFallEventsSummary weeklyFallSummary = calculateWeeklyFallEventsSummary(deviceId, weekStart);
        response.setFallEventsSummary(weeklyFallSummary);

        // Generate weekly patterns
        List<String> weeklyPatterns = generateWeeklyPatterns(dailyBreakdowns, coughSummary, vitalsSummary);
        response.setWeeklyPatterns(weeklyPatterns);

        // Generate weekly insights
        List<String> weeklyInsights = generateWeeklyInsights(coughSummary, comparison, vitalsSummary, daysWithData);
        response.setWeeklyInsights(weeklyInsights);

        // Generate recommendations
        List<String> recommendations = generateWeeklyRecommendations(coughSummary, vitalsSummary, comparison);
        response.setRecommendations(recommendations);

        // Calculate overall severity
        int coughScore = calculateWeeklyCoughSeverityScore(totalCoughs, coughSummary.getNightCoughPercentage(), daysWithData);
        int vitalsScore = vitalsSummary.getVitalsSeverityScore();
        int overallScore = (int) Math.round((coughScore * 0.5) + (vitalsScore * 0.5));
        response.setSeverityScore(overallScore);
        response.setSeverityLevel(getSeverityLevel(overallScore));
        response.setHealthStatus(getWeeklyHealthStatus(response.getSeverityLevel(), totalCoughs, daysWithData, vitalsSummary));

        response.setHasData(daysWithData > 0 || daysWithVitalsData > 0);
        response.setMessage(response.isHasData()
                ? String.format("Weekly summary generated with %d days of data", Math.max(daysWithData, daysWithVitalsData))
                : "No data available for this week");

        return response;
    }

    private String determineWeeklyCoughSeverity(int totalCoughs, double nightPercentage) {
        // Weekly thresholds (7x daily thresholds approximately)
        if (totalCoughs > 350 || (totalCoughs > 200 && nightPercentage > 50)) {
            return "SEVERE";
        } else if (totalCoughs > 175 || (totalCoughs > 100 && nightPercentage > 40)) {
            return "HIGH";
        } else if (totalCoughs > 70) {
            return "MODERATE";
        } else {
            return "GOOD";
        }
    }

    private int calculateWeeklyCoughSeverityScore(int totalCoughs, double nightPercentage, int daysWithData) {
        if (daysWithData == 0) {
            return 0;
        }

        double score = 0;
        double avgDaily = (double) totalCoughs / daysWithData;

        // Base score from average daily cough count (0-50 points)
        if (avgDaily < 10) {
            score += 10; 
        }else if (avgDaily < 30) {
            score += 25; 
        }else if (avgDaily < 50) {
            score += 40; 
        }else {
            score += 50;
        }

        // Night percentage (0-25 points)
        score += (nightPercentage / 100.0) * 25;

        // Days with high coughs (0-25 points)
        score += Math.min((totalCoughs / 50.0) * 5, 25);

        return Math.min((int) Math.round(score), 100);
    }

    private WeekOverWeekComparison compareWithPreviousWeek(String deviceId, LocalDate weekStart, int currentWeekTotal) {
        LocalDate prevWeekStart = weekStart.minusWeeks(1);
        LocalDate prevWeekEnd = prevWeekStart.plusDays(6);

        int prevWeekTotal = 0;
        for (int i = 0; i < 7; i++) {
            List<CoughEvent> dayEvents = getCoughEventsForDay(deviceId, prevWeekStart.plusDays(i));
            prevWeekTotal += dayEvents.size();
        }

        int change = currentWeekTotal - prevWeekTotal;
        double changePercentage = prevWeekTotal > 0
                ? Math.round((change * 1000.0 / prevWeekTotal)) / 10.0
                : 0.0;

        String trend;
        String trendMessage;

        if (changePercentage < -10) {
            trend = "IMPROVING";
            trendMessage = String.format("%.1f%% decrease from last week - Good progress!", Math.abs(changePercentage));
        } else if (changePercentage > 10) {
            trend = "WORSENING";
            trendMessage = String.format("%.1f%% increase from last week - Monitor closely", changePercentage);
        } else {
            trend = "STABLE";
            trendMessage = "Cough frequency similar to last week";
        }

        return new WeekOverWeekComparison(prevWeekTotal, currentWeekTotal, change, changePercentage, trend, trendMessage);
    }

    private WeeklyVitalsSummary buildWeeklyVitalsSummary(
            List<Double> allHeartRates, List<Double> allTemperatures, List<Double> allRespiratoryRates,
            List<Double> dailyHRAverages, List<Double> dailyTempAverages, List<Double> dailyRRAverages,
            int daysWithVitalsData, int totalReadings, List<VitalsAnomaly> anomalies) {

        WeeklyVitalsSummary summary = new WeeklyVitalsSummary();
        summary.setDaysWithVitalsData(daysWithVitalsData);
        summary.setTotalReadings(totalReadings);
        summary.setHasVitalsData(daysWithVitalsData > 0);

        summary.setDailyHeartRateAverages(dailyHRAverages);
        summary.setDailyTemperatureAverages(dailyTempAverages);
        summary.setDailyRespiratoryRateAverages(dailyRRAverages);
        summary.setWeeklyAnomalies(anomalies);

        if (!summary.isHasVitalsData()) {
            summary.setVitalsMessage("No vitals data for this week");
            summary.setVitalsSeverityScore(0);
            summary.setVitalsStatus("No data");
            summary.setHeartRate(createEmptyWeeklyVitalStats("Heart Rate"));
            summary.setTemperature(createEmptyWeeklyVitalStats("Temperature"));
            summary.setRespiratoryRate(createEmptyWeeklyVitalStats("Respiratory Rate"));
            return summary;
        }

        // Calculate weekly heart rate stats
        summary.setHeartRate(calculateWeeklyHeartRateStats(allHeartRates, dailyHRAverages));

        // Calculate weekly temperature stats
        summary.setTemperature(calculateWeeklyTemperatureStats(allTemperatures, dailyTempAverages));

        // Calculate weekly respiratory rate stats
        summary.setRespiratoryRate(calculateWeeklyRespiratoryRateStats(allRespiratoryRates, dailyRRAverages));

        // Calculate overall vitals severity
        int vitalsScore = calculateWeeklyVitalsSeverityScore(summary);
        summary.setVitalsSeverityScore(vitalsScore);
        summary.setVitalsStatus(getWeeklyVitalsStatus(summary));
        summary.setVitalsMessage(String.format("%d readings across %d days", totalReadings, daysWithVitalsData));

        return summary;
    }

    private WeeklyVitalStats createEmptyWeeklyVitalStats(String vitalName) {
        return new WeeklyVitalStats(0, 0, 0, "UNKNOWN", "No " + vitalName.toLowerCase() + " data", 0, 0, "UNKNOWN");
    }

    private WeeklyVitalStats calculateWeeklyHeartRateStats(List<Double> allReadings, List<Double> dailyAverages) {
        if (allReadings.isEmpty()) {
            return createEmptyWeeklyVitalStats("Heart Rate");
        }

        double avg = allReadings.stream().mapToDouble(d -> d).average().orElse(0);
        double min = allReadings.stream().mapToDouble(d -> d).min().orElse(0);
        double max = allReadings.stream().mapToDouble(d -> d).max().orElse(0);

        String status;
        String statusMessage;
        int anomalyCount = 0;

        if (avg < HR_BRADYCARDIA) {
            status = "CRITICAL";
            statusMessage = "Weekly average indicates bradycardia";
            anomalyCount = (int) allReadings.stream().filter(hr -> hr < HR_BRADYCARDIA).count();
        } else if (avg < HR_NORMAL_MIN) {
            status = "LOW";
            statusMessage = "Below normal range for the week";
            anomalyCount = (int) allReadings.stream().filter(hr -> hr < HR_NORMAL_MIN).count();
        } else if (avg > HR_TACHYCARDIA) {
            status = "CRITICAL";
            statusMessage = "Weekly average indicates tachycardia";
            anomalyCount = (int) allReadings.stream().filter(hr -> hr > HR_TACHYCARDIA).count();
        } else if (avg > HR_NORMAL_MAX) {
            status = "HIGH";
            statusMessage = "Above normal range for the week";
            anomalyCount = (int) allReadings.stream().filter(hr -> hr > HR_NORMAL_MAX).count();
        } else {
            status = "NORMAL";
            statusMessage = "Within normal range (60-100 bpm)";
        }

        // Calculate trend from daily averages
        String trend = calculateVitalTrend(dailyAverages);

        return new WeeklyVitalStats(
                Math.round(avg * 10.0) / 10.0,
                Math.round(min * 10.0) / 10.0,
                Math.round(max * 10.0) / 10.0,
                status, statusMessage,
                allReadings.size(),
                anomalyCount,
                trend
        );
    }

    private WeeklyVitalStats calculateWeeklyTemperatureStats(List<Double> allReadings, List<Double> dailyAverages) {
        if (allReadings.isEmpty()) {
            return createEmptyWeeklyVitalStats("Temperature");
        }

        double avg = allReadings.stream().mapToDouble(d -> d).average().orElse(0);
        double min = allReadings.stream().mapToDouble(d -> d).min().orElse(0);
        double max = allReadings.stream().mapToDouble(d -> d).max().orElse(0);

        String status;
        String statusMessage;
        int anomalyCount = 0;

        if (avg >= TEMP_HIGH_FEVER) {
            status = "CRITICAL";
            statusMessage = "High fever detected during the week";
            anomalyCount = (int) allReadings.stream().filter(t -> t >= TEMP_HIGH_FEVER).count();
        } else if (avg >= TEMP_FEVER) {
            status = "HIGH";
            statusMessage = "Elevated temperature during the week";
            anomalyCount = (int) allReadings.stream().filter(t -> t >= TEMP_FEVER).count();
        } else if (avg <= TEMP_HYPOTHERMIA) {
            status = "CRITICAL";
            statusMessage = "Hypothermia risk detected";
            anomalyCount = (int) allReadings.stream().filter(t -> t <= TEMP_HYPOTHERMIA).count();
        } else if (avg < TEMP_NORMAL_MIN) {
            status = "LOW";
            statusMessage = "Below normal range for the week";
            anomalyCount = (int) allReadings.stream().filter(t -> t < TEMP_NORMAL_MIN).count();
        } else if (avg > TEMP_NORMAL_MAX) {
            status = "HIGH";
            statusMessage = "Slightly elevated for the week";
            anomalyCount = (int) allReadings.stream().filter(t -> t > TEMP_NORMAL_MAX).count();
        } else {
            status = "NORMAL";
            statusMessage = "Within normal range (36.1-37.5°C)";
        }

        String trend = calculateVitalTrend(dailyAverages);

        return new WeeklyVitalStats(
                Math.round(avg * 10.0) / 10.0,
                Math.round(min * 10.0) / 10.0,
                Math.round(max * 10.0) / 10.0,
                status, statusMessage,
                allReadings.size(),
                anomalyCount,
                trend
        );
    }

    private WeeklyVitalStats calculateWeeklyRespiratoryRateStats(List<Double> allReadings, List<Double> dailyAverages) {
        if (allReadings.isEmpty()) {
            return createEmptyWeeklyVitalStats("Respiratory Rate");
        }

        double avg = allReadings.stream().mapToDouble(d -> d).average().orElse(0);
        double min = allReadings.stream().mapToDouble(d -> d).min().orElse(0);
        double max = allReadings.stream().mapToDouble(d -> d).max().orElse(0);

        String status;
        String statusMessage;
        int anomalyCount = 0;

        if (avg >= RR_TACHYPNEA) {
            status = "CRITICAL";
            statusMessage = "Tachypnea - rapid breathing detected";
            anomalyCount = (int) allReadings.stream().filter(rr -> rr >= RR_TACHYPNEA).count();
        } else if (avg > RR_NORMAL_MAX) {
            status = "HIGH";
            statusMessage = "Elevated breathing rate for the week";
            anomalyCount = (int) allReadings.stream().filter(rr -> rr > RR_NORMAL_MAX).count();
        } else if (avg <= RR_DEPRESSION) {
            status = "CRITICAL";
            statusMessage = "Respiratory depression detected";
            anomalyCount = (int) allReadings.stream().filter(rr -> rr <= RR_DEPRESSION).count();
        } else if (avg < RR_NORMAL_MIN) {
            status = "LOW";
            statusMessage = "Below normal range for the week";
            anomalyCount = (int) allReadings.stream().filter(rr -> rr < RR_NORMAL_MIN).count();
        } else {
            status = "NORMAL";
            statusMessage = "Within normal range (12-20 breaths/min)";
        }

        String trend = calculateVitalTrend(dailyAverages);

        return new WeeklyVitalStats(
                Math.round(avg * 10.0) / 10.0,
                Math.round(min * 10.0) / 10.0,
                Math.round(max * 10.0) / 10.0,
                status, statusMessage,
                allReadings.size(),
                anomalyCount,
                trend
        );
    }

    private String calculateVitalTrend(List<Double> dailyAverages) {
        // Filter out nulls and get valid averages
        List<Double> validAverages = dailyAverages.stream()
                .filter(d -> d != null)
                .collect(Collectors.toList());

        if (validAverages.size() < 2) {
            return "STABLE";
        }

        // Simple linear trend: compare first half average to second half average
        int midpoint = validAverages.size() / 2;
        double firstHalfAvg = validAverages.subList(0, midpoint).stream().mapToDouble(d -> d).average().orElse(0);
        double secondHalfAvg = validAverages.subList(midpoint, validAverages.size()).stream().mapToDouble(d -> d).average().orElse(0);

        double changePercent = firstHalfAvg > 0 ? ((secondHalfAvg - firstHalfAvg) / firstHalfAvg) * 100 : 0;

        if (changePercent > 5) {
            return "INCREASING";
        } else if (changePercent < -5) {
            return "DECREASING";
        } else {
            return "STABLE";
        }
    }

    private int calculateWeeklyVitalsSeverityScore(WeeklyVitalsSummary summary) {
        int score = 0;

        if (summary.getHeartRate() != null) {
            switch (summary.getHeartRate().getStatus()) {
                case "CRITICAL":
                    score += 30;
                    break;
                case "HIGH":
                    score += 20;
                    break;
                case "LOW":
                    score += 15;
                    break;
            }
        }

        if (summary.getTemperature() != null) {
            switch (summary.getTemperature().getStatus()) {
                case "CRITICAL":
                    score += 30;
                    break;
                case "HIGH":
                    score += 20;
                    break;
                case "LOW":
                    score += 15;
                    break;
            }
        }

        if (summary.getRespiratoryRate() != null) {
            // Respiratory rate has higher weight for respiratory system
            switch (summary.getRespiratoryRate().getStatus()) {
                case "CRITICAL":
                    score += 40;
                    break;
                case "HIGH":
                    score += 25;
                    break;
                case "LOW":
                    score += 20;
                    break;
            }
        }

        return Math.min(score, 100);
    }

    private String getWeeklyVitalsStatus(WeeklyVitalsSummary summary) {
        int criticalCount = 0;
        int highCount = 0;

        if (summary.getHeartRate() != null) {
            if ("CRITICAL".equals(summary.getHeartRate().getStatus())) {
                criticalCount++; 
            }else if ("HIGH".equals(summary.getHeartRate().getStatus())) {
                highCount++;
            }
        }
        if (summary.getTemperature() != null) {
            if ("CRITICAL".equals(summary.getTemperature().getStatus())) {
                criticalCount++; 
            }else if ("HIGH".equals(summary.getTemperature().getStatus())) {
                highCount++;
            }
        }
        if (summary.getRespiratoryRate() != null) {
            if ("CRITICAL".equals(summary.getRespiratoryRate().getStatus())) {
                criticalCount++; 
            }else if ("HIGH".equals(summary.getRespiratoryRate().getStatus())) {
                highCount++;
            }
        }

        if (criticalCount > 0) {
            return "Critical - Immediate attention recommended";
        } else if (highCount >= 2) {
            return "Multiple elevated vitals - Medical consultation advised";
        } else if (highCount == 1) {
            return "One vital elevated - Continue monitoring";
        } else {
            return "Vitals stable throughout the week";
        }
    }

    private List<String> generateWeeklyPatterns(List<DailyBreakdown> dailyBreakdowns, CoughWeeklySummary coughSummary, WeeklyVitalsSummary vitalsSummary) {
        List<String> patterns = new ArrayList<>();

        // Weekend vs weekday pattern
        int weekdayCoughs = 0;
        int weekendCoughs = 0;
        for (DailyBreakdown day : dailyBreakdowns) {
            if (day.getDayIndex() >= 5) { // Saturday, Sunday
                weekendCoughs += day.getTotalCoughs();
            } else {
                weekdayCoughs += day.getTotalCoughs();
            }
        }

        double weekdayAvg = weekdayCoughs / 5.0;
        double weekendAvg = weekendCoughs / 2.0;

        if (weekendAvg > weekdayAvg * 1.3) {
            patterns.add(String.format("Weekend coughs %.0f%% higher than weekdays", ((weekendAvg - weekdayAvg) / weekdayAvg) * 100));
        } else if (weekdayAvg > weekendAvg * 1.3) {
            patterns.add(String.format("Weekday coughs %.0f%% higher than weekends", ((weekdayAvg - weekendAvg) / weekendAvg) * 100));
        }

        // Nocturnal pattern
        if (coughSummary.getNightCoughPercentage() > 40) {
            patterns.add(String.format("High nocturnal coughing (%.1f%% at night)", coughSummary.getNightCoughPercentage()));
        }

        // Peak day pattern
        if (coughSummary.getPeakDayCoughs() > coughSummary.getAvgCoughsPerDay() * 1.5) {
            patterns.add(String.format("Peak on %s with %d coughs (%.0f%% above average)",
                    coughSummary.getPeakDayName(), coughSummary.getPeakDayCoughs(),
                    ((coughSummary.getPeakDayCoughs() - coughSummary.getAvgCoughsPerDay()) / coughSummary.getAvgCoughsPerDay()) * 100));
        }

        // Vitals patterns
        if (vitalsSummary.isHasVitalsData()) {
            if (vitalsSummary.getTemperature() != null && "INCREASING".equals(vitalsSummary.getTemperature().getTrend())) {
                patterns.add("Temperature trending upward through the week");
            }
            if (vitalsSummary.getRespiratoryRate() != null && "INCREASING".equals(vitalsSummary.getRespiratoryRate().getTrend())) {
                patterns.add("Respiratory rate increasing through the week");
            }
        }

        return patterns;
    }

    private List<String> generateWeeklyInsights(CoughWeeklySummary coughSummary, WeekOverWeekComparison comparison, WeeklyVitalsSummary vitalsSummary, int daysWithData) {
        List<String> insights = new ArrayList<>();

        // Week over week insight
        if ("IMPROVING".equals(comparison.getTrend())) {
            insights.add(String.format("Great progress! Cough frequency decreased by %.1f%% compared to last week", Math.abs(comparison.getChangePercentage())));
        } else if ("WORSENING".equals(comparison.getTrend())) {
            insights.add(String.format("Cough frequency increased by %.1f%% compared to last week - monitor closely", comparison.getChangePercentage()));
        }

        // Best/worst day insight
        if (daysWithData > 1) {
            insights.add(String.format("Best day: %s (%d coughs) | Worst day: %s (%d coughs)",
                    coughSummary.getLowestDayName(), coughSummary.getLowestDayCoughs(),
                    coughSummary.getPeakDayName(), coughSummary.getPeakDayCoughs()));
        }

        // Severity insight
        switch (coughSummary.getSeverityLevel()) {
            case "GOOD":
                insights.add("Weekly cough frequency is within healthy range");
                break;
            case "MODERATE":
                insights.add("Moderate cough activity this week - continue monitoring");
                break;
            case "HIGH":
            case "SEVERE":
                insights.add("Elevated cough frequency this week - consider medical consultation");
                break;
        }

        // Vitals insights
        if (vitalsSummary.isHasVitalsData()) {
            int abnormalVitals = 0;
            if (vitalsSummary.getHeartRate() != null && !"NORMAL".equals(vitalsSummary.getHeartRate().getStatus())
                    && !"UNKNOWN".equals(vitalsSummary.getHeartRate().getStatus())) {
                abnormalVitals++;
            }
            if (vitalsSummary.getTemperature() != null && !"NORMAL".equals(vitalsSummary.getTemperature().getStatus())
                    && !"UNKNOWN".equals(vitalsSummary.getTemperature().getStatus())) {
                abnormalVitals++;
            }
            if (vitalsSummary.getRespiratoryRate() != null && !"NORMAL".equals(vitalsSummary.getRespiratoryRate().getStatus())
                    && !"UNKNOWN".equals(vitalsSummary.getRespiratoryRate().getStatus())) {
                abnormalVitals++;
            }

            if (abnormalVitals == 0) {
                insights.add("All vital signs remained within normal range throughout the week");
            } else {
                insights.add(String.format("%d vital sign(s) showed abnormal readings during the week", abnormalVitals));
            }
        }

        return insights;
    }

    private List<String> generateWeeklyRecommendations(CoughWeeklySummary coughSummary, WeeklyVitalsSummary vitalsSummary, WeekOverWeekComparison comparison) {
        List<String> recommendations = new ArrayList<>();

        // Based on severity level
        switch (coughSummary.getSeverityLevel()) {
            case "GOOD":
                recommendations.add("Maintain current health practices");
                recommendations.add("Continue regular monitoring");
                break;
            case "MODERATE":
                recommendations.add("Stay well hydrated throughout the day");
                recommendations.add("Monitor for any worsening symptoms");
                recommendations.add("Keep a diary of potential triggers");
                break;
            case "HIGH":
                recommendations.add("Consider scheduling a medical consultation");
                recommendations.add("Monitor for additional symptoms");
                recommendations.add("Ensure proper indoor air quality");
                break;
            case "SEVERE":
                recommendations.add("Seek medical attention as soon as possible");
                recommendations.add("Monitor oxygen levels if equipment available");
                recommendations.add("Rest and avoid physical exertion");
                break;
        }

        // Night cough recommendations
        if (coughSummary.getNightCoughPercentage() > 40) {
            recommendations.add("Elevate your head while sleeping");
            recommendations.add("Use a humidifier in your bedroom");
        }

        // Worsening trend recommendations
        if ("WORSENING".equals(comparison.getTrend())) {
            recommendations.add("Review any recent changes in environment or activities");
            recommendations.add("Consider keeping a detailed symptom diary");
        }

        // Vitals-based recommendations
        if (vitalsSummary.isHasVitalsData()) {
            if (vitalsSummary.getTemperature() != null
                    && ("HIGH".equals(vitalsSummary.getTemperature().getStatus()) || "CRITICAL".equals(vitalsSummary.getTemperature().getStatus()))) {
                recommendations.add("Monitor temperature regularly and stay hydrated");
            }

            if (vitalsSummary.getRespiratoryRate() != null
                    && ("HIGH".equals(vitalsSummary.getRespiratoryRate().getStatus()) || "CRITICAL".equals(vitalsSummary.getRespiratoryRate().getStatus()))) {
                recommendations.add("Practice calm breathing exercises");
            }
        }

        return recommendations;
    }

    private String getWeeklyHealthStatus(String severityLevel, int totalCoughs, int daysWithData, WeeklyVitalsSummary vitalsSummary) {
        StringBuilder status = new StringBuilder();

        switch (severityLevel) {
            case "GOOD":
                status.append("Overall health status: Good");
                break;
            case "MODERATE":
                status.append("Overall health status: Moderate - Continue monitoring");
                break;
            case "HIGH":
                status.append("Overall health status: Concerning - Medical consultation advised");
                break;
            case "SEVERE":
                status.append("Overall health status: Critical - Immediate medical attention recommended");
                break;
            default:
                status.append("Status unknown");
        }

        if (vitalsSummary != null && vitalsSummary.isHasVitalsData()) {
            if (vitalsSummary.getWeeklyAnomalies() != null && !vitalsSummary.getWeeklyAnomalies().isEmpty()) {
                long criticalCount = vitalsSummary.getWeeklyAnomalies().stream()
                        .filter(a -> "CRITICAL".equals(a.getSeverity()))
                        .count();
                if (criticalCount > 0) {
                    status.append(" | ").append(criticalCount).append(" critical vital event(s) this week");
                }
            }
        }

        return status.toString();
    }

    // ==================== FALL EVENTS SUMMARY METHODS ====================
    private FallEventsSummary calculateFallEventsSummary(String deviceId, LocalDate date) {
        LocalDateTime startOfDay = date.atStartOfDay();
        LocalDateTime endOfDay = date.plusDays(1).atStartOfDay();
        List<FallEvent> falls = fallRepository.findByDeviceIdAndTimestampBetween(deviceId, startOfDay, endOfDay);

        FallEventsSummary summary = new FallEventsSummary();

        if (falls.isEmpty()) {
            summary.setHasFallData(false);
            summary.setTotalFalls(0);
            summary.setEmergencyFalls(0);
            summary.setNonEmergencyFalls(0);
            summary.setMaxGForce(0);
            summary.setAvgGForce(0);
            summary.setLatestFallTime(null);
            summary.setWorstEmergencyLevel("NORMAL");
            summary.setFallRiskLevel("NONE");
            summary.setFallRiskMessage("No falls detected today");
            summary.setFallEvents(new ArrayList<>());
            return summary;
        }

        int totalFalls = falls.size();
        int emergencyFalls = (int) falls.stream().filter(f -> Boolean.TRUE.equals(f.getIsEmergency())).count();
        int nonEmergencyFalls = totalFalls - emergencyFalls;

        double maxConfidence = falls.stream().mapToDouble(f -> f.getConfidence() != null ? f.getConfidence() : 0).max().orElse(0);
        double avgConfidence = falls.stream().mapToDouble(f -> f.getConfidence() != null ? f.getConfidence() : 0).average().orElse(0);

        String latestFallTime = falls.stream()
                .max(Comparator.comparing(FallEvent::getTimestamp))
                .map(f -> String.format("%02d:%02d", f.getTimestamp().getHour(), f.getTimestamp().getMinute()))
                .orElse(null);

        String worstLevel = falls.stream()
                .map(f -> f.getEmergencyLevel() != null ? f.getEmergencyLevel() : "NORMAL")
                .reduce("NORMAL", (a, b) -> emergencyLevelRank(a) >= emergencyLevelRank(b) ? a : b);

        String fallRiskLevel = determineFallRiskLevel(totalFalls, emergencyFalls, worstLevel);
        String fallRiskMessage = buildFallRiskMessage(totalFalls, emergencyFalls, fallRiskLevel);

        DateTimeFormatter timeFormatter = DateTimeFormatter.ofPattern("HH:mm");
        List<FallEventDetail> fallEventDetails = falls.stream()
                .sorted(Comparator.comparing(FallEvent::getTimestamp).reversed())
                .map(f -> new FallEventDetail(
                        f.getTimestamp().format(timeFormatter),
                        f.getConfidence() != null ? f.getConfidence() : 0,
                        Boolean.TRUE.equals(f.getIsEmergency()),
                        f.getEmergencyLevel() != null ? f.getEmergencyLevel() : "NORMAL",
                        f.getEmergencyReason(),
                        f.getBpm(),
                        f.getTemp(),
                        f.getRr()
                ))
                .collect(Collectors.toList());

        summary.setHasFallData(true);
        summary.setTotalFalls(totalFalls);
        summary.setEmergencyFalls(emergencyFalls);
        summary.setNonEmergencyFalls(nonEmergencyFalls);
        summary.setMaxGForce(Math.round(maxConfidence * 100.0) / 100.0);
        summary.setAvgGForce(Math.round(avgConfidence * 100.0) / 100.0);
        summary.setLatestFallTime(latestFallTime);
        summary.setWorstEmergencyLevel(worstLevel);
        summary.setFallRiskLevel(fallRiskLevel);
        summary.setFallRiskMessage(fallRiskMessage);
        summary.setFallEvents(fallEventDetails);
        return summary;
    }

    private WeeklyFallEventsSummary calculateWeeklyFallEventsSummary(String deviceId, LocalDate weekStart) {
        LocalDate weekEnd = weekStart.plusDays(7);
        List<FallEvent> falls = fallRepository.findByDeviceIdAndTimestampBetween(
                deviceId, weekStart.atStartOfDay(), weekEnd.atStartOfDay());

        WeeklyFallEventsSummary summary = new WeeklyFallEventsSummary();

        if (falls.isEmpty()) {
            summary.setHasFallData(false);
            summary.setTotalFalls(0);
            summary.setTotalEmergencyFalls(0);
            summary.setMaxGForce(0);
            summary.setAvgGForce(0);
            summary.setDaysWithFalls(0);
            summary.setAvgFallsPerDay(0);
            summary.setWorstEmergencyLevel("NORMAL");
            summary.setFallRiskLevel("NONE");
            summary.setFallRiskMessage("No falls detected this week");
            summary.setDailyFallCounts(Arrays.asList(0, 0, 0, 0, 0, 0, 0));
            summary.setDailyEmergencyCounts(Arrays.asList(0, 0, 0, 0, 0, 0, 0));
            return summary;
        }

        int totalFalls = falls.size();
        int emergencyFalls = (int) falls.stream().filter(f -> Boolean.TRUE.equals(f.getIsEmergency())).count();
        double maxConfidence = falls.stream().mapToDouble(f -> f.getConfidence() != null ? f.getConfidence() : 0).max().orElse(0);
        double avgConfidence = falls.stream().mapToDouble(f -> f.getConfidence() != null ? f.getConfidence() : 0).average().orElse(0);

        List<Integer> dailyFallCounts = new ArrayList<>();
        List<Integer> dailyEmergencyCounts = new ArrayList<>();
        int daysWithFalls = 0;

        for (int i = 0; i < 7; i++) {
            LocalDate day = weekStart.plusDays(i);
            LocalDateTime dayStart = day.atStartOfDay();
            LocalDateTime dayEnd = day.plusDays(1).atStartOfDay();
            int dayCount = (int) falls.stream()
                    .filter(f -> !f.getTimestamp().isBefore(dayStart) && f.getTimestamp().isBefore(dayEnd))
                    .count();
            int dayEmergency = (int) falls.stream()
                    .filter(f -> !f.getTimestamp().isBefore(dayStart) && f.getTimestamp().isBefore(dayEnd)
                    && Boolean.TRUE.equals(f.getIsEmergency()))
                    .count();
            dailyFallCounts.add(dayCount);
            dailyEmergencyCounts.add(dayEmergency);
            if (dayCount > 0) {
                daysWithFalls++;
            }
        }

        String worstLevel = falls.stream()
                .map(f -> f.getEmergencyLevel() != null ? f.getEmergencyLevel() : "NORMAL")
                .reduce("NORMAL", (a, b) -> emergencyLevelRank(a) >= emergencyLevelRank(b) ? a : b);

        String fallRiskLevel = determineFallRiskLevel(totalFalls, emergencyFalls, worstLevel);
        String fallRiskMessage = buildFallRiskMessage(totalFalls, emergencyFalls, fallRiskLevel);

        summary.setHasFallData(true);
        summary.setTotalFalls(totalFalls);
        summary.setTotalEmergencyFalls(emergencyFalls);
        summary.setMaxGForce(Math.round(maxConfidence * 100.0) / 100.0);
        summary.setAvgGForce(Math.round(avgConfidence * 100.0) / 100.0);
        summary.setDaysWithFalls(daysWithFalls);
        summary.setAvgFallsPerDay(daysWithFalls > 0 ? Math.round(totalFalls * 10.0 / 7) / 10.0 : 0);
        summary.setWorstEmergencyLevel(worstLevel);
        summary.setFallRiskLevel(fallRiskLevel);
        summary.setFallRiskMessage(fallRiskMessage);
        summary.setDailyFallCounts(dailyFallCounts);
        summary.setDailyEmergencyCounts(dailyEmergencyCounts);
        return summary;
    }

    private int emergencyLevelRank(String level) {
        if (level == null) {
            return 0;
        }
        switch (level.toUpperCase()) {
            case "CRITICAL":
                return 4;
            case "WARNING":
                return 3;
            case "MONITORING":
                return 2;
            case "NORMAL":
                return 1;
            default:
                return 0;
        }
    }

    private String determineFallRiskLevel(int totalFalls, int emergencyFalls, String worstLevel) {
        if (totalFalls == 0) {
            return "NONE";
        }
        if ("CRITICAL".equals(worstLevel) || emergencyFalls >= 2) {
            return "CRITICAL";
        }
        if ("WARNING".equals(worstLevel) || emergencyFalls >= 1) {
            return "HIGH";
        }
        if (totalFalls >= 3) {
            return "MODERATE";
        }
        return "LOW";
    }

    private String buildFallRiskMessage(int totalFalls, int emergencyFalls, String riskLevel) {
        if (totalFalls == 0) {
            return "No falls detected";
        }
        StringBuilder msg = new StringBuilder();
        msg.append(totalFalls).append(" fall").append(totalFalls > 1 ? "s" : "").append(" detected");
        if (emergencyFalls > 0) {
            msg.append(", ").append(emergencyFalls).append(" emergency");
        }
        switch (riskLevel) {
            case "CRITICAL":
                msg.append(" - Immediate attention required");
                break;
            case "HIGH":
                msg.append(" - Medical review recommended");
                break;
            case "MODERATE":
                msg.append(" - Monitor closely");
                break;
            default:
                msg.append(" - Low risk");
                break;
        }
        return msg.toString();
    }
}
