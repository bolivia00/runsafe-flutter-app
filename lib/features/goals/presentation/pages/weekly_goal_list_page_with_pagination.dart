import 'package:flutter/material.dart';
import 'package:runsafe/features/goals/data/dtos/weekly_goal_dto.dart';
import 'package:runsafe/features/goals/presentation/widgets/weekly_goal_list_widget.dart';

/// Página com paginação para listar metas semanais
class WeeklyGoalListPageWithPagination extends StatefulWidget {
  const WeeklyGoalListPageWithPagination({super.key});

  @override
  State<WeeklyGoalListPageWithPagination> createState() =>
      _WeeklyGoalListPageWithPaginationState();
}

class _WeeklyGoalListPageWithPaginationState
    extends State<WeeklyGoalListPageWithPagination>
    with SingleTickerProviderStateMixin {
  bool _showTutorial = false;
  late AnimationController _fabAnimationController;
  late Animation<double> _fabScaleAnimation;
  bool _hasShownTutorial = false;

  @override
  void initState() {
    super.initState();
    _fabAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fabScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _fabAnimationController, curve: Curves.elasticOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFabAnimation();
      if (!_hasShownTutorial) {
        _showTutorialOverlay();
        _hasShownTutorial = true;
      }
    });
  }

  @override
  void dispose() {
    _fabAnimationController.dispose();
    super.dispose();
  }

  void _showFabAnimation() {
    _fabAnimationController.forward().then((_) {
      _fabAnimationController.reverse();
    });
  }

  void _showTutorialOverlay() {
    setState(() => _showTutorial = true);
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() => _showTutorial = false);
      }
    });
  }

  void _handleAddWeeklyGoal() {
    // Implementar navegação ou modal para adicionar meta
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Abrir formulário de adição de meta')),
    );
  }

  void _handleEditWeeklyGoal(WeeklyGoalDto goalDto) {
    // Implementar navegação ou modal para editar meta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Editar meta: ${goalDto.target_km.toStringAsFixed(2)} km'),
      ),
    );
  }

  void _handleDeleteWeeklyGoal(WeeklyGoalDto goalDto) {
    // Remover meta do repositório
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Meta removida'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () {
            // Implementar lógica de desfazer
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas Semanais'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          SafeArea(
            child: WeeklyGoalListWidget(
              onEdit: _handleEditWeeklyGoal,
              onDelete: _handleDeleteWeeklyGoal,
            ),
          ),
          // Tutorial Overlay
          if (_showTutorial)
            Positioned(
              bottom: 100,
              right: 16,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _fabAnimationController,
                    curve: Curves.elasticOut,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Aqui você verá suas metas\nsemanais com filtros\ne paginação.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          onPressed: _handleAddWeeklyGoal,
          tooltip: 'Adicionar meta semanal',
          child: const Icon(Icons.flag_circle),
        ),
      ),
    );
  }
}
