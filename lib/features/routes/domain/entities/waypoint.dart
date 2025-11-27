class Waypoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  // Invariantes para garantir que a localização é válida
  Waypoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError('Latitude inválida.');
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError('Longitude inválida.');
    }
  }
}