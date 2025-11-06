import 'package:runsafe/domain/dto/running_route_dto.dart';
import 'package:runsafe/domain/entities/running_route.dart';
import 'package:runsafe/domain/mappers/waypoint_mapper.dart';

class RunningRouteMapper {
  // 1. Ele depende do WaypointMapper, ele não cria um.
  // Isso é chamado de "Injeção de Dependência" e torna o Mapper testável.
  final WaypointMapper _waypointMapper;

  RunningRouteMapper(this._waypointMapper);

  RunningRoute toEntity(RunningRouteDto dto) {
    return RunningRoute(
      id: dto.route_id,
      name: dto.route_name,
      // 2. Ele usa o outro mapper para converter a lista.
      waypoints: dto.waypoints
          .map((waypointDto) => _waypointMapper.toEntity(waypointDto))
          .toList(),
    );
  }

  RunningRouteDto toDto(RunningRoute entity) {
    return RunningRouteDto(
      route_id: entity.id,
      route_name: entity.name,
      // 3. Ele usa o outro mapper para converter a lista de volta.
      waypoints: entity.waypoints
          .map((waypointEntity) => _waypointMapper.toDto(waypointEntity))
          .toList(),
    );
  }
}