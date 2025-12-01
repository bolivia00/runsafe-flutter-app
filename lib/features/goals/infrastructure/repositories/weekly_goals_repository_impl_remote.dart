// Implementação remota do WeeklyGoalsRepository usando Supabase
// Referências: `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md`

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runsafe/features/goals/domain/repositories/weekly_goals_repository.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/data/datasources/weekly_goals_local_dao.dart';
import 'package:runsafe/features/goals/infrastructure/remote/weekly_goals_remote_datasource_supabase.dart';
import 'package:runsafe/features/goals/data/models/weekly_goal_model.dart';

class WeeklyGoalsRepositoryImplRemote implements WeeklyGoalsRepository {
  final WeeklyGoalsLocalDao _localDao;
  final SupabaseWeeklyGoalsRemoteDatasource _remote;
  static const String _lastSyncKey = 'weekly_goals_last_sync_v1';
  static const String _defaultUserId = 'default-user';

  WeeklyGoalsRepositoryImplRemote(this._localDao, this._remote);

  Future<DateTime?> _getLastSync() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_lastSyncKey);
    if (raw == null) return null;
    try {
      return DateTime.parse(raw).toUtc();
    } catch (_) {
      return null;
    }
  }

  Future<void> _setLastSync(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, dt.toUtc().toIso8601String());
  }

  @override
  Future<List<WeeklyGoal>> loadFromCache() async {
    return await _localDao.loadAllForUser(_defaultUserId);
  }

  @override
  Future<int> syncFromServer() async {
    final startedAt = DateTime.now().toUtc();
    
    // === FASE 1: PUSH (melhor esforço) ===
    try {
      if (kDebugMode) {
        print('[WeeklyGoalsRepositoryImplRemote] Iniciando PUSH de metas locais...');
      }
      
      // Lê todas as metas do usuário do cache local
      final localGoals = await _localDao.loadAllForUser(_defaultUserId);
      
      if (localGoals.isNotEmpty) {
        // Converte para models
        final models = localGoals.map((goal) => WeeklyGoalModel.fromEntity(goal)).toList();
        
        // Envia para o servidor (upsert)
        final pushed = await _remote.upsertWeeklyGoals(models);
        
        if (kDebugMode) {
          print('[WeeklyGoalsRepositoryImplRemote] PUSH concluído: $pushed metas enviadas');
        }
      }
    } catch (e) {
      // Erro no push não bloqueia o pull
      if (kDebugMode) {
        print('[WeeklyGoalsRepositoryImplRemote] Erro no PUSH (ignorado): $e');
      }
    }
    
    // === FASE 2: PULL (incremental desde lastSync) ===
    final lastSync = await _getLastSync();
    
    if (kDebugMode) {
      print('[WeeklyGoalsRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
    }
    
    final page = await _remote.fetchWeeklyGoals(since: lastSync);
    final fetched = page.items;
    
    if (fetched.isEmpty) {
      if (kDebugMode) {
        print('[WeeklyGoalsRepositoryImplRemote] PULL: nenhuma meta nova/alterada.');
      }
      await _setLastSync(startedAt);
      return 0;
    }
    
    int changes = 0;
    for (final model in fetched) {
      final entity = model.toEntity();
      await _localDao.save(entity);
      changes++;
    }
    
    if (kDebugMode) {
      print('[WeeklyGoalsRepositoryImplRemote] PULL concluído: $changes metas atualizadas');
    }
    
    await _setLastSync(startedAt);
    return changes;
  }

  @override
  Future<List<WeeklyGoal>> listAll() async {
    return await loadFromCache();
  }

  @override
  Future<List<WeeklyGoal>> listFeatured() async {
    final all = await loadFromCache();
    // Critério: progresso > 0 e < 100%
    return all.where((g) {
      final progress = g.progressPercentage;
      return progress > 0 && progress < 1.0;
    }).toList();
  }

  @override
  Future<WeeklyGoal?> getById(String id) async {
    final all = await loadFromCache();
    for (final g in all) {
      if (g.id == id) return g;
    }
    return null;
  }
}

// Bloco de uso (exemplo):
/*
final remoteDatasource = SupabaseWeeklyGoalsRemoteDatasource(Supabase.instance.client);
final localDao = WeeklyGoalsLocalDao(StorageService());
final repository = WeeklyGoalsRepositoryImplRemote(localDao, remoteDatasource);

// Em um provider / viewmodel:
await repository.loadFromCache(); // Render inicial
await repository.syncFromServer(); // Atualiza incremental
final metas = await repository.listFeatured(); // Metas em progresso
*/

// Checklist de erros comuns:
// - DAO espera userId: usar constante _defaultUserId para simplificar
// - Sync incremental: lastSync pode ser null na primeira execução
// - Conversão model -> entity: WeeklyGoalModel já possui toEntity()
// - Progress calculation: entidade tem getter progressPercentage
// - Featured logic: 0 < progress < 1 (metas iniciadas mas não completas)
