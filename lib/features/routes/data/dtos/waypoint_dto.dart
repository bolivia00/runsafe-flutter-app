class WaypointDto {
  final double lat;
  final double lon;
  final String ts; // Timestamp como String

  WaypointDto({required this.lat, required this.lon, required this.ts});

  factory WaypointDto.fromJson(Map<String, dynamic> json) {
    return WaypointDto(
      lat: (json['lat'] as num).toDouble(),
      lon: (json['lon'] as num).toDouble(),
      ts: json['ts'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'lat': lat,
      'lon': lon,
      'ts': ts,
    };
  }
}