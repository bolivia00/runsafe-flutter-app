import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:runsafe/features/routes/data/dtos/running_route_dto.dart';
import 'package:runsafe/features/routes/domain/entities/running_route.dart';
import 'package:runsafe/features/routes/data/mappers/running_route_mapper.dart';
import 'package:runsafe/features/routes/data/mappers/waypoint_mapper.dart';
import 'package:runsafe/core/services/storage_service.dart';

class RunningRouteRepository extends ChangeNotifier {
  
  final StorageService _storageService = StorageService();
  // O Mapper da Rota precisa do Mapper do Waypoint (Injeção de Dependência)
  final RunningRouteMapper _mapper = RunningRouteMapper(WaypointMapper());

  List<RunningRoute> _routes = [];
  List<RunningRoute> get routes => _routes;

  Future<void> loadRoutes() async {
    final jsonString = await _storageService.getRunningRoutesJson();
    if (jsonString != null) {
      try {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _routes = jsonList
            .map((jsonMap) => RunningRouteDto.fromJson(jsonMap))
            .map((dto) => _mapper.toEntity(dto))
            .toList();
      } catch (e) {
        _routes = [];
      }
    }
    notifyListeners();
  }

  Future<void> _saveRoutes() async {
    final List<Map<String, dynamic>> jsonList = _routes
        .map((entity) => _mapper.toDto(entity))
        .map((dto) => dto.toJson())
        .toList();
    
    final jsonString = jsonEncode(jsonList);
    await _storageService.saveRunningRoutesJson(jsonString);
  }

  Future<void> addRoute(RunningRoute route) async {
    _routes.insert(0, route);
    await _saveRoutes();
    notifyListeners();
  }

  Future<void> editRoute(RunningRoute updatedRoute) async {
    final index = _routes.indexWhere((route) => route.id == updatedRoute.id);
    if (index != -1) {
      _routes[index] = updatedRoute;
      await _saveRoutes();
      notifyListeners();
    }
  }

  Future<void> deleteRoute(String routeId) async {
    _routes.removeWhere((route) => route.id == routeId);
    await _saveRoutes();
    notifyListeners();
  }
}
