// Data validation schema for cough events
class CoughEvent {
  static validate(eventData) {
    const errors = [];
    
    // Required fields
    if (!eventData.device_id || typeof eventData.device_id !== 'string') {
      errors.push('device_id is required and must be a string');
    }
    
    if (!eventData.timestamp || isNaN(Date.parse(eventData.timestamp))) {
      errors.push('timestamp is required and must be a valid ISO date string');
    }
    
    if (!eventData.telemetry || typeof eventData.telemetry !== 'object') {
      errors.push('telemetry is required and must be an object');
    } else {
      // Validate telemetry sub-fields
      const tel = eventData.telemetry;
      if (typeof tel.confidence_score !== 'number' || tel.confidence_score < 0 || tel.confidence_score > 1) {
        errors.push('telemetry.confidence_score must be a number between 0 and 1');
      }
      if (typeof tel.peak_decibel !== 'number') {
        errors.push('telemetry.peak_decibel must be a number');
      }
      if (typeof tel.battery_voltage !== 'number') {
        errors.push('telemetry.battery_voltage must be a number');
      }
    }
    
    // Optional fields with defaults
    const validatedData = {
      device_id: eventData.device_id,
      timestamp: eventData.timestamp,
      event_type: eventData.event_type || 'cough_confirmed',
      telemetry: {
        confidence_score: eventData.telemetry.confidence_score,
        peak_decibel: eventData.telemetry.peak_decibel,
        battery_voltage: eventData.telemetry.battery_voltage
      },
      metadata: eventData.metadata || {
        model_version: 'unknown',
        firmware_version: '1.0.0'
      }
    };
    
    return {
      isValid: errors.length === 0,
      data: validatedData,
      errors
    };
  }
  
  // Example of what a complete event should look like
  static getExample() {
    return {
      device_id: "cough_monitor_01",
      timestamp: "2025-12-14T14:45:00Z",
      event_type: "cough_confirmed",
      telemetry: {
        confidence_score: 0.94,
        peak_decibel: -8.5,
        battery_voltage: 4.1
      },
      metadata: {
        model_version: "v1.2_quantized",
        firmware_version: "1.0.0",
        location: "bedroom"
      }
    };
  }
}

module.exports = CoughEvent;