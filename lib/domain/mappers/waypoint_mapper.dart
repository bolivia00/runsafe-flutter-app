import 'package:runsafe/domain/dto/waypoint_dto.dart';
import 'package:runsafe/domain/entities/waypoint.dart';

class WaypointMapper {
  Waypoint toEntity(WaypointDto dto) {
    return Waypoint(
      latitude: dto.lat,
      longitude: dto.lon,
      timestamp: DateTime.parse(dto.ts),
    );
  }

  WaypointDto toDto(Waypoint entity) {
    return WaypointDto(
      lat: entity.latitude,
      lon: entity.longitude,
      ts: entity.timestamp.toIso8601String(),
    );
  }
}