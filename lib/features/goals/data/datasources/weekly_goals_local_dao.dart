import 'dart:convert';
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/data/models/weekly_goal_model.dart';

/// DAO local para persistir WeeklyGoals usando StorageService
class WeeklyGoalsLocalDao {
  final StorageService _storageService;

  WeeklyGoalsLocalDao(this._storageService);

  /// Salva um único goal (adiciona ou atualiza)
  Future<void> save(WeeklyGoal goal) async {
    final goals = await loadAllForUser(goal.userId);
    
    // Remove goal existente com mesmo ID
    goals.removeWhere((g) => g.id == goal.id);
    
    // Adiciona o goal atualizado
    goals.add(goal);
    
    // Persiste lista completa
    await _saveList(goal.userId, goals);
  }

  /// Carrega todos os goals de um usuário
  Future<List<WeeklyGoal>> loadAllForUser(String userId) async {
    final json = await _storageService.getWeeklyGoalsJson();
    
    if (json == null || json.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final userGoalsJson = decoded[userId] as List<dynamic>?;
      
      if (userGoalsJson == null) {
        return [];
      }

      return userGoalsJson
          .map((item) => WeeklyGoalModel.fromJson(item as Map<String, dynamic>).toEntity())
          .toList();
    } catch (e) {
      // Se houver erro na desserialização, retorna lista vazia
      return [];
    }
  }

  /// Remove um goal pelo ID
  Future<void> delete(String id) async {
    // Carrega todos os dados
    final allData = await _loadAllData();
    
    // Remove o goal de todos os usuários
    bool modified = false;
    for (final userId in allData.keys) {
      final goals = allData[userId]!;
      final lengthBefore = goals.length;
      goals.removeWhere((g) => g.id == id);
      if (goals.length != lengthBefore) {
        modified = true;
      }
    }

    if (modified) {
      await _saveAllData(allData);
    }
  }

  /// Remove todos os goals de um usuário
  Future<void> clearForUser(String userId) async {
    final allData = await _loadAllData();
    allData.remove(userId);
    await _saveAllData(allData);
  }

  /// Salva lista de goals para um usuário específico
  Future<void> _saveList(String userId, List<WeeklyGoal> goals) async {
    final allData = await _loadAllData();
    allData[userId] = goals;
    await _saveAllData(allData);
  }

  /// Carrega estrutura completa (todos os usuários)
  Future<Map<String, List<WeeklyGoal>>> _loadAllData() async {
    final json = await _storageService.getWeeklyGoalsJson();
    
    if (json == null || json.isEmpty) {
      return {};
    }

    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      final result = <String, List<WeeklyGoal>>{};
      
      for (final entry in decoded.entries) {
        final userId = entry.key;
        final goalsJson = entry.value as List<dynamic>;
        result[userId] = goalsJson
            .map((item) => WeeklyGoalModel.fromJson(item as Map<String, dynamic>).toEntity())
            .toList();
      }
      
      return result;
    } catch (e) {
      return {};
    }
  }

  /// Salva estrutura completa (todos os usuários)
  Future<void> _saveAllData(Map<String, List<WeeklyGoal>> allData) async {
    final encoded = <String, dynamic>{};
    
    for (final entry in allData.entries) {
      final userId = entry.key;
      final goals = entry.value;
      encoded[userId] = goals
          .map((goal) => WeeklyGoalModel.fromEntity(goal).toJson())
          .toList();
    }
    
    final json = jsonEncode(encoded);
    await _storageService.saveWeeklyGoalsJson(json);
  }
}
