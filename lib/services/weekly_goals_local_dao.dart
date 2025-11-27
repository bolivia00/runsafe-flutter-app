import 'dart:convert';
import 'package:runsafe/domain/dto/weekly_goal_dto.dart';
import 'package:runsafe/domain/models/listing_response.dart';
import 'package:runsafe/services/storage_service.dart';

/// DAO local para gerenciar listagem paginada e filtrável de metas semanais
/// Implementa em memória com suporte a SharedPreferences como fallback
class WeeklyGoalsLocalDaoSharedPrefs {
  final StorageService _storageService = StorageService();

  /// Cache em memória das metas carregadas
  List<WeeklyGoalDto> _cachedGoals = [];

  /// Carrega todos as metas do armazenamento
  Future<List<WeeklyGoalDto>> listAll() async {
    try {
      final jsonString = await _storageService.getWeeklyGoalsJson();
      if (jsonString == null || jsonString.isEmpty) {
        _cachedGoals = [];
      } else {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _cachedGoals = jsonList
            .map((json) => WeeklyGoalDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return _cachedGoals;
    } catch (e) {
      _cachedGoals = [];
      return [];
    }
  }

  /// Listagem com suporte a paginação, filtros e ordenação
  /// 
  /// Parâmetros:
  /// - page: página (1-based, default 1)
  /// - pageSize: itens por página (max 100, default 20)
  /// - sortBy: campo de ordenação ("target_km" default, ou "progress")
  /// - sortDir: direção de ordenação ("asc" ou "desc", default "desc")
  /// - filters: filtros opcionais {"min_target_km": 10, "min_progress_percent": 50}
  Future<ListingResponse<WeeklyGoalDto>> list({
    int page = 1,
    int pageSize = 20,
    String sortBy = 'target_km',
    String sortDir = 'desc',
    Map<String, dynamic>? filters,
  }) async {
    // Validar parâmetros
    page = ListingMeta.validatePage(page);
    pageSize = ListingMeta.validatePageSize(pageSize);
    final isAscending = sortDir.toLowerCase() == 'asc';

    // Carregar todas as metas
    await listAll();

    // Aplicar filtros
    List<WeeklyGoalDto> filtered = _cachedGoals.toList();

    if (filters != null && filters.isNotEmpty) {
      final minTargetKm = (filters['min_target_km'] as num?)?.toDouble();
      final minProgressPercent = (filters['min_progress_percent'] as num?)?.toDouble();

      if (minTargetKm != null && minTargetKm > 0) {
        filtered = filtered.where((goal) => goal.target_km >= minTargetKm).toList();
      }

      if (minProgressPercent != null && minProgressPercent >= 0 && minProgressPercent <= 100) {
        filtered = filtered
            .where((goal) {
              final progressPercent =
                  goal.target_km > 0 ? (goal.current_progress_km / goal.target_km) * 100 : 0;
              return progressPercent >= minProgressPercent;
            })
            .toList();
      }
    }

    // Aplicar ordenação
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'target_km':
          comparison = a.target_km.compareTo(b.target_km);
          break;
        case 'progress':
          final progressA = a.target_km > 0 ? a.current_progress_km / a.target_km : 0;
          final progressB = b.target_km > 0 ? b.current_progress_km / b.target_km : 0;
          comparison = progressA.compareTo(progressB);
          break;
        case 'current_km':
          comparison = a.current_progress_km.compareTo(b.current_progress_km);
          break;
        default:
          comparison = a.target_km.compareTo(b.target_km);
      }

      return isAscending ? comparison : -comparison;
    });

    // Calcular paginação
    final total = filtered.length;
    final totalPages = (total / pageSize).ceil();

    // Ajustar página se fora do intervalo
    if (page > totalPages && totalPages > 0) {
      page = totalPages;
    }

    // Extrair dados da página
    final startIndex = (page - 1) * pageSize;
    final endIndex = (startIndex + pageSize).clamp(0, total);
    final data =
        filtered.sublist(startIndex, endIndex.clamp(0, filtered.length));

    return ListingResponse<WeeklyGoalDto>(
      meta: ListingMeta(
        total: total,
        page: page,
        pageSize: pageSize,
      ),
      filtersApplied: filters ?? {},
      data: data,
    );
  }

  /// Inserir ou atualizar metas no armazenamento
  Future<void> upsertAll(List<WeeklyGoalDto> goals) async {
    try {
      final jsonList = goals.map((dto) => dto.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _storageService.saveWeeklyGoalsJson(jsonString);
      _cachedGoals = goals;
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Limpar cache local
  Future<void> clear() async {
    try {
      await _storageService.saveWeeklyGoalsJson(jsonEncode([]));
      _cachedGoals = [];
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Retornar dados em cache sem recarregar
  List<WeeklyGoalDto> getCached() => _cachedGoals;
}
