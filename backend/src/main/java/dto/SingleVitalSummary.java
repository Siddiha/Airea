package dto;

public class SingleVitalSummary {
    private double average;
    private double min;
    private double max;
    private String status;        // NORMAL, LOW, HIGH, CRITICAL
    private String statusMessage; // Human readable status
    private int readingCount;
    private int anomalyCount;
    
    // Constructors
    public SingleVitalSummary() {}
    
    public SingleVitalSummary(double average, double min, double max, String status, 
                              String statusMessage, int readingCount, int anomalyCount) {
        this.average = average;
        this.min = min;
        this.max = max;
        this.status = status;
        this.statusMessage = statusMessage;
        this.readingCount = readingCount;
        this.anomalyCount = anomalyCount;
    }
    
    // Getters and Setters
    public double getAverage() {
        return average;
    }
    
    public void setAverage(double average) {
        this.average = average;
    }
    
    public double getMin() {
        return min;
    }
    
    public void setMin(double min) {
        this.min = min;
    }
    
    public double getMax() {
        return max;
    }
    
    public void setMax(double max) {
        this.max = max;
    }
    
    public String getStatus() {
        return status;
    }
    
    public void setStatus(String status) {
        this.status = status;
    }
    
    public String getStatusMessage() {
        return statusMessage;
    }
    
    public void setStatusMessage(String statusMessage) {
        this.statusMessage = statusMessage;
    }
    
    public int getReadingCount() {
        return readingCount;
    }
    
    public void setReadingCount(int readingCount) {
        this.readingCount = readingCount;
    }
    
    public int getAnomalyCount() {
        return anomalyCount;
    }
    
    public void setAnomalyCount(int anomalyCount) {
        this.anomalyCount = anomalyCount;
    }
}
