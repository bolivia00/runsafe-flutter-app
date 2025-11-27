// ignore_for_file: avoid_print
import 'package:runsafe/features/alerts/data/dtos/safety_alert_dto.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';
import 'package:runsafe/features/alerts/data/mappers/safety_alert_mapper.dart';

void runSafetyAlertExample() {
  print("\n--- Exemplo 2: SafetyAlert ---");

  final jsonFromApi = {
    'alert_id': 'alert-123',
    'description': 'Buraco grande na calçada',
    'alert_type': 'pothole',
    'timestamp': '2025-10-15T20:00:00Z',
    'severity': 3
  };
  print("JSON recebido: $jsonFromApi");

  final dto = SafetyAlertDto.fromJson(jsonFromApi);
  final mapper = SafetyAlertMapper();
  final SafetyAlert entity = mapper.toEntity(dto);

  print("Entidade criada: ID ${entity.id}, Tipo ${entity.type}, Data ${entity.timestamp}");
}