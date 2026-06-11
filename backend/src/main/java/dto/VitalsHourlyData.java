package dto;

public class VitalsHourlyData {
    private int hour;
    private Double avgHeartRate;
    private Double avgTemperature;
    private Double avgRespiratoryRate;
    private int readingCount;
    
    // Constructors
    public VitalsHourlyData() {}
    
    public VitalsHourlyData(int hour, Double avgHeartRate, Double avgTemperature, 
                            Double avgRespiratoryRate, int readingCount) {
        this.hour = hour;
        this.avgHeartRate = avgHeartRate;
        this.avgTemperature = avgTemperature;
        this.avgRespiratoryRate = avgRespiratoryRate;
        this.readingCount = readingCount;
    }
    
    // Getters and Setters
    public int getHour() {
        return hour;
    }
    
    public void setHour(int hour) {
        this.hour = hour;
    }
    
    public Double getAvgHeartRate() {
        return avgHeartRate;
    }
    
    public void setAvgHeartRate(Double avgHeartRate) {
        this.avgHeartRate = avgHeartRate;
    }
    
    public Double getAvgTemperature() {
        return avgTemperature;
    }
    
    public void setAvgTemperature(Double avgTemperature) {
        this.avgTemperature = avgTemperature;
    }
    
    public Double getAvgRespiratoryRate() {
        return avgRespiratoryRate;
    }
    
    public void setAvgRespiratoryRate(Double avgRespiratoryRate) {
        this.avgRespiratoryRate = avgRespiratoryRate;
    }
    
    public int getReadingCount() {
        return readingCount;
    }
    
    public void setReadingCount(int readingCount) {
        this.readingCount = readingCount;
    }
}
