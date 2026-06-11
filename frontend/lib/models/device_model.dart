class WearableDevice {
  final String deviceID;
  final String uniquePairingCode;
  int batteryLevel;
  bool isConnected;

  WearableDevice({
    required this.deviceID,
    required this.uniquePairingCode,
    this.batteryLevel = 0,
    this.isConnected = false,
  });

  void updateBattery(int level) {
    batteryLevel = level;
  }
}

class PatientNotification {
  final String title;
  final String time;
  final bool isHighAlert; 

  PatientNotification({
    required this.title,
    required this.time,
    this.isHighAlert = false,
  });
}

class DeviceController {
  WearableDevice? currentDevice;

  bool pairDevice(String inputCode) {
    if (inputCode.isNotEmpty) {
      currentDevice = WearableDevice(
        deviceID: "XXX XXX", 
        uniquePairingCode: inputCode,
        batteryLevel: 70,    
        isConnected: true,
      );
      return true; 
    }
    return false; 
  }

  void disconnectDevice() {
    if (currentDevice != null) {
      currentDevice!.isConnected = false;
      currentDevice = null;
    }
  }

  List<PatientNotification> fetchNotifications() {
    return [
      PatientNotification(
          title: "High heart beat detected", 
          time: "13:00", 
          isHighAlert: true
      ),
      PatientNotification(
          title: "Connected with doctor", 
          time: "12:56"
      ),
      PatientNotification(
          title: "Device connected", 
          time: "12:48"
      ),
    ];
  }
}