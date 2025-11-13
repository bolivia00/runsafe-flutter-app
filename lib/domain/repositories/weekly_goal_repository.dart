import 'dart:convert'; // <-- 1. ESTA LINHA ESTAVA FALTANDO
import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/weekly_goal_dto.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/domain/mappers/weekly_goal_mapper.dart';
import 'package:runsafe/services/storage_service.dart';

// Agora a classe será encontrada
class WeeklyGoalRepository extends ChangeNotifier {

  final StorageService _storageService = StorageService();
  final WeeklyGoalMapper _mapper = WeeklyGoalMapper();

  List<WeeklyGoal> _goals = [];
  List<WeeklyGoal> get goals => _goals;

  Future<void> loadGoals() async {
    final jsonString = await _storageService.getWeeklyGoalsJson();
    if (jsonString != null) {
      try {
        // Agora 'jsonDecode' será encontrado
        final List<dynamic> jsonList = jsonDecode(jsonString);

        _goals = jsonList
            .map((jsonMap) => WeeklyGoalDto.fromJson(jsonMap))
            .map((dto) => _mapper.toEntity(dto))
            .toList();
      } catch (e) {
        _goals = []; 
      }
    }
    notifyListeners(); 
  }

  Future<void> _saveGoals() async {
    final List<Map<String, dynamic>> jsonList = _goals
        .map((entity) => _mapper.toDto(entity))
        .map((dto) => dto.toJson())
        .toList();

    // Agora 'jsonEncode' será encontrado
    final jsonString = jsonEncode(jsonList);
    await _storageService.saveWeeklyGoalsJson(jsonString);
  }

  Future<void> addGoal(WeeklyGoal goal) async {
    _goals.insert(0, goal); 
    await _saveGoals(); 
    notifyListeners(); 
  }
}