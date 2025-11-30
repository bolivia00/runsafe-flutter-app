import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/data/dtos/weekly_goal_dto.dart';
import 'package:runsafe/features/goals/data/repositories/weekly_goal_repository.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/presentation/widgets/weekly_goal_list_item.dart';
import 'package:runsafe/core/utils/app_colors.dart';

class WeeklyGoalListWidget extends StatefulWidget {
  final Function(WeeklyGoalDto)? onEdit;
  final Function(WeeklyGoalDto)? onDelete;
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
  // --- ESTADO LOCAL ---
  List<WeeklyGoal> _displayedGoals = []; 
  int _totalItems = 0;
  int _totalPages = 0;
  bool _isLoading = false;

  // Filtros e Paginação
  int _currentPage = 1;
  final int _pageSize = 20;
  
  // Ordenação
  String _sortBy = 'target_km'; 
  String _sortDir = 'desc'; 
  
  // Valores dos filtros
  double? _minTargetKm;
  double? _minProgressPercent;

  late TextEditingController _minTargetKmController;
  late TextEditingController _minProgressController;

  @override
  void initState() {
    super.initState();
    _minTargetKmController = TextEditingController();
    _minProgressController = TextEditingController();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processGoals();
    });
  }

  @override
  void dispose() {
    _minTargetKmController.dispose();
    _minProgressController.dispose();
    super.dispose();
  }

  // --- LÓGICA DE PROCESSAMENTO ---
  void _processGoals({int page = 1}) {
    setState(() => _isLoading = true);

    // 1. Pega os dados BRUTOS do repositório (Entidades)
    final repository = Provider.of<WeeklyGoalRepository>(context, listen: false);
    List<WeeklyGoal> allGoals = List.from(repository.goals);

    // 2. APLICA FILTROS
    if (_minTargetKm != null) {
      allGoals = allGoals.where((g) => g.targetKm >= _minTargetKm!).toList();
    }
    
    if (_minProgressPercent != null) {
      // A entidade retorna 0.0 a 1.0, o filtro é 0 a 100
      allGoals = allGoals.where((g) => (g.progressPercentage * 100) >= _minProgressPercent!).toList();
    }

    // 3. APLICA ORDENAÇÃO
    allGoals.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'target_km':
          comparison = a.targetKm.compareTo(b.targetKm);
          break;
        case 'progress':
          comparison = a.progressPercentage.compareTo(b.progressPercentage);
          break;
        case 'current_km':
          comparison = a.currentKm.compareTo(b.currentKm);
          break;
        default:
          comparison = 0;
      }
      return _sortDir == 'asc' ? comparison : -comparison;
    });

    // 4. APLICA PAGINAÇÃO
    final total = allGoals.length;
    final pages = (total / _pageSize).ceil();
    final safePage = (page > pages && pages > 0) ? pages : (page < 1 ? 1 : page);
    
    final startIndex = (safePage - 1) * _pageSize;
    final endIndex = (startIndex + _pageSize) > total ? total : (startIndex + _pageSize);
    
    List<WeeklyGoal> pagedData = [];
    if (startIndex < total) {
      pagedData = allGoals.sublist(startIndex, endIndex);
    }

    // 5. ATUALIZA A TELA
    setState(() {
      _currentPage = safePage;
      _totalItems = total;
      _totalPages = pages;
      _displayedGoals = pagedData;
      _isLoading = false;
    });
  }

  // --- CONTROLES DE UI ---
  void _nextPage() {
    if (_currentPage < _totalPages) {
      _processGoals(page: _currentPage + 1);
    }
  }

  void _previousPage() {
    if (_currentPage > 1) {
      _processGoals(page: _currentPage - 1);
    }
  }

  void _changeSortBy(String field) {
    setState(() {
      _sortBy = field;
    });
    _processGoals(page: 1);
  }

  void _toggleSortDir() {
    setState(() {
      _sortDir = _sortDir == 'asc' ? 'desc' : 'asc';
    });
    _processGoals(page: 1);
  }

  void _applyFilters() {
    FocusScope.of(context).unfocus();
    try {
      _minTargetKm = _minTargetKmController.text.isNotEmpty
          ? double.parse(_minTargetKmController.text.replaceAll(',', '.'))
          : null;
      _minProgressPercent = _minProgressController.text.isNotEmpty
          ? double.parse(_minProgressController.text.replaceAll(',', '.'))
          : null;
      _processGoals(page: 1);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valores inválidos. Use apenas números.')),
      );
    }
  }

  void _clearFilters() {
    FocusScope.of(context).unfocus();
    _minTargetKmController.clear();
    _minProgressController.clear();
    setState(() {
      _minTargetKm = null;
      _minProgressPercent = null;
    });
    _processGoals(page: 1);
  }

  @override
  Widget build(BuildContext context) {
    // Reage a mudanças no repositório
    final repo = Provider.of<WeeklyGoalRepository>(context);
    if (!_isLoading && repo.goals.length != _totalItems && _minTargetKm == null) {
       // Opcional: Atualizar automaticamente se o número de itens mudar
       // WidgetsBinding.instance.addPostFrameCallback((_) => _processGoals(page: _currentPage));
    }

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          // FILTROS
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ExpansionTile(
              title: const Text('Filtrar Metas', style: TextStyle(fontWeight: FontWeight.bold)),
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
                          prefixIcon: Icon(Icons.straighten),
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
                          prefixIcon: Icon(Icons.percent),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onPressed: _applyFilters,
                              child: const Text('Aplicar Filtros'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.grey[700],
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(color: Colors.grey[400]!),
                              ),
                              onPressed: _clearFilters,
                              child: const Text('Limpar'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ORDENAÇÃO
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _sortBy,
                      icon: const Icon(Icons.sort),
                      items: const [
                        DropdownMenuItem(value: 'target_km', child: Text('Distância')),
                        DropdownMenuItem(value: 'progress', child: Text('Progresso')),
                        DropdownMenuItem(value: 'current_km', child: Text('Km Atual')),
                      ],
                      onChanged: (value) {
                        if (value != null) _changeSortBy(value);
                      },
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      _sortDir == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                      color: AppColors.emerald,
                    ),
                    onPressed: _toggleSortDir,
                    tooltip: _sortDir == 'asc' ? 'Crescente' : 'Decrescente',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // CONTEÚDO
          _buildContent(),

          // PAGINAÇÃO
          if (!_isLoading && _totalItems > 0)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: (_currentPage > 1) ? _previousPage : null,
                  ),
                  Text(
                    'Página $_currentPage de $_totalPages',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: (_currentPage < _totalPages) ? _nextPage : null,
                  ),
                ],
              ),
            ),
           const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_displayedGoals.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(40.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.filter_list_off, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              const Text(
                'Nenhuma meta encontrada.',
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _displayedGoals.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        // --- CONVERSÃO CRÍTICA: Entity -> DTO ---
        final entity = _displayedGoals[index];
        
        final dto = WeeklyGoalDto(
          target_km: entity.targetKm,
          current_progress_km: entity.currentKm,
        );
        // -----------------------------------------

        if (widget.itemBuilder != null) {
          return widget.itemBuilder!(context, dto, index);
        }

        return WeeklyGoalListItem(
          goal: dto,
          onEdit: widget.onEdit,
          onDelete: widget.onDelete,
        );
      },
    );
  }
}