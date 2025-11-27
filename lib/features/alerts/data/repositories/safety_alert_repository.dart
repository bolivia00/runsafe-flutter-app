import 'dart:convert';
import 'package:flutter/material.dart';
// NOVOS IMPORTS CORRETOS
import 'package:runsafe/features/alerts/data/dtos/safety_alert_dto.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';
import 'package:runsafe/features/alerts/data/mappers/safety_alert_mapper.dart';
import 'package:runsafe/core/services/storage_service.dart'; // Core Service

class SafetyAlertRepository extends ChangeNotifier {
  
  final StorageService _storageService = StorageService();
  final SafetyAlertMapper _mapper = SafetyAlertMapper();

  List<SafetyAlert> _alerts = [];
  List<SafetyAlert> get alerts => _alerts;

  Future<void> loadAlerts() async {
    final jsonString = await _storageService.getSafetyAlertsJson();
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        
        _alerts = jsonList
            .map((jsonMap) => SafetyAlertDto.fromJson(jsonMap))
            .map((dto) => _mapper.toEntity(dto))
            .toList();
      } catch (e) {
        _alerts = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveAlerts() async {
    final List<Map<String, dynamic>> jsonList = _alerts
        .map((entity) => _mapper.toDto(entity))
        .map((dto) => dto.toJson())
        .toList();
    
    final jsonString = jsonEncode(jsonList);
    await _storageService.saveSafetyAlertsJson(jsonString);
  }

  Future<void> addAlert(SafetyAlert alert) async {
    _alerts.insert(0, alert);
    await _saveAlerts();
    notifyListeners();
  }

  Future<void> editAlert(SafetyAlert updatedAlert) async {
    final index = _alerts.indexWhere((alert) => alert.id == updatedAlert.id);
    if (index != -1) {
      _alerts[index] = updatedAlert;
      await _saveAlerts();
      notifyListeners();
    }
  }

  Future<void> deleteAlert(String alertId) async {
    _alerts.removeWhere((alert) => alert.id == alertId);
    await _saveAlerts();
    notifyListeners();
  }
}