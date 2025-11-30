import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

/// Model para serialização/deserialização de WeeklyGoal
class WeeklyGoalModel {
  final String id;
  final String userId;
  final double targetKm;
  final double currentKm;

  WeeklyGoalModel({
    required this.id,
    required this.userId,
    required this.targetKm,
    required this.currentKm,
  })  : assert(targetKm > 0, 'targetKm deve ser maior que zero'),
        assert(currentKm >= 0, 'currentKm não pode ser negativo');

  /// Converte o model para a entidade de domínio
  WeeklyGoal toEntity() {
    return WeeklyGoal(
      id: id,
      userId: userId,
      targetKm: targetKm,
      currentKm: currentKm,
    );
  }

  /// Cria um model a partir da entidade de domínio
  factory WeeklyGoalModel.fromEntity(WeeklyGoal entity) {
    return WeeklyGoalModel(
      id: entity.id,
      userId: entity.userId,
      targetKm: entity.targetKm,
      currentKm: entity.currentKm,
    );
  }

  /// Deserializa JSON para model
  factory WeeklyGoalModel.fromJson(Map<String, dynamic> json) {
    return WeeklyGoalModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      targetKm: (json['targetKm'] as num).toDouble(),
      currentKm: (json['currentKm'] as num).toDouble(),
    );
  }

  /// Serializa model para JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'targetKm': targetKm,
      'currentKm': currentKm,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WeeklyGoalModel &&
        other.id == id &&
        other.userId == userId &&
        other.targetKm == targetKm &&
        other.currentKm == currentKm;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        userId.hashCode ^
        targetKm.hashCode ^
        currentKm.hashCode;
  }

  @override
  String toString() {
    return 'WeeklyGoalModel(id: $id, userId: $userId, targetKm: $targetKm, currentKm: $currentKm)';
  }
}
