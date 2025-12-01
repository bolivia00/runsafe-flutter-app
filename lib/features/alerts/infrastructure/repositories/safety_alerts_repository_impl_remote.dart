// Implementação remota do SafetyAlertsRepository usando Supabase
// Referências: `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md`

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runsafe/features/alerts/domain/repositories/safety_alerts_repository.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';
import 'package:runsafe/core/services/safety_alerts_local_dao.dart';
import 'package:runsafe/features/alerts/infrastructure/remote/safety_alerts_remote_datasource_supabase.dart';
import 'package:runsafe/features/alerts/infrastructure/dtos/safety_alert_dto.dart';
import 'package:runsafe/features/alerts/data/mappers/safety_alert_mapper.dart';

class SafetyAlertsRepositoryImplRemote implements SafetyAlertsRepository {
  final SafetyAlertsLocalDaoSharedPrefs _localDao;
  final SupabaseSafetyAlertsRemoteDatasource _remote;
  final SafetyAlertMapper _mapper;
  static const String _lastSyncKey = 'safety_alerts_last_sync_v1';

  SafetyAlertsRepositoryImplRemote(this._localDao, this._remote, this._mapper);

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

  /// Converte SafetyAlertModel (Supabase) → Entidade de domínio via mapper
  SafetyAlert _modelToEntity(SafetyAlertModel model) {
    // Cria DTO temporário a partir do model
    final dto = SafetyAlertDto(
      id: model.id,
      description: model.description,
      type: model.type,
      severity: model.severity,
      createdAt: model.timestamp.toIso8601String(),
      updatedAt: (model.updatedAt ?? model.timestamp).toIso8601String(),
    );
    // Usa mapper para conversão DTO → Entity (centraliza parsing de AlertType)
    return _mapper.toEntity(dto);
  }

  @override
  Future<List<SafetyAlert>> loadFromCache() async {
    final dtos = await _localDao.listAll();
    // Comentário: Usa mapper para converter DTO → Entity na fronteira de persistência
    return dtos.map((dto) => _mapper.toEntity(dto)).toList();
  }

  @override
  Future<int> syncFromServer() async {
    final startedAt = DateTime.now().toUtc();
    
    // === FASE 1: PUSH (melhor esforço) ===
    try {
      if (kDebugMode) {
        print('[SafetyAlertsRepositoryImplRemote] Iniciando PUSH de alertas locais...');
      }
      
      // Lê todos os alertas do cache local
      final localDtos = await _localDao.listAll();
      
      if (localDtos.isNotEmpty) {
        // Converte para models do Supabase
        final models = localDtos.map((dto) {
          final entity = _mapper.toEntity(dto);
          return _entityToModel(entity);
        }).toList();
        
        // Envia para o servidor (upsert)
        final pushed = await _remote.upsertSafetyAlerts(models);
        
        if (kDebugMode) {
          print('[SafetyAlertsRepositoryImplRemote] PUSH concluído: $pushed alertas enviados');
        }
      }
    } catch (e) {
      // Erro no push não bloqueia o pull
      if (kDebugMode) {
        print('[SafetyAlertsRepositoryImplRemote] Erro no PUSH (ignorado): $e');
      }
    }
    
    // === FASE 2: PULL (incremental desde lastSync) ===
    final lastSync = await _getLastSync();
    
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
    }
    
    final page = await _remote.fetchSafetyAlerts(since: lastSync);
    final fetched = page.items;
    
    if (fetched.isEmpty) {
      if (kDebugMode) {
        print('[SafetyAlertsRepositoryImplRemote] PULL: nenhum alerta novo/alterado.');
      }
      await _setLastSync(startedAt);
      return 0;
    }
    
    // Merge por ID
    final existingDtos = await _localDao.listAll();
    final existingById = {for (var d in existingDtos) d.id: d};
    
    int changes = 0;
    for (final model in fetched) {
      final entity = _modelToEntity(model);
      final dto = _mapper.toDto(entity, updatedAt: model.updatedAt);
      existingById[dto.id] = dto;
      changes++;
    }
    
    await _localDao.upsertAll(existingById.values.toList());
    
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] PULL concluído: $changes alertas atualizados');
    }
    
    await _setLastSync(startedAt);
    return changes;
  }

  @override
  Future<List<SafetyAlert>> listAll() async {
    return await loadFromCache();
  }

  @override
  Future<List<SafetyAlert>> listFeatured() async {
    final all = await loadFromCache();
    return all.where((a) => a.severity >= 4).toList();
  }

  @override
  Future<SafetyAlert?> getById(String id) async {
    final all = await loadFromCache();
    for (final a in all) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Converte Entity → Model para push ao Supabase
  SafetyAlertModel _entityToModel(SafetyAlert alert) {
    return SafetyAlertModel(
      id: alert.id,
      description: alert.description,
      type: _alertTypeToString(alert.type),
      timestamp: alert.timestamp,
      severity: alert.severity,
      updatedAt: DateTime.now().toUtc(),
    );
  }

  /// Converte AlertType enum → String (snake_case)
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

// Bloco de uso (exemplo):
/*
final remoteDatasource = SupabaseSafetyAlertsRemoteDatasource(Supabase.instance.client);
final localDao = SafetyAlertsLocalDaoSharedPrefs();
final repository = SafetyAlertsRepositoryImplRemote(localDao, remoteDatasource);

// Em um provider / viewmodel:
await repository.loadFromCache(); // Render inicial
await repository.syncFromServer(); // Atualiza incremental
final alertas = await repository.listFeatured(); // Severidade >= 4
*/
