// ignore_for_file: non_constant_identifier_names
import 'package:runsafe/features/routes/data/dtos/waypoint_dto.dart';

class RunningRouteDto {
  final String route_id;
  final String route_name;
  final List<WaypointDto> waypoints; // Lista de DTOs!

  RunningRouteDto({
    required this.route_id,
    required this.route_name,
    required this.waypoints,
  });

  factory RunningRouteDto.fromJson(Map<String, dynamic> json) {
    // Convertemos a lista de JSON em uma lista de WaypointDto
    var waypointsList = (json['waypoints'] as List)
        .map((item) => WaypointDto.fromJson(item as Map<String, dynamic>))
        .toList();

    return RunningRouteDto(
      route_id: json['route_id'] as String,
      route_name: json['route_name'] as String,
      waypoints: waypointsList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'route_id': route_id,
      'route_name': route_name,
      // Convertemos a lista de DTOs em uma lista de JSON
      'waypoints': waypoints.map((item) => item.toJson()).toList(),
    };
  }
}