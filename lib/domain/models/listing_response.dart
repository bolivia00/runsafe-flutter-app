/// Modelo genérico para respostas paginadas de listagem
/// Segue o padrão: meta + filtersApplied + data
class ListingResponse<T> {
  final ListingMeta meta;
  final Map<String, dynamic> filtersApplied;
  final List<T> data;

  ListingResponse({
    required this.meta,
    required this.filtersApplied,
    required this.data,
  });

  /// Total de itens disponíveis (sem filtro de página)
  int get total => meta.total;

  /// Página atual (1-based)
  int get page => meta.page;

  /// Itens por página
  int get pageSize => meta.pageSize;

  /// Número total de páginas
  int get totalPages => meta.totalPages;

  /// Se há próxima página
  bool get hasNextPage => page < totalPages;

  /// Se há página anterior
  bool get hasPreviousPage => page > 1;
}

/// Metadados da paginação
class ListingMeta {
  final int total;
  final int page;
  final int pageSize;
  final int totalPages;

  ListingMeta({
    required this.total,
    required this.page,
    required this.pageSize,
  }) : totalPages = (total / pageSize).ceil();

  /// Cálculo alternativo: com página inválida, retorna página 1
  static int validatePage(int page) => page < 1 ? 1 : page;

  /// Trunca pageSize se maior que max
  static int validatePageSize(int pageSize, {int maxPageSize = 100}) {
    if (pageSize < 1) return 1;
    if (pageSize > maxPageSize) return maxPageSize;
    return pageSize;
  }
}
