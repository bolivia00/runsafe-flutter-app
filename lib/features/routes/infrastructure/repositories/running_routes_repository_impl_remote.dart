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
    
    // === FASE 1: PULL (busca do servidor PRIMEIRO para detectar exclusões) ===
    if (kDebugMode) {
      print('[RunningRoutesRepositoryImplRemote] Iniciando PULL completo...');
    }
    
    // Busca TODAS as rotas do Supabase (sem filtro since)
    final page = await _remote.fetchRunningRoutes(since: null);
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
      final totalWaypoints = fetched.fold<int>(0, (sum, m) => sum + m.waypoints.length);
      print('[RunningRoutesRepositoryImplRemote] PULL concluído: ${newDtos.length} rotas, $totalWaypoints waypoints');
    }
    
    // === FASE 2: PUSH (envia alterações locais ao servidor) ===
    try {
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] Iniciando PUSH de rotas locais...');
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
        final pushed = await _remote.upsertRunningRoutes(models);
        
        if (kDebugMode) {
          print('[RunningRoutesRepositoryImplRemote] PUSH concluído: $pushed rotas enviadas');
        }
      }
    } catch (e) {
      // Erro no push não bloqueia a sincronização
      if (kDebugMode) {
        print('[RunningRoutesRepositoryImplRemote] Erro no PUSH (ignorado): $e');
      }
    }
    
    await _setLastSync(startedAt);
    return newDtos.length;
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
