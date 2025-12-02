import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/domain/repositories/weekly_goals_repository.dart';
import 'package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart';

/// Implementação do repositório usando DAO local
/// 
/// NOTA: Esta implementação é apenas local (não sincroniza com servidor ainda).
/// Os métodos syncFromServer() retornam valores dummy até que seja implementada
/// a integração com API/backend.
class WeeklyGoalsRepositoryImpl implements WeeklyGoalsRepository {
  final WeeklyGoalsLocalDao _dao;
  final String _defaultUserId;

  WeeklyGoalsRepositoryImpl(this._dao, {String defaultUserId = 'default-user'})
      : _defaultUserId = defaultUserId;

  @override
  Future<List<WeeklyGoal>> loadFromCache() async {
    try {
      return await _dao.loadAllForUser(_defaultUserId);
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao carregar cache: $e',
        operation: 'loadFromCache',
      );
    }
  }

  @override
  Future<int> syncFromServer() async {
    try {
      // Sincronização com servidor não implementada ainda.
      // Por enquanto, retorna 0 (nenhum registro sincronizado)
      return 0;
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao sincronizar: $e',
        operation: 'syncFromServer',
      );
    }
  }

  @override
  Future<List<WeeklyGoal>> listAll() async {
    try {
      return await _dao.loadAllForUser(_defaultUserId);
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao listar goals: $e',
        operation: 'listAll',
      );
    }
  }

  @override
  Future<List<WeeklyGoal>> listFeatured() async {
    try {
      final allGoals = await _dao.loadAllForUser(_defaultUserId);
      
      // Filtra metas "em destaque": progresso > 0% e < 100%
      return allGoals.where((goal) {
        final progress = goal.progressPercentage;
        return progress > 0.0 && progress < 1.0;
      }).toList();
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao listar metas em destaque: $e',
        operation: 'listFeatured',
      );
    }
  }

  @override
  Future<WeeklyGoal?> getById(String id) async {
    try {
      final allGoals = await _dao.loadAllForUser(_defaultUserId);
      
      try {
        return allGoals.firstWhere((goal) => goal.id == id);
      } catch (e) {
        return null; // Não encontrado
      }
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao buscar goal por ID: $e',
        operation: 'getById',
      );
    }
  }
  
  @override
  Future<void> add(WeeklyGoal goal) async {
    try {
      await _dao.save(goal);
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao salvar goal: $e',
        operation: 'add',
      );
    }
  }
  
  @override
  Future<void> update(WeeklyGoal goal) async {
    try {
      await _dao.save(goal);
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao atualizar goal: $e',
        operation: 'update',
      );
    }
  }
  
  @override
  Future<void> delete(String id) async {
    try {
      await _dao.delete(id);
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao remover goal: $e',
        operation: 'delete',
      );
    }
  }

  /// Remove todos os goals de um usuário
  Future<void> clearForUser(String userId) async {
    try {
      await _dao.clearForUser(userId);
    } catch (e) {
      throw WeeklyGoalRepositoryException(
        'Erro ao limpar goals: $e',
        operation: 'clearForUser',
      );
    }
  }
}

/// Exceção personalizada para operações do repositório
class WeeklyGoalRepositoryException implements Exception {
  final String message;
  final String operation;

  WeeklyGoalRepositoryException(this.message, {required this.operation});

  @override
  String toString() => 'WeeklyGoalRepositoryException [$operation]: $message';
}
