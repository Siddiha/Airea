package dto;

public class VitalsAnomaly {
    private String type;           // HEART_RATE, TEMPERATURE, RESPIRATORY_RATE
    private String severity;       // WARNING, CRITICAL
    private String condition;      // e.g., "Bradycardia", "Fever", "Tachypnea"
    private double value;
    private String timestamp;
    private String message;
    
    // Constructors
    public VitalsAnomaly() {}
    
    public VitalsAnomaly(String type, String severity, String condition, 
                         double value, String timestamp, String message) {
        this.type = type;
        this.severity = severity;
        this.condition = condition;
        this.value = value;
        this.timestamp = timestamp;
        this.message = message;
    }
    
    // Getters and Setters
    public String getType() {
        return type;
    }
    
    public void setType(String type) {
        this.type = type;
    }
    
    public String getSeverity() {
        return severity;
    }
    
    public void setSeverity(String severity) {
        this.severity = severity;
    }
    
    public String getCondition() {
        return condition;
    }
    
    public void setCondition(String condition) {
        this.condition = condition;
    }
    
    public double getValue() {
        return value;
    }
    
    public void setValue(double value) {
        this.value = value;
    }
    
    public String getTimestamp() {
        return timestamp;
    }
    
    public void setTimestamp(String timestamp) {
        this.timestamp = timestamp;
    }
    
    public String getMessage() {
        return message;
    }
    
    public void setMessage(String message) {
        this.message = message;
    }
}
