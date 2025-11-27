import 'dart:convert';
import 'package:runsafe/domain/dto/safety_alert_dto.dart';
import 'package:runsafe/domain/models/listing_response.dart';
import 'package:runsafe/services/storage_service.dart';

/// DAO local para gerenciar listagem paginada e filtrável de alertas de segurança
/// Implementa em memória com suporte a SharedPreferences como fallback
class SafetyAlertsLocalDaoSharedPrefs {
  final StorageService _storageService = StorageService();

  /// Cache em memória dos alertas carregados
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

  /// Listagem com suporte a paginação, filtros e ordenação
  /// 
  /// Parâmetros:
  /// - page: página (1-based, default 1)
  /// - pageSize: itens por página (max 100, default 20)
  /// - sortBy: campo de ordenação ("reportedAt" default, ou "severity")
  /// - sortDir: direção de ordenação ("asc" ou "desc", default "desc")
  /// - filters: filtros opcionais {"q": busca, "severity": 1-5, "alert_type": tipo}
  Future<ListingResponse<SafetyAlertDto>> list({
    int page = 1,
    int pageSize = 20,
    String sortBy = 'timestamp',
    String sortDir = 'desc',
    Map<String, dynamic>? filters,
  }) async {
    // Validar parâmetros
    page = ListingMeta.validatePage(page);
    pageSize = ListingMeta.validatePageSize(pageSize);
    final isAscending = sortDir.toLowerCase() == 'asc';

    // Carregar todos os alertas
    await listAll();

    // Aplicar filtros
    List<SafetyAlertDto> filtered = _cachedAlerts.toList();

    if (filters != null && filters.isNotEmpty) {
      final q = (filters['q'] as String?)?.toLowerCase();
      final severity = filters['severity'] as int?;
      final alertType = filters['alert_type'] as String?;

      if (q != null && q.isNotEmpty) {
        filtered = filtered
            .where((alert) =>
                alert.description.toLowerCase().contains(q) ||
                alert.alert_type.toLowerCase().contains(q))
            .toList();
      }

      if (severity != null && severity >= 1 && severity <= 5) {
        filtered = filtered.where((alert) => alert.severity == severity).toList();
      }

      if (alertType != null && alertType.isNotEmpty) {
        filtered = filtered
            .where((alert) => alert.alert_type.toLowerCase() == alertType.toLowerCase())
            .toList();
      }
    }

    // Aplicar ordenação
    filtered.sort((a, b) {
      int comparison = 0;

      switch (sortBy) {
        case 'timestamp':
          comparison = a.timestamp.compareTo(b.timestamp);
          break;
        case 'severity':
          comparison = a.severity.compareTo(b.severity);
          break;
        case 'alert_type':
          comparison = a.alert_type.compareTo(b.alert_type);
          break;
        default:
          comparison = a.timestamp.compareTo(b.timestamp);
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

    return ListingResponse<SafetyAlertDto>(
      meta: ListingMeta(
        total: total,
        page: page,
        pageSize: pageSize,
      ),
      filtersApplied: filters ?? {},
      data: data,
    );
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
