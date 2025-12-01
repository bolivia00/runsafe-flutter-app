import 'package:flutter/foundation.dart';
import '../../infrastructure/repositories/waypoints_repository_impl_remote.dart';
import '../../domain/entities/waypoint.dart';

/// Provider para gerenciar waypoints com sincronização remota
class WaypointsProvider extends ChangeNotifier {
  final WaypointsRepositoryImplRemote _repository;

  List<Waypoint> _waypoints = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Waypoint> get waypoints => _waypoints;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  WaypointsProvider(this._repository);

  /// Lista todos os waypoints do cache local
  Future<List<Waypoint>> listAll() async {
    return await _repository.listAll();
  }

  /// Busca waypoint por timestamp (ID)
  Future<Waypoint?> getById(String timestampIso) async {
    return await _repository.getById(timestampIso);
  }

  /// Carrega waypoints: primeiro do cache, depois sincroniza bidirecional (push + pull)
  Future<void> loadWaypoints() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Carrega do cache primeiro (responsividade)
      if (kDebugMode) {
        print('[WaypointsProvider] Carregando do cache...');
      }
      _waypoints = await _repository.loadFromCache();
      notifyListeners(); // Atualiza UI imediatamente

      // 2. Sync bidirecional: SEMPRE executa (push + pull)
      if (kDebugMode) {
        print('[WaypointsProvider] Iniciando sync bidirecional...');
      }
      await _repository.syncFromServer();
      _waypoints = await _repository.listAll();
      
      if (kDebugMode) {
        print('[WaypointsProvider] Sync concluído: ${_waypoints.length} waypoints totais');
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar waypoints: $e';
      if (kDebugMode) {
        print('[WaypointsProvider] Erro: $e');
      }
    } finally {
      _isLoading = false;
      if (mounted) {
        notifyListeners();
      }
    }
  }

  /// Sincroniza agora (chamado pelo pull-to-refresh)
  Future<void> syncNow() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('[WaypointsProvider] Sync manual iniciado');
      }
      await _repository.syncFromServer();
      _waypoints = await _repository.listAll();
      
      if (kDebugMode) {
        print('[WaypointsProvider] Sync manual concluído: ${_waypoints.length} waypoints');
      }
    } catch (e) {
      _errorMessage = 'Erro ao sincronizar: $e';
      if (kDebugMode) {
        print('[WaypointsProvider] Erro sync: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Método auxiliar para verificar se o provider ainda está montado
  bool get mounted => hasListeners;
}
