// ignore_for_file: avoid_print
import 'package:runsafe/domain/dto/weekly_goal_dto.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/domain/mappers/weekly_goal_mapper.dart';

void runWeeklyGoalExample() {
  print("--- Exemplo 1: WeeklyGoal ---");
  
  // 1. Simula o JSON vindo da API
  final jsonFromApi = {'target_km': 10.0, 'current_progress_km': 3.5};
  print("JSON recebido: $jsonFromApi");

  // 2. JSON -> DTO
  final dto = WeeklyGoalDto.fromJson(jsonFromApi);

  // 3. DTO -> Entidade (usando o Mapper)
  final mapper = WeeklyGoalMapper();
  final WeeklyGoal entity = mapper.toEntity(dto);

  // 4. Usando a Entidade "inteligente"
  print("Entidade criada: Meta ${entity.targetKm}km, Progresso ${entity.currentKm}km");
  print("Lógica de Domínio: Progresso ${entity.progressPercentage * 100}%");

  // 5. Atualizando a entidade e convertendo de volta para DTO/JSON
  entity.addRun(2.0); // Adiciona 2km
  print("Entidade atualizada: Progresso ${entity.currentKm}km");

  final dtoToSend = mapper.toDto(entity);
  print("JSON para enviar: ${dtoToSend.toJson()}"); // {target_km: 10.0, current_progress_km: 5.5}
}