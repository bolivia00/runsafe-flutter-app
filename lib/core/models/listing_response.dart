/// Modelo genérico para responses de listagem com paginação
class ListingResponse<T> {
  final List<T> data;
  final ListingMeta meta;
  final Map<String, dynamic>? filtersApplied;

  ListingResponse({
    required this.data,
    required this.meta,
    this.filtersApplied,
  });

  // Getters de conveniência para acessar meta diretamente
  int get page => meta.page;
  int get pageSize => meta.pageSize;
  int get total => meta.total;
  int get totalPages => meta.totalPages;
  bool get hasNextPage => meta.hasNextPage;
  bool get hasPreviousPage => meta.page > 1;
  int get startIndex => meta.startIndex;
}

/// Metadados da paginação
class ListingMeta {
  final int page;
  final int pageSize;
  final int total;

  ListingMeta({
    required this.page,
    required this.pageSize,
    required this.total,
  });

  /// Validar número da página
  static int validatePage(int page) {
    return page < 1 ? 1 : page;
  }

  /// Validar tamanho da página
  static int validatePageSize(int pageSize) {
    if (pageSize < 1) return 10;
    if (pageSize > 100) return 100;
    return pageSize;
  }

  /// Calcular total de páginas
  int get totalPages => (total / pageSize).ceil();

  /// Verificar se há próxima página
  bool get hasNextPage => page < totalPages;

  /// Calcular índice inicial
  int get startIndex => (page - 1) * pageSize;

  /// Factory para criar ListingMeta com valores padrão
  factory ListingMeta.initial() {
    return ListingMeta(
      page: 1,
      pageSize: 10,
      total: 0,
    );
  }
}
