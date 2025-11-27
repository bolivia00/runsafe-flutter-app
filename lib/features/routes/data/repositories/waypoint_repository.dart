import 'dart:convert';
import 'package:flutter/material.dart'; // <-- CORRIGIDO (era package.flutter)
import 'package:runsafe/features/routes/data/dtos/waypoint_dto.dart';
import 'package:runsafe/features/routes/domain/entities/waypoint.dart';
import 'package:runsafe/features/routes/data/mappers/waypoint_mapper.dart';
import 'package:runsafe/core/services/storage_service.dart';

class WaypointRepository extends ChangeNotifier { // <-- Agora 'ChangeNotifier' é encontrado
  
  final StorageService _storageService = StorageService();
  final WaypointMapper _mapper = WaypointMapper();

  List<Waypoint> _waypoints = [];
  List<Waypoint> get waypoints => _waypoints;

  Future<void> loadWaypoints() async {
    final jsonString = await _storageService.getWaypointsJson();
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _waypoints = jsonList
            .map((jsonMap) => WaypointDto.fromJson(jsonMap))
            .map((dto) => _mapper.toEntity(dto))
            .toList();
      } catch (e) {
        _waypoints = [];
      }
    }
    notifyListeners(); // <-- Agora 'notifyListeners' é encontrado
  }

  Future<void> _saveWaypoints() async {
    final List<Map<String, dynamic>> jsonList = _waypoints
        .map((entity) => _mapper.toDto(entity))
        .map((dto) => dto.toJson())
        .toList();
    
    final jsonString = jsonEncode(jsonList);
    await _storageService.saveWaypointsJson(jsonString);
  }

  Future<void> addWaypoint(Waypoint waypoint) async {
    _waypoints.insert(0, waypoint);
    await _saveWaypoints();
    notifyListeners();
  }

  Future<void> editWaypoint(Waypoint updatedWaypoint) async {
    final index = _waypoints.indexWhere((wp) => wp.timestamp == updatedWaypoint.timestamp);
    if (index != -1) {
      _waypoints[index] = updatedWaypoint;
      await _saveWaypoints();
      notifyListeners();
    }
  }

  Future<void> deleteWaypoint(DateTime timestamp) async {
    _waypoints.removeWhere((wp) => wp.timestamp == timestamp);
    await _saveWaypoints();
    notifyListeners();
  }
}
