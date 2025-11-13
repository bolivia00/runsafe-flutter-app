import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/weekly_goal_dto.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/domain/mappers/weekly_goal_mapper.dart';
import 'package:runsafe/services/storage_service.dart';

class WeeklyGoalRepository extends ChangeNotifier {
  
  final StorageService _storageService = StorageService();
  final WeeklyGoalMapper _mapper = WeeklyGoalMapper();

  List<WeeklyGoal> _goals = [];
  List<WeeklyGoal> get goals => _goals;

  // Carrega as metas salvas (código existente)
  Future<void> loadGoals() async {
    final jsonString = await _storageService.getWeeklyGoalsJson();
    if (jsonString != null) {
      try {
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

  // Salva a lista de metas atual no SharedPreferences (código existente)
  Future<void> _saveGoals() async {
    final List<Map<String, dynamic>> jsonList = _goals
        .map((entity) => _mapper.toDto(entity))
        .map((dto) => dto.toJson())
        .toList();
    
    final jsonString = jsonEncode(jsonList);
    await _storageService.saveWeeklyGoalsJson(jsonString);
  }

  // Adiciona uma nova meta (código existente)
  Future<void> addGoal(WeeklyGoal goal) async {
    _goals.insert(0, goal); 
    await _saveGoals(); 
    notifyListeners(); 
  }

  // --- NOVO MÉTODO PARA EDITAR ---
  /// Edita uma meta existente na lista
  Future<void> editGoal(WeeklyGoal updatedGoal) async {
    // 1. Encontra o índice (a posição) da meta antiga na lista usando o ID
    final index = _goals.indexWhere((goal) => goal.id == updatedGoal.id);

    // 2. Se encontrou a meta, substitui pela nova
    if (index != -1) {
      _goals[index] = updatedGoal;
      await _saveGoals(); // 3. Salva a lista inteira no disco
      notifyListeners(); // 4. Avisa a UI que a lista mudou
    }
  }

  // --- NOVO MÉTODO PARA EXCLUIR ---
  /// Exclui uma meta da lista usando o ID
  Future<void> deleteGoal(String goalId) async {
    // 1. Remove a meta da lista onde o ID bate
    _goals.removeWhere((goal) => goal.id == goalId);
    
    await _saveGoals(); // 2. Salva a lista no disco
    notifyListeners(); // 3. Avisa a UI
  }
}