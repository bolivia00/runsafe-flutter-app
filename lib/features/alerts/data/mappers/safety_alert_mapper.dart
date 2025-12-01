import 'package:runsafe/features/alerts/infrastructure/dtos/safety_alert_dto.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';

/// Mapper para conversão entre SafetyAlertDto (persistência) e SafetyAlert (domínio)
/// Centraliza a lógica de conversão, especialmente do enum AlertType
class SafetyAlertMapper {
  /// Converte DTO → Entidade de domínio
  /// Comentário: Parsing defensivo de AlertType aceita múltiplos formatos
  SafetyAlert toEntity(SafetyAlertDto dto) {
    return SafetyAlert(
      id: dto.id,
      description: dto.description,
      type: _stringToAlertType(dto.type),
      timestamp: DateTime.tryParse(dto.createdAt)?.toUtc() ?? DateTime.now().toUtc(),
      severity: dto.severity,
    );
  }

  /// Converte Entidade de domínio → DTO
  /// Comentário: updatedAt é opcional, usa timestamp como fallback
  SafetyAlertDto toDto(SafetyAlert entity, {DateTime? updatedAt}) {
    return SafetyAlertDto(
      id: entity.id,
      description: entity.description,
      type: _alertTypeToString(entity.type),
      severity: entity.severity,
      createdAt: entity.timestamp.toUtc().toIso8601String(),
      updatedAt: (updatedAt ?? entity.timestamp).toUtc().toIso8601String(),
    );
  }

  /// Converte String → AlertType enum (parsing defensivo)
  /// Aceita múltiplos formatos: 'pothole', 'no_lighting', 'noLighting', etc.
  AlertType _stringToAlertType(String type) {
    switch (type.toLowerCase().replaceAll('_', '')) {
      case 'pothole':
        return AlertType.pothole;
      case 'nolighting':
        return AlertType.noLighting;
      case 'suspiciousactivity':
        return AlertType.suspiciousActivity;
      default:
        return AlertType.other;
    }
  }

  /// Converte AlertType enum → String (formato snake_case para backend)
  String _alertTypeToString(AlertType type) {
    switch (type) {
      case AlertType.pothole:
        return 'pothole';
      case AlertType.noLighting:
        return 'no_lighting';
      case AlertType.suspiciousActivity:
        return 'suspicious_activity';
      case AlertType.other:
        return 'other';
    }
  }
}
