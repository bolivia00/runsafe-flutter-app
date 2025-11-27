import 'package:runsafe/features/goals/data/dtos/weekly_goal_dto.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

// O Mapper centraliza a conversão. Sem lógica de negócios aqui!
class WeeklyGoalMapper {
  
  // Converte DTO (dados brutos) -> Entidade (objeto de domínio)
  WeeklyGoal toEntity(WeeklyGoalDto dto) {
    return WeeklyGoal(
      targetKm: dto.target_km, // Normaliza o nome
      currentKm: dto.current_progress_km, // Normaliza o nome
    );
  }

  // Converte Entidade (objeto de domínio) -> DTO (dados brutos)
  WeeklyGoalDto toDto(WeeklyGoal entity) {
    return WeeklyGoalDto(
      target_km: entity.targetKm, // Normaliza o nome
      current_progress_km: entity.currentKm, // Normaliza o nome
    );
  }
}