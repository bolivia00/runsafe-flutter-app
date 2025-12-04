// Implementação remota do WaypointsRepository usando Supabase
// Referências: `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md`

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runsafe/features/routes/domain/repositories/waypoints_repository.dart';
import 'package:runsafe/features/routes/domain/entities/waypoint.dart';
import 'package:runsafe/core/services/waypoints_local_dao.dart';
import 'package:runsafe/features/routes/infrastructure/remote/waypoints_remote_datasource_supabase.dart';
import 'package:runsafe/features/routes/data/dtos/waypoint_dto.dart';
import 'package:runsafe/features/routes/data/mappers/waypoint_mapper.dart';

class WaypointsRepositoryImplRemote implements WaypointsRepository {
  final WaypointsLocalDaoSharedPrefs _localDao;
  final SupabaseWaypointsRemoteDatasource _remote;
  final WaypointMapper _mapper;
  static const String _lastSyncKey = 'waypoints_last_sync_v1';

  WaypointsRepositoryImplRemote(this._localDao, this._remote, this._mapper);

  Future<void> _setLastSync(DateTime dt) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastSyncKey, dt.toUtc().toIso8601String());
  }

  /// Converte WaypointModel (Supabase) → Entidade de domínio via mapper
  Waypoint _modelToEntity(WaypointModel model) {
    // Cria DTO temporário a partir do model
    final dto = WaypointDto(
      lat: model.latitude,
      lon: model.longitude,
      ts: model.timestamp.toIso8601String(),
    );
    // Usa mapper para conversão DTO → Entity (parsing defensivo de timestamp)
    return _mapper.toEntity(dto);
  }

  @override
  Future<List<Waypoint>> loadFromCache() async {
    final dtos = await _localDao.listAll();
    // Comentário: Usa mapper para converter DTO → Entity na fronteira de persistência
    return dtos.map((dto) => _mapper.toEntity(dto)).toList();
  }

  @override
  Future<int> syncFromServer() async {
    final startedAt = DateTime.now().toUtc();
    
    // === FASE 1: PULL (busca do servidor PRIMEIRO para detectar exclusões) ===
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] Iniciando PULL completo...');
    }
    
    // Busca TODOS os waypoints do Supabase (sem filtro since)
    final page = await _remote.fetchWaypoints(since: null);
    final fetched = page.items;
    
    // Converte para DTOs
    final newDtos = fetched.map((model) {
      final entity = _modelToEntity(model);
      return _mapper.toDto(entity);
    }).toList();
    
    // Substitui cache local completamente
    await _localDao.clear();
    await _localDao.upsertAll(newDtos);
    
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] PULL concluído: ${newDtos.length} waypoints sincronizados');
    }
    
    // === FASE 2: PUSH (envia alterações locais ao servidor) ===
    try {
      if (kDebugMode) {
        print('[WaypointsRepositoryImplRemote] Iniciando PUSH de waypoints locais...');
      }
      
      // Lê cache atualizado (já sincronizado com servidor)
      final localDtos = await _localDao.listAll();
      
      if (localDtos.isNotEmpty) {
        // Converte para models do Supabase
        final models = localDtos.map((dto) {
          final entity = _mapper.toEntity(dto);
          return _entityToModel(entity);
        }).toList();
        
        // Envia para o servidor (upsert)
        final pushed = await _remote.upsertWaypoints(models);
        
        if (kDebugMode) {
          print('[WaypointsRepositoryImplRemote] PUSH concluído: $pushed waypoints enviados');
        }
      }
    } catch (e) {
      // Erro no push não bloqueia a sincronização
      if (kDebugMode) {
        print('[WaypointsRepositoryImplRemote] Erro no PUSH (ignorado): $e');
      }
    }
    
    await _setLastSync(startedAt);
    return newDtos.length;
  }

  @override
  Future<List<Waypoint>> listAll() async {
    return await loadFromCache();
  }

  @override
  Future<List<Waypoint>> listFeatured() async {
    final all = await loadFromCache();
    // Critério: 10 mais recentes
    all.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(10).toList();
  }

  @override
  Future<Waypoint?> getById(String id) async {
    // ID é timestamp.toIso8601String()
    final all = await loadFromCache();
    for (final w in all) {
      if (w.timestamp.toIso8601String() == id) return w;
    }
    return null;
  }

  /// Converte Entity → Model para push ao Supabase
  WaypointModel _entityToModel(Waypoint waypoint) {
    return WaypointModel(
      latitude: waypoint.latitude,
      longitude: waypoint.longitude,
      timestamp: waypoint.timestamp,
      updatedAt: DateTime.now().toUtc(),
    );
  }
  
  @override
  Future<void> add(Waypoint waypoint) async {
    final dto = _mapper.toDto(waypoint);
    final existing = await _localDao.listAll();
    final updated = [...existing, dto];
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] Waypoint adicionado localmente: ${waypoint.timestamp.toIso8601String()}');
    }
  }
  
  @override
  Future<void> update(Waypoint waypoint) async {
    final dto = _mapper.toDto(waypoint);
    final existing = await _localDao.listAll();
    final updated = existing.where((d) => d.ts != waypoint.timestamp.toIso8601String()).toList()..add(dto);
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] Waypoint atualizado localmente: ${waypoint.timestamp.toIso8601String()}');
    }
  }
  
  @override
  Future<void> delete(String timestampIso) async {
    // 1. Deletar do Supabase primeiro
    try {
      await _remote.deleteWaypoint(timestampIso);
    } catch (e) {
      if (kDebugMode) {
        print('[WaypointsRepositoryImplRemote] Erro ao deletar no Supabase: $e');
      }
      rethrow;
    }
    
    // 2. Deletar do cache local
    final existing = await _localDao.listAll();
    final updated = existing.where((d) => d.ts != timestampIso).toList();
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[WaypointsRepositoryImplRemote] Waypoint removido localmente e do Supabase: $timestampIso');
    }
  }
}

// Bloco de uso (exemplo):
/*
final remoteDatasource = SupabaseWaypointsRemoteDatasource(Supabase.instance.client);
final localDao = WaypointsLocalDaoSharedPrefs();
final repository = WaypointsRepositoryImplRemote(localDao, remoteDatasource);

// Em um provider / viewmodel:
await repository.loadFromCache(); // Render inicial
await repository.syncFromServer(); // Atualiza incremental
final waypoints = await repository.listFeatured(); // 10 mais recentes
*/
