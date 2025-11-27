import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/safety_alert_dto.dart';
import 'package:runsafe/domain/models/listing_response.dart';
import 'package:runsafe/services/safety_alerts_local_dao.dart';
import 'package:runsafe/widgets/safety_alert_list_item.dart';

/// Widget de listagem de alertas de segurança com suporte a paginação, filtros e loading
class SafetyAlertListWidget extends StatefulWidget {
  /// Callback quando um alerta é selecionado para edição
  final Function(SafetyAlertDto)? onEdit;

  /// Callback quando um alerta é excluído
  final Function(SafetyAlertDto)? onDelete;

  /// Callback para renderizar item customizado (opcional)
  final Widget Function(BuildContext, SafetyAlertDto, int)? itemBuilder;

  const SafetyAlertListWidget({
    super.key,
    this.onEdit,
    this.onDelete,
    this.itemBuilder,
  });

  @override
  State<SafetyAlertListWidget> createState() => _SafetyAlertListWidgetState();
}

class _SafetyAlertListWidgetState extends State<SafetyAlertListWidget> {
  final SafetyAlertsLocalDaoSharedPrefs _dao =
      SafetyAlertsLocalDaoSharedPrefs();

  late ListingResponse<SafetyAlertDto> _currentListing;
  bool _isLoading = true;
  String? _errorMessage;

  final TextEditingController _searchController = TextEditingController();
  int _currentPage = 1;
  final int _pageSize = 20;
  String _sortBy = 'timestamp';
  String _sortDir = 'desc';
  int? _selectedSeverity;

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlerts({int page = 1}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final filters = <String, dynamic>{};
      if (_searchController.text.isNotEmpty) {
        filters['q'] = _searchController.text;
      }
      if (_selectedSeverity != null) {
        filters['severity'] = _selectedSeverity;
      }

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
        _errorMessage = 'Erro ao carregar alertas: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearch(String query) {
    _currentPage = 1;
    _loadAlerts();
  }

  void _nextPage() {
    if (_currentListing.hasNextPage) {
      _loadAlerts(page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentListing.hasPreviousPage) {
      _loadAlerts(page: _currentPage - 1);
    }
  }

  void _changeSortBy(String field) {
    setState(() {
      _sortBy = field;
      _currentPage = 1;
    });
    _loadAlerts();
  }

  void _toggleSortDir() {
    setState(() {
      _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
      _currentPage = 1;
    });
    _loadAlerts();
  }

  void _filterBySeverity(int? severity) {
    setState(() {
      _selectedSeverity = severity;
      _currentPage = 1;
    });
    _loadAlerts();
  }

  String _getSeverityLabel(int severity) {
    switch (severity) {
      case 1:
        return 'Baixa';
      case 2:
        return 'Média-Baixa';
      case 3:
        return 'Média';
      case 4:
        return 'Média-Alta';
      case 5:
        return 'Alta';
      default:
        return 'Desconhecida';
    }
  }

  Color _getSeverityColor(int severity) {
    switch (severity) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.lime;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.deepOrange;
      case 5:
        return Colors.red;
      default:
        return Colors.grey;
    }
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
              hintText: 'Buscar alertas...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            onChanged: (_) => _onSearch(_searchController.text),
          ),
        ),

        // --- Filtros e Ordenação ---
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Filtro de Severidade
                Wrap(
                  spacing: 4,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      FilterChip(
                        label: Text(_getSeverityLabel(i)),
                        selected: _selectedSeverity == i,
                        backgroundColor: _getSeverityColor(i).withOpacity(0.2),
                        selectedColor: _getSeverityColor(i),
                        labelStyle: TextStyle(
                          color: _selectedSeverity == i ? Colors.white : Colors.black,
                        ),
                        onSelected: (isSelected) {
                          _filterBySeverity(isSelected ? i : null);
                        },
                      ),
                  ],
                ),
                const SizedBox(width: 8),
                // Dropdown de Ordenação
                DropdownButton<String>(
                  value: _sortBy,
                  items: const [
                    DropdownMenuItem(
                      value: 'timestamp',
                      child: Text('Data'),
                    ),
                    DropdownMenuItem(
                      value: 'severity',
                      child: Text('Severidade'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      _changeSortBy(value);
                    }
                  },
                ),
                // Botão de Direção
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
              onPressed: () => _loadAlerts(),
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
            const Icon(Icons.security_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('Nenhum alerta encontrado.'),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _currentListing.data.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final alert = _currentListing.data[index];

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(context, alert, index);
        }

        return SafetyAlertListItem(
          alert: alert,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
          getSeverityColor: _getSeverityColor,
          getSeverityLabel: _getSeverityLabel,
        );
      },
    );
  }
}
