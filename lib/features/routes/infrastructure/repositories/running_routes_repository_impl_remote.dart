// Implementação remota do RunningRoutesRepository usando Supabase
// Referências: `supabase_init_debug_prompt.md`, `supabase_rls_remediation.md`
// Foco: sync incremental (updated_at), cache local SharedPreferences via DAO existente.

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:runsafe/features/routes/domain/repositories/running_routes_repository.dart';
import 'package:runsafe/features/routes/domain/entities/running_route.dart';
import 'package:runsafe/features/routes/domain/entities/waypoint.dart';
import 'package:runsafe/core/services/running_routes_local_dao.dart';
import 'package:runsafe/features/routes/infrastructure/remote/running_routes_remote_datasource_supabase.dart';
import 'package:runsafe/features/routes/data/mappers/running_route_mapper.dart';

class RunningRoutesRepositoryImplRemote implements RunningRoutesRepository {
  final RunningRoutesLocalDaoSharedPrefs _localDao;
  final SupabaseRunningRoutesRemoteDatasource _remote;
  final RunningRouteMapper _mapper;
  static const String _lastSyncKey = 'running_routes_last_sync_v1';

  RunningRoutesRepositoryImplRemote(this._localDao, this._remote, this._mapper);

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

  RunningRoute _modelToEntity(RunningRouteModel model) {
    final waypoints = model.waypoints
        .map((w) => Waypoint(latitude: w.latitude, longitude: w.longitude, timestamp: w.timestamp))
        .toList();
    // Garante pelo menos 1 waypoint (model já deveria garantir, mas mantemos defesa)
    if (waypoints.isEmpty) {
      waypoints.add(Waypoint(latitude: 0, longitude: 0, timestamp: DateTime.now().toUtc()));
    }
    return RunningRoute(id: model.id, name: model.name, waypoints: waypoints);
  }

  @override
  Future<List<RunningRoute>> loadFromCache() async {
    final dtos = await _localDao.listAll();
    return dtos.map((dto) => _mapper.toEntity(dto)).toList();
  }

  @override
  Future<int> syncFromServer() async {
    final startedAt = DateTime.now().toUtc();
    
    // === FASE 1: PUSH (melhor esforço) ===
    try {
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] Iniciando PUSH de rotas locais...');
      }
      
      // Lê todas as rotas do cache local
      final localDtos = await _localDao.listAll();
      
      if (localDtos.isNotEmpty) {
        // Converte para models do Supabase
        final models = localDtos.map((dto) {
          final entity = _mapper.toEntity(dto);
          return _entityToModel(entity);
        }).toList();
        
        // Envia para o servidor (upsert)
        final pushed = await _remote.upsertRunningRoutes(models);
        
        if (kDebugMode) {
          print('[RunningRoutesRepositoryImplRemote] PUSH concluído: $pushed rotas enviadas');
        }
      }
    } catch (e) {
      // Erro no push não bloqueia o pull
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] Erro no PUSH (ignorado): $e');
      }
    }
    
    // === FASE 2: PULL (incremental desde lastSync) ===
    final lastSync = await _getLastSync();
    
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Iniciando PULL. lastSync=${lastSync?.toIso8601String() ?? 'null'}');
    }
    
    final page = await _remote.fetchRunningRoutes(since: lastSync);
    final fetched = page.items;
    
    if (fetched.isEmpty) {
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] PULL: nenhuma rota nova/alterada.');
      }
      await _setLastSync(startedAt);
      return 0;
    }
    
    // Merge por ID
    final existingDtos = await _localDao.listAll();
    final existingById = {for (var d in existingDtos) d.route_id: d};
    
    int changes = 0;
    for (final model in fetched) {
      final entity = _modelToEntity(model);
      final dto = _mapper.toDto(entity);
      existingById[dto.route_id] = dto;
      changes++;
    }
    
    await _localDao.upsertAll(existingById.values.toList());
    
    if (kDebugMode) {
      final totalWaypoints = fetched.fold<int>(0, (sum, m) => sum + m.waypoints.length);
      print('[RunningRoutesRepositoryImplRemote] PULL concluído: $changes rotas, $totalWaypoints waypoints');
    }
    
    await _setLastSync(startedAt);
    return changes;
  }

  @override
  Future<List<RunningRoute>> listAll() async {
    return await loadFromCache();
  }

  @override
  Future<List<RunningRoute>> listFeatured() async {
    final all = await loadFromCache();
    // Critério simples: >=5 waypoints
    return all.where((r) => r.waypoints.length >= 5).toList();
  }

  @override
  Future<RunningRoute?> getById(String id) async {
    final all = await loadFromCache();
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }

  // Conversão Entity → Model para push ao Supabase
  RunningRouteModel _entityToModel(RunningRoute route) {
    return RunningRouteModel(
      id: route.id,
      name: route.name,
      waypoints: route.waypoints
          .map((w) => WaypointModel(
                latitude: w.latitude,
                longitude: w.longitude,
                timestamp: w.timestamp,
              ))
          .toList(),
      updatedAt: DateTime.now().toUtc(),
    );
  }
  
  @override
  Future<void> add(RunningRoute route) async {
    final dto = _mapper.toDto(route);
    final existing = await _localDao.listAll();
    final updated = [...existing, dto];
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Rota adicionada localmente: ${route.id}');
    }
  }
  
  @override
  Future<void> update(RunningRoute route) async {
    final dto = _mapper.toDto(route);
    final existing = await _localDao.listAll();
    final updated = existing.where((d) => d.route_id != route.id).toList()..add(dto);
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Rota atualizada localmente: ${route.id}');
    }
  }
  
  @override
  Future<void> delete(String id) async {
    // 1. Deletar do Supabase primeiro
    try {
      await _remote.deleteRunningRoute(id);
    } catch (e) {
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] Erro ao deletar no Supabase: $e');
      }
      rethrow;
    }
    
    // 2. Deletar do cache local
    final existing = await _localDao.listAll();
    final updated = existing.where((d) => d.route_id != id).toList();
    await _localDao.upsertAll(updated);
    
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Rota removida localmente e do Supabase: $id');
    }
  }
}

// Bloco de uso (exemplo):
/*
final remoteDatasource = SupabaseRunningRoutesRemoteDatasource(Supabase.instance.client);
final localDao = RunningRoutesLocalDaoSharedPrefs();
final repository = RunningRoutesRepositoryImplRemote(localDao, remoteDatasource);

// Em um provider / viewmodel:
await repository.loadFromCache(); // Render inicial
await repository.syncFromServer(); // Atualiza incremental
final rotas = await repository.listAll();
*/
