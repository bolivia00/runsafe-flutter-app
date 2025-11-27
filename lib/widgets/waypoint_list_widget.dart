import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/waypoint_dto.dart';
import 'package:runsafe/domain/models/listing_response.dart';
import 'package:runsafe/services/waypoints_local_dao.dart';
import 'package:runsafe/widgets/waypoint_list_item.dart';

/// Widget de listagem de waypoints com suporte a paginação e filtros
class WaypointListWidget extends StatefulWidget {
  /// Callback quando um waypoint é selecionado para edição
  final Function(WaypointDto)? onEdit;

  /// Callback quando um waypoint é excluído
  final Function(WaypointDto)? onDelete;

  /// Callback para renderizar item customizado (opcional)
  final Widget Function(BuildContext, WaypointDto, int)? itemBuilder;

  const WaypointListWidget({
    super.key,
    this.onEdit,
    this.onDelete,
    this.itemBuilder,
  });

  @override
  State<WaypointListWidget> createState() => _WaypointListWidgetState();
}

class _WaypointListWidgetState extends State<WaypointListWidget> {
  final WaypointsLocalDaoSharedPrefs _dao =
      WaypointsLocalDaoSharedPrefs();

  late ListingResponse<WaypointDto> _currentListing;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 20;
  String _sortBy = 'ts';
  String _sortDir = 'desc';

  double? _minLat;
  double? _maxLat;
  double? _minLon;
  double? _maxLon;

  late TextEditingController _minLatController;
  late TextEditingController _maxLatController;
  late TextEditingController _minLonController;
  late TextEditingController _maxLonController;

  @override
  void initState() {
    super.initState();
    _minLatController = TextEditingController();
    _maxLatController = TextEditingController();
    _minLonController = TextEditingController();
    _maxLonController = TextEditingController();
    _loadWaypoints();
  }

  @override
  void dispose() {
    _minLatController.dispose();
    _maxLatController.dispose();
    _minLonController.dispose();
    _maxLonController.dispose();
    super.dispose();
  }

  Future<void> _loadWaypoints({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filters = <String, dynamic>{};
      if (_minLat != null) filters['min_lat'] = _minLat;
      if (_maxLat != null) filters['max_lat'] = _maxLat;
      if (_minLon != null) filters['min_lon'] = _minLon;
      if (_maxLon != null) filters['max_lon'] = _maxLon;

      final listing = await _dao.list(
        page: page,
        pageSize: _pageSize,
        sortBy: _sortBy,
        sortDir: _sortDir,
        filters: filters.isNotEmpty ? filters : null,
      );

      setState(() {
        _currentListing = listing;
        _currentPage = page;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar waypoints: $e';
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentListing.hasNextPage) {
      _loadWaypoints(page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentListing.hasPreviousPage) {
      _loadWaypoints(page: _currentPage - 1);
    }
  }

  void _changeSortBy(String field) {
    setState(() {
      _sortBy = field;
      _currentPage = 1;
    });
    _loadWaypoints();
  }

  void _toggleSortDir() {
    setState(() {
      _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      _currentPage = 1;
    });
    _loadWaypoints();
  }

  void _applyBoundingBox() {
    try {
      _minLat = _minLatController.text.isNotEmpty
          ? double.parse(_minLatController.text)
          : null;
      _maxLat = _maxLatController.text.isNotEmpty
          ? double.parse(_maxLatController.text)
          : null;
      _minLon = _minLonController.text.isNotEmpty
          ? double.parse(_minLonController.text)
          : null;
      _maxLon = _maxLonController.text.isNotEmpty
          ? double.parse(_maxLonController.text)
          : null;

      _currentPage = 1;
      _loadWaypoints();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valores de coordenada inválidos')),
      );
    }
  }

  void _clearFilters() {
    _minLatController.clear();
    _maxLatController.clear();
    _minLonController.clear();
    _maxLonController.clear();
    setState(() {
      _minLat = null;
      _maxLat = null;
      _minLon = null;
      _maxLon = null;
      _currentPage = 1;
    });
    _loadWaypoints();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Filtro de Coordenadas (Bounding Box) ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ExpansionTile(
            title: const Text('Filtrar por Coordenadas'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minLatController,
                            decoration: const InputDecoration(
                              hintText: 'Min Lat (-90 a 90)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _maxLatController,
                            decoration: const InputDecoration(
                              hintText: 'Max Lat',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minLonController,
                            decoration: const InputDecoration(
                              hintText: 'Min Lon (-180 a 180)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _maxLonController,
                            decoration: const InputDecoration(
                              hintText: 'Max Lon',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                              signed: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _applyBoundingBox,
                          child: const Text('Aplicar'),
                        ),
                        OutlinedButton(
                          onPressed: _clearFilters,
                          child: const Text('Limpar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        ),

        // --- Barra de Ordenação ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'ts', child: Text('Data')),
                  DropdownMenuItem(value: 'lat', child: Text('Latitude')),
                  DropdownMenuItem(value: 'lon', child: Text('Longitude')),
                ],
                onChanged: (value) {
                  if (value != null) _changeSortBy(value);
                },
              ),
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
              onPressed: () => _loadWaypoints(),
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
            const Icon(Icons.location_on_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Nenhum waypoint encontrado.'),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _currentListing.data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final waypoint = _currentListing.data[index];

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(context, waypoint, index);
        }

        return WaypointListItem(
          waypoint: waypoint,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        );
      },
    );
  }
}
