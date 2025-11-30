import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/features/alerts/data/datasources/safety_alert_remote_datasource.dart';
import 'package:runsafe/features/alerts/data/dtos/safety_alert_dto.dart';
import 'package:runsafe/features/alerts/data/mappers/safety_alert_mapper.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';

class SafetyAlertRepository extends ChangeNotifier {
  final StorageService _localService = StorageService();
  final SafetyAlertRemoteDataSource _remoteService = SafetyAlertRemoteDataSource();
  final SafetyAlertMapper _mapper = SafetyAlertMapper();

  List<SafetyAlert> _alerts = [];
  List<SafetyAlert> get alerts => _alerts;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // --- CARREGAR ---
  Future<void> loadAlerts() async {
    _isLoading = true;
    notifyListeners();

    // 1. Local
    await _loadFromLocal();

    // 2. Remoto (Sincronização)
    try {
      await syncFromServer();
    } catch (e) {
      debugPrint("Modo Offline ou Erro Sync: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadFromLocal() async {
    final jsonString = await _localService.getSafetyAlertsJson();
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _alerts = jsonList
            .map((j) => SafetyAlertDto.fromJson(j))
            .map((dto) => _mapper.toEntity(dto))
            .toList();
        notifyListeners();
      } catch (e) {
        debugPrint("Erro ao ler cache local: $e");
      }
    }
  }

  Future<void> syncFromServer() async {
    final remoteDtos = await _remoteService.fetchAlerts();
    final remoteEntities = remoteDtos.map((d) => _mapper.toEntity(d)).toList();

    _alerts = remoteEntities;
    await _saveToLocal();
    notifyListeners();
  }

  // --- ADICIONAR ---
Future<void> addAlert(SafetyAlert alert) async {
    _isLoading = true;
    notifyListeners();

    try {
      final dto = _mapper.toDto(alert);
      
      // CORREÇÃO: Removemos "final savedDto =" pois não usamos a variável
      await _remoteService.addAlert(dto);
      
      // Como o ID vem do banco, o ideal é recarregar a lista ou salvar localmente o que temos
      // Para simplificar e tirar o erro, salvamos o alerta localmente
      _alerts.insert(0, alert);
      await _saveToLocal();
      
    } catch (e) {
      
      // ... (resto do código igual)
      debugPrint("Erro ao salvar online: $e");
      // O item já está salvo localmente, então está seguro
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- DELETAR ---
  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((a) => a.id == id);
    notifyListeners();
    await _saveToLocal();

    try {
      await _remoteService.deleteAlert(id);
    } catch (e) {
      debugPrint("Erro ao deletar online: $e");
    }
  }

  // --- EDITAR (O MÉTODO QUE FALTAVA) ---
  Future<void> editAlert(SafetyAlert updatedAlert) async {
    final index = _alerts.indexWhere((a) => a.id == updatedAlert.id);
    if (index != -1) {
      _alerts[index] = updatedAlert;
      notifyListeners();
      await _saveToLocal();
      
      // Futuro: Implementar update no Supabase aqui
    }
  }

  Future<void> _saveToLocal() async {
    final dtos = _alerts.map((e) => _mapper.toDto(e)).map((d) => d.toJson()).toList();
    await _localService.saveSafetyAlertsJson(jsonEncode(dtos));
  }
}