package service;

import dto.*;
import model.CoughEvent;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import repository.CoughRepository;

import java.time.*;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class SummaryService {

    @Autowired
    private CoughRepository coughRepository;

    private static final ZoneId SRI_LANKA_ZONE = ZoneId.of("Asia/Colombo");
    private static final DateTimeFormatter DATE_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd");

    public DailySummaryResponse generateDailySummary(String deviceId, LocalDate date) {
        DailySummaryResponse response = new DailySummaryResponse();
        response.setDate(date.format(DATE_FORMATTER));
        response.setDeviceId(deviceId);

        // Get cough events for the day
        List<CoughEvent> events = getCoughEventsForDay(deviceId, date);

        if (events.isEmpty()) {
            response.setHasData(false);
            response.setMessage("No cough data available for this date");
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
            response.setSeverityScore(0);
            response.setSeverityLevel("UNKNOWN");
            response.setHealthStatus("No data");
            response.setInsights(new ArrayList<>());
            response.setRecommendations(new ArrayList<>());
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

        // Calculate severity
        int severityScore = calculateSeverityScore(totalCoughs, nightPercentage, patterns);
        String severityLevel = getSeverityLevel(severityScore);
        String healthStatus = getHealthStatus(severityLevel, totalCoughs);

        // Generate insights
        List<HealthInsight> insights = generateInsights(totalCoughs, nightPercentage, patterns, severityLevel);

        // Generate recommendations
        List<String> recommendations = generateRecommendations(severityLevel, nightPercentage, totalCoughs);

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

    private int calculateSeverityScore(int totalCoughs, double nightPercentage, List<CoughPattern> patterns) {
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

    private String getSeverityLevel(int score) {
        if (score < 30) return "GOOD";
        else if (score < 50) return "MODERATE";
        else if (score < 70) return "HIGH";
        else return "SEVERE";
    }

    private String getHealthStatus(String level, int totalCoughs) {
        switch (level) {
            case "GOOD":
                return "Minimal cough activity - Health status good";
            case "MODERATE":
                return "Moderate cough activity - Continue monitoring";
            case "HIGH":
                return "High cough frequency - Consider medical consultation";
            case "SEVERE":
                return "Severe coughing - Medical attention recommended";
            default:
                return "Status unknown";
        }
    }

    private List<HealthInsight> generateInsights(int totalCoughs, double nightPercentage, List<CoughPattern> patterns, String severityLevel) {
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

        return insights;
    }

    private List<String> generateRecommendations(String severityLevel, double nightPercentage, int totalCoughs) {
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
}
