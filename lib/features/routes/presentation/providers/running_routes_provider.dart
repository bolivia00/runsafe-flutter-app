import 'package:flutter/foundation.dart';
import '../../infrastructure/repositories/running_routes_repository_impl_remote.dart';
import '../../domain/entities/running_route.dart';

/// Provider para gerenciar rotas com sincronização remota
/// RunningRoute contém lista aninhada de waypoints
class RunningRoutesProvider extends ChangeNotifier {
  final RunningRoutesRepositoryImplRemote _repository;

  List<RunningRoute> _routes = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<RunningRoute> get routes => _routes;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  RunningRoutesProvider(this._repository);

  /// Lista todas as rotas do cache local
  Future<List<RunningRoute>> listAll() async {
    return await _repository.listAll();
  }

  /// Lista apenas rotas destacadas (featured = true)
  Future<List<RunningRoute>> listFeatured() async {
    return await _repository.listFeatured();
  }

  /// Busca rota específica por ID com seus waypoints
  Future<RunningRoute?> getById(String id) async {
    return await _repository.getById(id);
  }

  /// Carrega rotas: primeiro do cache, depois sincroniza bidirecional (push + pull)
  Future<void> loadRoutes() async {
    if (_isLoading) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Carrega do cache primeiro (responsividade)
      if (kDebugMode) {
        print('[RunningRoutesProvider] Carregando do cache...');
      }
      _routes = await _repository.loadFromCache();
      notifyListeners(); // Atualiza UI imediatamente

      // 2. Sync bidirecional: SEMPRE executa (push + pull)
      if (kDebugMode) {
        print('[RunningRoutesProvider] Iniciando sync bidirecional...');
      }
      await _repository.syncFromServer();
      _routes = await _repository.listAll();
      
      if (kDebugMode) {
        final totalWaypoints = _routes.fold<int>(
          0, 
          (sum, route) => sum + route.waypoints.length,
        );
        print('[RunningRoutesProvider] Sync concluído: ${_routes.length} rotas totais, $totalWaypoints waypoints');
      }
    } catch (e) {
      _errorMessage = 'Erro ao carregar rotas: $e';
      if (kDebugMode) {
        print('[RunningRoutesProvider] Erro: $e');
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
        print('[RunningRoutesProvider] Sync manual iniciado');
      }
      await _repository.syncFromServer();
      _routes = await _repository.listAll();
      
      if (kDebugMode) {
        final totalWaypoints = _routes.fold<int>(
          0,
          (sum, route) => sum + route.waypoints.length,
        );
        print('[RunningRoutesProvider] Sync manual concluído: ${_routes.length} rotas, $totalWaypoints waypoints totais');
      }
    } catch (e) {
      _errorMessage = 'Erro ao sincronizar: $e';
      if (kDebugMode) {
        print('[RunningRoutesProvider] Erro sync: $e');
      }
    } finally {
      _isLoading = false;
      if (mounted) {
        notifyListeners();
      }
    }
  }

  /// Método auxiliar para verificar se o provider ainda está montado
  bool get mounted => hasListeners;
}
