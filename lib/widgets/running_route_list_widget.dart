import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/running_route_dto.dart';
import 'package:runsafe/domain/models/listing_response.dart';
import 'package:runsafe/services/running_routes_local_dao.dart';
import 'package:runsafe/widgets/running_route_list_item.dart';

/// Widget de listagem de rotas de corrida com suporte a paginação, filtros e loading
class RunningRouteListWidget extends StatefulWidget {
  /// Callback quando uma rota é selecionada para edição
  final Function(RunningRouteDto)? onEdit;

  /// Callback quando uma rota é excluída
  final Function(RunningRouteDto)? onDelete;

  /// Callback para renderizar item customizado (opcional)
  final Widget Function(BuildContext, RunningRouteDto, int)? itemBuilder;

  const RunningRouteListWidget({
    super.key,
    this.onEdit,
    this.onDelete,
    this.itemBuilder,
  });

  @override
  State<RunningRouteListWidget> createState() => _RunningRouteListWidgetState();
}

class _RunningRouteListWidgetState extends State<RunningRouteListWidget> {
  final RunningRoutesLocalDaoSharedPrefs _dao =
      RunningRoutesLocalDaoSharedPrefs();

  late ListingResponse<RunningRouteDto> _currentListing;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _pageSize = 20;
  String _sortBy = 'route_name';
  String _sortDir = 'asc';

  @override
  void initState() {
    super.initState();
    _loadRoutes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRoutes({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filters = _searchController.text.isNotEmpty
          ? {'q': _searchController.text}
          : <String, dynamic>{};

      final listing = await _dao.list(
        page: page,
        pageSize: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
        filters: filters,
      );

      setState(() {
        _currentListing = listing;
        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar rotas: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    _currentPage = 1;
    _loadRoutes();
  }

  void _nextPage() {
    if (_currentListing.hasNextPage) {
      _loadRoutes(page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentListing.hasPreviousPage) {
      _loadRoutes(page: _currentPage - 1);
    }
  }

  void _changeSortBy(String field) {
    setState(() {
      _sortBy = field;
      _currentPage = 1;
    });
    _loadRoutes();
  }

  void _toggleSortDir() {
    setState(() {
      _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      _currentPage = 1;
    });
    _loadRoutes();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Barra de Busca ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Buscar rotas...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (_) => _onSearch(_searchController.text),
          ),
        ),

        // --- Barra de Controles (Ordenação, Paginação) ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Dropdown de Ordenação
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(
                    value: 'route_name',
                    child: Text('Nome'),
                  ),
                  DropdownMenuItem(
                    value: 'waypoints_count',
                    child: Text('Waypoints'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _changeSortBy(value);
                  }
                },
              ),

              // Botão de Direção de Ordenação
              IconButton(
                icon: Icon(
                  _sortDir == 'asc'
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                ),
                onPressed: _toggleSortDir,
                tooltip: _sortDir == 'asc'
                    ? 'Ordenar decrescente'
                    : 'Ordenar crescente',
              ),
            ],
          ),
        ),

        // --- Conteúdo Principal ---
        Expanded(
          child: _buildContent(),
        ),

        // --- Controles de Paginação ---
        if (!_isLoading && _currentListing.total > 0)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed:
                      _currentListing.hasPreviousPage ? _previousPage : null,
                ),
                Text(
                  'Página ${_currentListing.page} de ${_currentListing.totalPages}',
                  style: const TextStyle(fontSize: 14),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: _currentListing.hasNextPage ? _nextPage : null,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 12),
            Text(_errorMessage!),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => _loadRoutes(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_currentListing.data.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.route_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Nenhuma rota encontrada.'),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _currentListing.data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final route = _currentListing.data[index];

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(context, route, index);
        }

        return RunningRouteListItem(
          route: route,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        );
      },
    );
  }
}
