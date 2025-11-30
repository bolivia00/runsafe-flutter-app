import 'package:runsafe/features/alerts/data/dtos/safety_alert_dto.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';

class SafetyAlertMapper {
  
  // Converte DTO -> Entidade
  SafetyAlert toEntity(SafetyAlertDto dto) {
    return SafetyAlert(
      id: dto.id,
      description: dto.description,
      type: _mapStringToEnum(dto.type),
      severity: dto.severity,
      timestamp: DateTime.parse(dto.createdAt),
    );
  }

  // Converte Entidade -> DTO
  SafetyAlertDto toDto(SafetyAlert entity) {
    return SafetyAlertDto(
      id: entity.id,
      description: entity.description,
      type: _mapEnumToString(entity.type),
      severity: entity.severity,
      createdAt: entity.timestamp.toIso8601String(),
      updatedAt: DateTime.now().toIso8601String(),
    );
  }

  // Auxiliares
  AlertType _mapStringToEnum(String type) {
    switch (type) {
      case 'pothole': return AlertType.pothole;
      case 'noLighting': return AlertType.noLighting;
      case 'suspiciousActivity': return AlertType.suspiciousActivity;
      default: return AlertType.other;
    }
  }

  String _mapEnumToString(AlertType type) {
    return type.toString().split('.').last;
  }
}