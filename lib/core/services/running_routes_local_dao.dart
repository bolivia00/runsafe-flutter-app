import 'dart:convert';
import 'package:runsafe/features/routes/data/dtos/running_route_dto.dart';
import 'package:runsafe/core/models/listing_response.dart';
import 'package:runsafe/core/services/storage_service.dart';

/// DAO local para gerenciar listagem paginada e filtrável de rotas de corrida
/// Implementa em memória com suporte a SharedPreferences como fallback
class RunningRoutesLocalDaoSharedPrefs {
  final StorageService _storageService = StorageService();

  /// Cache em memória das rotas carregadas
  List<RunningRouteDto> _cachedRoutes = [];

  /// Carrega todas as rotas do armazenamento
  Future<List<RunningRouteDto>> listAll() async {
    try {
      final jsonString = await _storageService.getRunningRoutesJson();
      if (jsonString == null || jsonString.isEmpty) {
        _cachedRoutes = [];
      } else {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _cachedRoutes = jsonList
            .map((json) => RunningRouteDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return _cachedRoutes;
    } catch (e) {
      _cachedRoutes = [];
      return [];
    }
  }

  /// Listagem com suporte a paginação, filtros e ordenação
  /// 
  /// Parâmetros:
  /// - page: página (1-based, default 1)
  /// - pageSize: itens por página (max 100, default 20)
  /// - sortBy: campo de ordenação (default "route_name")
  /// - sortDir: direção de ordenação ("asc" ou "desc", default "asc")
  /// - filters: filtros opcionais (exemplo: {"q": "parque"})
  Future<ListingResponse<RunningRouteDto>> list({
    int page = 1,
    int pageSize = 20,
    String sortBy = 'route_name',
    String sortDir = 'asc',
    Map<String, dynamic>? filters,
  }) async {
    // Validar parâmetros
    page = ListingMeta.validatePage(page);
    pageSize = ListingMeta.validatePageSize(pageSize);
    final isAscending = sortDir.toLowerCase() == 'asc';

    // Carregar todas as rotas
    await listAll();

    // Aplicar filtros
    List<RunningRouteDto> filtered = _cachedRoutes.toList();

    if (filters != null && filters.isNotEmpty) {
      final q = (filters['q'] as String?)?.toLowerCase();

      if (q != null && q.isNotEmpty) {
        filtered = filtered
            .where((route) =>
                route.route_name.toLowerCase().contains(q))
            .toList();
      }
    }

    // Aplicar ordenação
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'route_name':
          comparison = a.route_name.compareTo(b.route_name);
          break;
        case 'waypoints_count':
          comparison = a.waypoints.length.compareTo(b.waypoints.length);
          break;
        default:
          comparison = a.route_name.compareTo(b.route_name);
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

    return ListingResponse<RunningRouteDto>(
      meta: ListingMeta(
        total: total,
        page: page,
        pageSize: pageSize,
      ),
      filtersApplied: filters ?? {},
      data: data,
    );
  }

  /// Inserir ou atualizar rotas no armazenamento
  Future<void> upsertAll(List<RunningRouteDto> routes) async {
    try {
      final jsonList = routes.map((dto) => dto.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _storageService.saveRunningRoutesJson(jsonString);
      _cachedRoutes = routes;
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Limpar cache local
  Future<void> clear() async {
    try {
      await _storageService.saveRunningRoutesJson(jsonEncode([]));
      _cachedRoutes = [];
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Retornar dados em cache sem recarregar
  List<RunningRouteDto> getCached() => _cachedRoutes;
}


