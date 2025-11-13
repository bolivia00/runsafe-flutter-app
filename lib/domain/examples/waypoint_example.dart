// ignore_for_file: avoid_print
import 'package:runsafe/domain/dto/waypoint_dto.dart';
import 'package:runsafe/domain/entities/waypoint.dart';
import 'package:runsafe/domain/mappers/waypoint_mapper.dart';

void runWaypointExample() {
  print("\n--- Exemplo 3: Waypoint ---");
  
  final jsonFromApi = {
    'lat': -23.5505,
    'lon': -46.6333,
    'ts': '2025-10-15T20:01:30Z'
  };
  print("JSON recebido: $jsonFromApi");

  final dto = WaypointDto.fromJson(jsonFromApi);
  final mapper = WaypointMapper();
  final Waypoint entity = mapper.toEntity(dto);

  print("Entidade criada: Lat ${entity.latitude}, Lon ${entity.longitude}");
}