package dto;

import java.util.List;

public class VitalsSummary {
    private boolean hasVitalsData;
    private String vitalsMessage;
    private int totalReadings;
    
    // Individual vital summaries
    private SingleVitalSummary heartRate;
    private SingleVitalSummary temperature;
    private SingleVitalSummary respiratoryRate;
    
    // Combined hourly data for multi-line chart
    private List<VitalsHourlyData> hourlyVitals;
    
    // Detected anomalies
    private List<VitalsAnomaly> anomalies;
    
    // Vitals contribution to severity
    private int vitalsSeverityScore;
    private String vitalsStatus;
    
    // Constructors
    public VitalsSummary() {}
    
    // Getters and Setters
    public boolean isHasVitalsData() {
        return hasVitalsData;
    }
    
    public void setHasVitalsData(boolean hasVitalsData) {
        this.hasVitalsData = hasVitalsData;
    }
    
    public String getVitalsMessage() {
        return vitalsMessage;
    }
    
    public void setVitalsMessage(String vitalsMessage) {
        this.vitalsMessage = vitalsMessage;
    }
    
    public int getTotalReadings() {
        return totalReadings;
    }
    
    public void setTotalReadings(int totalReadings) {
        this.totalReadings = totalReadings;
    }
    
    public SingleVitalSummary getHeartRate() {
        return heartRate;
    }
    
    public void setHeartRate(SingleVitalSummary heartRate) {
        this.heartRate = heartRate;
    }
    
    public SingleVitalSummary getTemperature() {
        return temperature;
    }
    
    public void setTemperature(SingleVitalSummary temperature) {
        this.temperature = temperature;
    }
    
    public SingleVitalSummary getRespiratoryRate() {
        return respiratoryRate;
    }
    
    public void setRespiratoryRate(SingleVitalSummary respiratoryRate) {
        this.respiratoryRate = respiratoryRate;
    }
    
    public List<VitalsHourlyData> getHourlyVitals() {
        return hourlyVitals;
    }
    
    public void setHourlyVitals(List<VitalsHourlyData> hourlyVitals) {
        this.hourlyVitals = hourlyVitals;
    }
    
    public List<VitalsAnomaly> getAnomalies() {
        return anomalies;
    }
    
    public void setAnomalies(List<VitalsAnomaly> anomalies) {
        this.anomalies = anomalies;
    }
    
    public int getVitalsSeverityScore() {
        return vitalsSeverityScore;
    }
    
    public void setVitalsSeverityScore(int vitalsSeverityScore) {
        this.vitalsSeverityScore = vitalsSeverityScore;
    }
    
    public String getVitalsStatus() {
        return vitalsStatus;
    }
    
    public void setVitalsStatus(String vitalsStatus) {
        this.vitalsStatus = vitalsStatus;
    }
}
