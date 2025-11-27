import 'package:flutter/material.dart';
import 'package:runsafe/features/goals/data/dtos/weekly_goal_dto.dart';
import 'package:runsafe/core/models/listing_response.dart';
import 'package:runsafe/core/services/weekly_goals_local_dao.dart';
import 'package:runsafe/features/goals/presentation/widgets/weekly_goal_list_item.dart';

/// Widget de listagem de metas semanais com suporte a paginação e filtros
class WeeklyGoalListWidget extends StatefulWidget {
  /// Callback quando uma meta é selecionada para edição
  final Function(WeeklyGoalDto)? onEdit;

  /// Callback quando uma meta é excluída
  final Function(WeeklyGoalDto)? onDelete;

  /// Callback para renderizar item customizado (opcional)
  final Widget Function(BuildContext, WeeklyGoalDto, int)? itemBuilder;

  const WeeklyGoalListWidget({
    super.key,
    this.onEdit,
    this.onDelete,
    this.itemBuilder,
  });

  @override
  State<WeeklyGoalListWidget> createState() => _WeeklyGoalListWidgetState();
}

class _WeeklyGoalListWidgetState extends State<WeeklyGoalListWidget> {
  final WeeklyGoalsLocalDaoSharedPrefs _dao =
      WeeklyGoalsLocalDaoSharedPrefs();

  late ListingResponse<WeeklyGoalDto> _currentListing;
  bool _isLoading = true;
  String? _errorMessage;

  int _currentPage = 1;
  final int _pageSize = 20;
  String _sortBy = 'target_km';
  String _sortDir = 'desc';
  double? _minTargetKm;
  double? _minProgressPercent;

  late TextEditingController _minTargetKmController;
  late TextEditingController _minProgressController;

  @override
  void initState() {
    super.initState();
    _minTargetKmController = TextEditingController();
    _minProgressController = TextEditingController();
    _loadGoals();
  }

  @override
  void dispose() {
    _minTargetKmController.dispose();
    _minProgressController.dispose();
    super.dispose();
  }

  Future<void> _loadGoals({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filters = <String, dynamic>{};
      if (_minTargetKm != null) filters['min_target_km'] = _minTargetKm;
      if (_minProgressPercent != null) filters['min_progress_percent'] = _minProgressPercent;

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
        _errorMessage = 'Erro ao carregar metas: $e';
        _isLoading = false;
      });
    }
  }

  void _nextPage() {
    if (_currentListing.hasNextPage) {
      _loadGoals(page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentListing.hasPreviousPage) {
      _loadGoals(page: _currentPage - 1);
    }
  }

  void _changeSortBy(String field) {
    setState(() {
      _sortBy = field;
      _currentPage = 1;
    });
    _loadGoals();
  }

  void _toggleSortDir() {
    setState(() {
      _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      _currentPage = 1;
    });
    _loadGoals();
  }

  void _applyFilters() {
    try {
      _minTargetKm = _minTargetKmController.text.isNotEmpty
          ? double.parse(_minTargetKmController.text)
          : null;
      _minProgressPercent = _minProgressController.text.isNotEmpty
          ? double.parse(_minProgressController.text)
          : null;

      _currentPage = 1;
      _loadGoals();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valores de filtro inválidos')),
      );
    }
  }

  void _clearFilters() {
    _minTargetKmController.clear();
    _minProgressController.clear();
    setState(() {
      _minTargetKm = null;
      _minProgressPercent = null;
      _currentPage = 1;
    });
    _loadGoals();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // --- Filtros ---
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ExpansionTile(
            title: const Text('Filtrar Metas'),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _minTargetKmController,
                      decoration: const InputDecoration(
                        labelText: 'Distância mínima (km)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _minProgressController,
                      decoration: const InputDecoration(
                        labelText: 'Progresso mínimo (%)',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                          onPressed: _applyFilters,
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

        // --- Ordenação ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(value: 'target_km', child: Text('Distância')),
                  DropdownMenuItem(value: 'progress', child: Text('Progresso')),
                  DropdownMenuItem(value: 'current_km', child: Text('Atual')),
                ],
                onChanged: (value) {
                  if (value != null) _changeSortBy(value);
                },
              ),
              IconButton(
                icon: Icon(
                  _sortDir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                ),
                onPressed: _toggleSortDir,
                tooltip: _sortDir == 'asc' ? 'Ordenar decrescente' : 'Ordenar crescente',
              ),
            ],
          ),
        ),

        // --- Conteúdo Principal ---
        Expanded(
          child: _buildContent(),
        ),

        // --- Paginação ---
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
              onPressed: () => _loadGoals(),
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_currentListing.data.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.flag_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('Nenhuma meta encontrada.'),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _currentListing.data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final goal = _currentListing.data[index];

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(context, goal, index);
        }

        return WeeklyGoalListItem(
          goal: goal,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        );
      },
    );
  }
}


