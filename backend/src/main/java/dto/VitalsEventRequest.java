package dto;

public class VitalsEventRequest {

    private String deviceId;
    private String type;
    private float temp;
    private float bpm;
    private float rr;
    private boolean leadsOff;

    // Manual Getters and Setters (Bypassing Lombok)
    public String getDeviceId() {
        return deviceId;
    }

    public void setDeviceId(String deviceId) {
        this.deviceId = deviceId;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public float getTemp() {
        return temp;
    }

    public void setTemp(float temp) {
        this.temp = temp;
    }

    public float getBpm() {
        return bpm;
    }

    public void setBpm(float bpm) {
        this.bpm = bpm;
    }

    public float getRr() {
        return rr;
    }

    public void setRr(float rr) {
        this.rr = rr;
    }

    public boolean isLeadsOff() {
        return leadsOff;
    }

    public void setLeadsOff(boolean leadsOff) {
        this.leadsOff = leadsOff;
    }
}
