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
    
    // === FASE 2: PULL (busca completa para detectar exclusões) ===
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Iniciando PULL completo...');
    }
    
    // Busca TODOS os alertas do Supabase (sem filtro since)
    final page = await _remote.fetchSafetyAlerts(since: null);
    final fetched = page.items;
    
    // Converte para DTOs
    final newDtos = fetched.map((model) {
      final entity = _modelToEntity(model);
      return _mapper.toDto(entity, updatedAt: model.updatedAt);
    }).toList();
    
    // Substitui cache local completamente
    await _localDao.upsertAll(newDtos);
    
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] PULL concluído: ${newDtos.length} alertas sincronizados');
    }
    
    await _setLastSync(startedAt);
    return newDtos.length;
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
  
  @override
  Future<void> add(SafetyAlert alert) async {
    final dto = _mapper.toDto(alert, updatedAt: DateTime.now().toUtc());
    final existing = await _localDao.listAll();
    final updated = [...existing, dto];
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Alerta adicionado localmente: ${alert.id}');
    }
  }
  
  @override
  Future<void> update(SafetyAlert alert) async {
    final dto = _mapper.toDto(alert, updatedAt: DateTime.now().toUtc());
    final existing = await _localDao.listAll();
    final updated = existing.where((d) => d.id != alert.id).toList()..add(dto);
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Alerta atualizado localmente: ${alert.id}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    // 1. Deletar do Supabase primeiro
    try {
      await _remote.deleteSafetyAlert(id);
    } catch (e) {
      if (kDebugMode) {
        print('[SafetyAlertsRepositoryImplRemote] Erro ao deletar no Supabase: $e');
      }
      rethrow;
    }
    
    // 2. Deletar do cache local
    final existing = await _localDao.listAll();
    final updated = existing.where((d) => d.id != id).toList();
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[SafetyAlertsRepositoryImplRemote] Alerta removido localmente e do Supabase: $id');
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
