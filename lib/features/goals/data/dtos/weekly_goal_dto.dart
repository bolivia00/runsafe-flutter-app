// ignore_for_file: non_constant_identifier_names
// Esta classe é "fiel ao backend". Ela apenas espelha o JSON.
class WeeklyGoalDto {
  final double target_km;
  final double current_progress_km;

  WeeklyGoalDto({
    required this.target_km,
    required this.current_progress_km,
  });

  // Converte um JSON (Map) em um objeto DTO
  factory WeeklyGoalDto.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalDto(
      target_km: (json['target_km'] as num).toDouble(),
      current_progress_km: (json['current_progress_km'] as num).toDouble(),
    );
  }

  // Converte o DTO em um JSON (Map) para enviar ao backend
  Map<String, dynamic> toJson() {
    return {
      'target_km': target_km,
      'current_progress_km': current_progress_km,
    };
  }
}