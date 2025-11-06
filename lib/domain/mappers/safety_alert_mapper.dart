import 'package:runsafe/domain/dto/safety_alert_dto.dart';
import 'package:runsafe/domain/entities/safety_alert.dart';

class SafetyAlertMapper {
  
  // Função auxiliar para converter a String do DTO no nosso Enum da Entidade
  AlertType _mapTypeToEntity(String type) {
    switch (type.toLowerCase()) {
      case 'pothole':
        return AlertType.pothole;
      case 'no_lighting':
        return AlertType.noLighting;
      case 'suspicious_activity':
        return AlertType.suspiciousActivity;
      default:
        return AlertType.other;
    }
  }

  // Função auxiliar para converter nosso Enum no formato do DTO
  String _mapTypeToDto(AlertType type) {
    return type.toString().split('.').last; // Ex: AlertType.pothole -> 'pothole'
  }

  SafetyAlert toEntity(SafetyAlertDto dto) {
    return SafetyAlert(
      id: dto.alert_id,
      description: dto.description,
      // Conversão de tipo (String -> Enum)
      type: _mapTypeToEntity(dto.alert_type), 
      // Conversão de tipo (String -> DateTime)
      timestamp: DateTime.parse(dto.timestamp), 
      severity: dto.severity,
    );
  }

 SafetyAlertDto toDto(SafetyAlert entity) {
    return SafetyAlertDto(
      alert_id: entity.id,
      description: entity.description,
      // CORREÇÃO AQUI: 'type' foi renomeado para 'alert_type'
      alert_type: _mapTypeToDto(entity.type), 
      timestamp: entity.timestamp.toIso8601String(),
      severity: entity.severity,
    );
  }
}