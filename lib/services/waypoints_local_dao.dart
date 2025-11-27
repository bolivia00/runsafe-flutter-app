import 'dart:convert';
import 'package:runsafe/domain/dto/waypoint_dto.dart';
import 'package:runsafe/domain/models/listing_response.dart';
import 'package:runsafe/services/storage_service.dart';

/// DAO local para gerenciar listagem paginada e filtrável de waypoints
/// Implementa em memória com suporte a SharedPreferences como fallback
class WaypointsLocalDaoSharedPrefs {
  final StorageService _storageService = StorageService();

  /// Cache em memória dos waypoints carregados
  List<WaypointDto> _cachedWaypoints = [];

  /// Carrega todos os waypoints do armazenamento
  Future<List<WaypointDto>> listAll() async {
    try {
      final jsonString = await _storageService.getWaypointsJson();
      if (jsonString == null || jsonString.isEmpty) {
        _cachedWaypoints = [];
      } else {
        final List<dynamic> jsonList = jsonDecode(jsonString);
        _cachedWaypoints = jsonList
            .map((json) => WaypointDto.fromJson(json as Map<String, dynamic>))
            .toList();
      }
      return _cachedWaypoints;
    } catch (e) {
      _cachedWaypoints = [];
      return [];
    }
  }

  /// Listagem com suporte a paginação, filtros e ordenação
  /// 
  /// Parâmetros:
  /// - page: página (1-based, default 1)
  /// - pageSize: itens por página (max 100, default 20)
  /// - sortBy: campo de ordenação ("ts" default, ou "lat", "lon")
  /// - sortDir: direção de ordenação ("asc" ou "desc", default "desc")
  /// - filters: filtros opcionais {"q": busca, "min_lat": -90, "max_lat": 90, etc}
  Future<ListingResponse<WaypointDto>> list({
    int page = 1,
    int pageSize = 20,
    String sortBy = 'ts',
    String sortDir = 'desc',
    Map<String, dynamic>? filters,
  }) async {
    // Validar parâmetros
    page = ListingMeta.validatePage(page);
    pageSize = ListingMeta.validatePageSize(pageSize);
    final isAscending = sortDir.toLowerCase() == 'asc';

    // Carregar todos os waypoints
    await listAll();

    // Aplicar filtros
    List<WaypointDto> filtered = _cachedWaypoints.toList();

    if (filters != null && filters.isNotEmpty) {
      final minLat = (filters['min_lat'] as num?)?.toDouble();
      final maxLat = (filters['max_lat'] as num?)?.toDouble();
      final minLon = (filters['min_lon'] as num?)?.toDouble();
      final maxLon = (filters['max_lon'] as num?)?.toDouble();

      if (minLat != null) {
        filtered = filtered.where((wp) => wp.lat >= minLat).toList();
      }
      if (maxLat != null) {
        filtered = filtered.where((wp) => wp.lat <= maxLat).toList();
      }
      if (minLon != null) {
        filtered = filtered.where((wp) => wp.lon >= minLon).toList();
      }
      if (maxLon != null) {
        filtered = filtered.where((wp) => wp.lon <= maxLon).toList();
      }
    }

    // Aplicar ordenação
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'ts':
          comparison = a.ts.compareTo(b.ts);
          break;
        case 'lat':
          comparison = a.lat.compareTo(b.lat);
          break;
        case 'lon':
          comparison = a.lon.compareTo(b.lon);
          break;
        default:
          comparison = a.ts.compareTo(b.ts);
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

    return ListingResponse<WaypointDto>(
      meta: ListingMeta(
        total: total,
        page: page,
        pageSize: pageSize,
      ),
      filtersApplied: filters ?? {},
      data: data,
    );
  }

  /// Inserir ou atualizar waypoints no armazenamento
  Future<void> upsertAll(List<WaypointDto> waypoints) async {
    try {
      final jsonList = waypoints.map((dto) => dto.toJson()).toList();
      final jsonString = jsonEncode(jsonList);
      await _storageService.saveWaypointsJson(jsonString);
      _cachedWaypoints = waypoints;
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Limpar cache local
  Future<void> clear() async {
    try {
      await _storageService.saveWaypointsJson(jsonEncode([]));
      _cachedWaypoints = [];
    } catch (e) {
      // Log erro silenciosamente
    }
  }

  /// Retornar dados em cache sem recarregar
  List<WaypointDto> getCached() => _cachedWaypoints;
}
