import 'package:flutter/foundation.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';
import 'package:runsafe/features/alerts/domain/repositories/safety_alerts_repository.dart';

/// Provider que envolve o SafetyAlertsRepository para uso com ChangeNotifier
class SafetyAlertsProvider extends ChangeNotifier {
  final SafetyAlertsRepository _repository;
  
  List<SafetyAlert> _alerts = [];
  bool _isLoading = false;
  
  List<SafetyAlert> get alerts => _alerts;
  bool get isLoading => _isLoading;
  
  SafetyAlertsProvider(this._repository);
  
  /// Carrega alertas: primeiro do cache, depois sincroniza bidirecional (push + pull)
  Future<void> loadAlerts() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      // Carrega cache local primeiro (responsividade)
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Carregando do cache...');
      }
      _alerts = await _repository.loadFromCache();
      notifyListeners(); // Atualiza UI imediatamente
      
      // Sync bidirecional: SEMPRE executa (push + pull)
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Iniciando sync bidirecional...');
      }
      await _repository.syncFromServer();
      _alerts = await _repository.listAll();
      
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Sync concluído: ${_alerts.length} alertas totais');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Erro ao carregar: $e');
      }
    } finally {
      _isLoading = false;
      if (mounted) {
        notifyListeners();
      }
    }
  }
  
  /// Lista alertas em destaque (severity >= 4)
  Future<List<SafetyAlert>> getFeatured() async {
    return await _repository.listFeatured();
  }
  
  /// Busca alerta por ID
  Future<SafetyAlert?> getById(String id) async {
    return await _repository.getById(id);
  }
  
  /// Força sincronização
  Future<void> syncNow() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Sync manual iniciado');
      }
      await _repository.syncFromServer();
      _alerts = await _repository.listAll();
      
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Sync manual concluído: ${_alerts.length} alertas');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Erro ao sincronizar: $e');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  /// Adiciona novo alerta
  Future<void> addAlert(SafetyAlert alert) async {
    try {
      await _repository.add(alert);
      _alerts = await _repository.listAll();
      notifyListeners();
      
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Alerta adicionado: ${alert.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Erro ao adicionar alerta: $e');
      }
      rethrow;
    }
  }
  
  /// Atualiza alerta existente
  Future<void> updateAlert(SafetyAlert alert) async {
    try {
      await _repository.update(alert);
      _alerts = await _repository.listAll();
      notifyListeners();
      
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Alerta atualizado: ${alert.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Erro ao atualizar alerta: $e');
      }
      rethrow;
    }
  }
  
  /// Remove alerta
  Future<void> deleteAlert(String id) async {
    try {
      await _repository.delete(id);
      _alerts = await _repository.listAll();
      notifyListeners();
      
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Alerta removido: $id');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SafetyAlertsProvider] Erro ao remover alerta: $e');
      }
      rethrow;
    }
  }
  
  /// Método auxiliar para verificar se o provider ainda está montado
  bool get mounted => hasListeners;
}
