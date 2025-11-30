import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:runsafe/core/services/storage_service.dart';
import 'package:runsafe/features/goals/data/dtos/weekly_goal_dto.dart';
import 'package:runsafe/features/goals/data/mappers/weekly_goal_mapper.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

class WeeklyGoalRepository extends ChangeNotifier {
  
  final StorageService _storageService = StorageService();
  final WeeklyGoalMapper _mapper = WeeklyGoalMapper();

  List<WeeklyGoal> _goals = [];
  List<WeeklyGoal> get goals => _goals;

  // --- CORREÇÃO IMPORTANTE AQUI ---
  // O construtor chama o loadGoals assim que a classe nasce.
  WeeklyGoalRepository() {
    loadGoals();
  }

  // CARREGAR: Pega do disco e põe na memória
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
        debugPrint("Erro ao carregar metas: $e");
      }
    } else {
      _goals = [];
    }
    notifyListeners(); 
  }

  // SALVAR: Pega da memória e põe no disco
  Future<void> _saveGoals() async {
    final List<Map<String, dynamic>> jsonList = _goals
        .map((entity) => _mapper.toDto(entity))
        .map((dto) => dto.toJson())
        .toList();
    
    final jsonString = jsonEncode(jsonList);
    await _storageService.saveWeeklyGoalsJson(jsonString);
  }

  // ADICIONAR
  Future<void> addGoal(WeeklyGoal goal) async {
    // Insere no topo da lista
    _goals.insert(0, goal); 
    await _saveGoals(); 
    notifyListeners(); 
  }
  
  // EDITAR
  Future<void> editGoal(WeeklyGoal updatedGoal) async {
      final index = _goals.indexWhere((g) => g.id == updatedGoal.id);
      if (index != -1) {
        _goals[index] = updatedGoal;
        await _saveGoals();
        notifyListeners();
      }
  }
  
  // DELETAR
  Future<void> deleteGoal(String id) async {
      _goals.removeWhere((g) => g.id == id);
      await _saveGoals();
      notifyListeners();
  }
}