import 'package:runsafe/features/routes/data/dtos/waypoint_dto.dart';
import 'package:runsafe/features/routes/domain/entities/waypoint.dart';

/// Mapper para conversão entre WaypointDto (persistência) e Waypoint (domínio)
/// Centraliza parsing defensivo de timestamp ISO 8601
class WaypointMapper {
  /// Converte DTO → Entidade de domínio
  /// Comentário: Parsing defensivo de timestamp com fallback para epoch se inválido
  Waypoint toEntity(WaypointDto dto) {
    return Waypoint(
      latitude: dto.lat,
      longitude: dto.lon,
      timestamp: DateTime.tryParse(dto.ts)?.toUtc() ?? 
                 DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  /// Converte Entidade de domínio → DTO
  /// Comentário: Usa formato ISO 8601 para persistência e como ID único
  WaypointDto toDto(Waypoint entity) {
    return WaypointDto(
      lat: entity.latitude,
      lon: entity.longitude,
      ts: entity.timestamp.toUtc().toIso8601String(),
    );
  }
}