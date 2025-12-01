import 'package:flutter/foundation.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/domain/repositories/weekly_goals_repository.dart';
import 'package:runsafe/features/goals/data/repositories/weekly_goals_repository_impl.dart';

/// Provider para gerenciar estado dos WeeklyGoals
class WeeklyGoalsProvider extends ChangeNotifier {
  final WeeklyGoalsRepository _repository;
  final WeeklyGoalsRepositoryImpl? _repositoryImpl;

  List<WeeklyGoal> _items = [];
  bool _loading = false;
  String? _error;
  String? _currentUserId;

  WeeklyGoalsProvider(this._repository) 
      : _repositoryImpl = _repository is WeeklyGoalsRepositoryImpl ? _repository : null;

  // Getters
  List<WeeklyGoal> get items => List.unmodifiable(_items);
  bool get loading => _loading;
  String? get error => _error;
  bool get hasError => _error != null;
  bool get isEmpty => _items.isEmpty;
  int get count => _items.length;

  /// Carrega goals de um usuário: primeiro do cache, depois sincroniza bidirecional (push + pull)
  Future<void> load(String userId) async {
    if (_loading) return;
    
    _loading = true;
    _error = null;
    _currentUserId = userId;
    notifyListeners();

    try {
      // Primeiro carrega do cache (responsividade)
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Carregando do cache...');
      }
      _items = await _repository.loadFromCache();
      notifyListeners(); // Atualiza UI imediatamente
      
      // Sync bidirecional: SEMPRE executa (push + pull)
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Iniciando sync bidirecional...');
      }
      final changesCount = await _repository.syncFromServer();
      _items = await _repository.listAll();
      
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Sync concluído: ${_items.length} metas totais ($changesCount mudanças)');
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      _items = [];
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Erro ao carregar: $e');
      }
    } finally {
      _loading = false;
      if (mounted) {
        notifyListeners();
      }
    }
  }

  /// Adiciona uma nova meta
  Future<void> addGoal(WeeklyGoal goal) async {
    try {
      // Usa método auxiliar da implementação
      if (_repositoryImpl != null) {
        await _repositoryImpl!.add(goal);
      } else {
        throw Exception('Repositório não suporta operação de adição direta');
      }
      
      // Atualiza lista local
      final index = _items.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _items[index] = goal;
      } else {
        _items.add(goal);
      }
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Adiciona quilômetros a um goal existente
  Future<void> addRunForGoal(String id, double km) async {
    if (km < 0) {
      _error = 'Quilometragem não pode ser negativa';
      notifyListeners();
      return;
    }

    try {
      // Encontra o goal
      final index = _items.indexWhere((g) => g.id == id);
      if (index == -1) {
        _error = 'Meta não encontrada';
        notifyListeners();
        return;
      }

      // Atualiza goal localmente
      final goal = _items[index];
      goal.addRun(km);

      // Persiste mudança usando método auxiliar
      if (_repositoryImpl != null) {
        await _repositoryImpl!.add(goal);
      } else {
        throw Exception('Repositório não suporta operação de atualização direta');
      }
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Remove um goal
  Future<void> remove(String id) async {
    try {
      // Usa método auxiliar da implementação
      if (_repositoryImpl != null) {
        await _repositoryImpl!.remove(id);
      } else {
        throw Exception('Repositório não suporta operação de remoção direta');
      }
      
      // Remove da lista local
      _items.removeWhere((g) => g.id == id);
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Limpa todos os goals do usuário atual
  Future<void> clearAll() async {
    if (_currentUserId == null) return;

    try {
      // Usa método auxiliar da implementação
      if (_repositoryImpl != null) {
        await _repositoryImpl!.clearForUser(_currentUserId!);
      } else {
        throw Exception('Repositório não suporta operação de limpeza direta');
      }
      
      _items.clear();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Atualiza um goal completo
  Future<void> updateGoal(WeeklyGoal goal) async {
    try {
      // Usa método auxiliar da implementação
      if (_repositoryImpl != null) {
        await _repositoryImpl!.add(goal);
      } else {
        throw Exception('Repositório não suporta operação de atualização direta');
      }
      
      // Atualiza lista local
      final index = _items.indexWhere((g) => g.id == goal.id);
      if (index != -1) {
        _items[index] = goal;
      }
      
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Encontra um goal pelo ID (usa método da interface)
  WeeklyGoal? findById(String id) {
    try {
      return _items.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Carrega metas em destaque (usa método da interface)
  Future<void> loadFeatured() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _items = await _repository.listFeatured();
      _error = null;
    } catch (e) {
      _error = e.toString();
      _items = [];
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Limpa mensagem de erro
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Sincroniza agora (chamado pelo pull-to-refresh)
  Future<void> syncNow() async {
    if (_loading) return;

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Sync manual iniciado');
      }
      final changesCount = await _repository.syncFromServer();
      _items = await _repository.listAll();
      
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Sync manual concluído: ${_items.length} metas ($changesCount mudanças)');
      }
      
      _error = null;
    } catch (e) {
      _error = e.toString();
      if (kDebugMode) {
        print('[WeeklyGoalsProvider] Erro ao sincronizar: $e');
      }
    } finally {
      _loading = false;
      if (mounted) {
        notifyListeners();
      }
    }
  }

  /// Método auxiliar para verificar se o provider ainda está montado
  bool get mounted => hasListeners;
}
