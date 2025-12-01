import 'dart:convert';
import 'package:runsafe/features/alerts/infrastructure/dtos/safety_alert_dto.dart';
import 'package:runsafe/core/services/storage_service.dart';

/// DAO local para SafetyAlert usando SharedPreferences
class SafetyAlertsLocalDaoSharedPrefs {
  final StorageService _storageService = StorageService();

  /// Cache em memória
  List<SafetyAlertDto> _cachedAlerts = [];

  /// Carrega todos os alertas do armazenamento
  Future<List<SafetyAlertDto>> listAll() async {
    try {
      final jsonString = await _storageService.getSafetyAlertsJson();
      if (jsonString == null || jsonString.isEmpty) {
        _cachedAlerts = [];
      } else {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _cachedAlerts = jsonList
            .map((json) => SafetyAlertDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return _cachedAlerts;
    } catch (e) {
      _cachedAlerts = [];
      return [];
    }
  }

  /// Inserir ou atualizar alertas no armazenamento
  Future<void> upsertAll(List<SafetyAlertDto> alerts) async {
    try {
      final jsonList = alerts.map((dto) => dto.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _storageService.saveSafetyAlertsJson(jsonString);
      _cachedAlerts = alerts;
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Limpar cache local
  Future<void> clear() async {
    try {
      await _storageService.saveSafetyAlertsJson(jsonEncode([]));
      _cachedAlerts = [];
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Retornar dados em cache sem recarregar
  List<SafetyAlertDto> getCached() => _cachedAlerts;
}
