class Device {
  final String id;
  final String name;
  final bool isOnline;
  final String mode; // 'AUTO' or 'MANUAL'
  final bool pumpRunning;
  final double tankLevel; // percentage 0-100
  final double pressure;
  final DateTime lastSeen;

  const Device({
    required this.id,
    required this.name,
    required this.isOnline,
    required this.mode,
    required this.pumpRunning,
    required this.tankLevel,
    required this.pressure,
    required this.lastSeen,
  });

  Device copyWith({
    String? id,
    String? name,
    bool? isOnline,
    String? mode,
    bool? pumpRunning,
    double? tankLevel,
    double? pressure,
    DateTime? lastSeen,
  }) {
    return Device(
      id: id ?? this.id,
      name: name ?? this.name,
      isOnline: isOnline ?? this.isOnline,
      mode: mode ?? this.mode,
      pumpRunning: pumpRunning ?? this.pumpRunning,
      tankLevel: tankLevel ?? this.tankLevel,
      pressure: pressure ?? this.pressure,
      lastSeen: lastSeen ?? this.lastSeen,
    );
  }
}
