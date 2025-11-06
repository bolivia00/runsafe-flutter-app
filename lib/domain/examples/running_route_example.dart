// ignore_for_file: avoid_print
import 'package:runsafe/domain/dto/running_route_dto.dart';
import 'package:runsafe/domain/entities/running_route.dart';
import 'package:runsafe/domain/mappers/running_route_mapper.dart';
import 'package:runsafe/domain/mappers/waypoint_mapper.dart';

void runRunningRouteExample() {
  print("\n--- Exemplo 4: RunningRoute ---");

  final jsonFromApi = {
    'route_id': 'route-456',
    'route_name': 'Volta no Parque',
    'waypoints': [
      {'lat': -23.55, 'lon': -46.63, 'ts': '2025-10-15T20:01:30Z'},
      {'lat': -23.56, 'lon': -46.64, 'ts': '2025-10-15T20:05:00Z'}
    ]
  };
print("JSON recebido: (Contém ${(jsonFromApi['waypoints'] as List).length} waypoints)");

  final dto = RunningRouteDto.fromJson(jsonFromApi);
  
  // 1. Criamos os mappers necessários
  final waypointMapper = WaypointMapper();
  final routeMapper = RunningRouteMapper(waypointMapper); // Injetamos a dependência

  // 2. Convertemos
  final RunningRoute entity = routeMapper.toEntity(dto);

  print("Entidade criada: ${entity.name}, com ${entity.waypoints.length} waypoints.");
  print("Lógica de Domínio: Distância (simulada) ${entity.totalDistanceInKm} km");
}