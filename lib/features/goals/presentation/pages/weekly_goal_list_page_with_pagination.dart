import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/data/dtos/weekly_goal_dto.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
import 'package:runsafe/features/goals/presentation/widgets/weekly_goal_list_widget.dart';
import 'package:runsafe/features/goals/data/repositories/weekly_goal_repository.dart';
import 'package:runsafe/core/utils/app_colors.dart';

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

  // --- FUNÇÃO PARA ADICIONAR META (Agora funciona de verdade!) ---
  void _handleAddWeeklyGoal() {
    final TextEditingController kmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nova Meta Semanal'),
          content: TextField(
            controller: kmController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Quantos KM você quer correr?',
              hintText: 'Ex: 15.5',
              border: OutlineInputBorder(),
              suffixText: 'km',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emerald,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                if (kmController.text.isNotEmpty) {
                  final double? target = double.tryParse(kmController.text.replaceAll(',', '.'));
                  
                  if (target != null && target > 0) {
                    // Cria a nova meta
                    final newGoal = WeeklyGoal(
                      targetKm: target,
                      currentKm: 0.0, // Começa zerada
                    );
                    
                    // Salva no repositório
                    Provider.of<WeeklyGoalRepository>(context, listen: false).addGoal(newGoal);
                    
                    Navigator.pop(context); // Fecha o diálogo
                    
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Meta de $target km criada com sucesso!')),
                    );
                  }
                }
              },
              child: const Text('Salvar Meta'),
            ),
          ],
        );
      },
    );
  }

  void _handleEditWeeklyGoal(WeeklyGoalDto goalDto) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Editar meta: ${goalDto.target_km} km (Em breve)')),
    );
  }

  void _handleDeleteWeeklyGoal(WeeklyGoalDto goalDto) {
     // Aqui você deve implementar a lógica para deletar pelo ID
     // Como o DTO as vezes não tem ID na visualização, precisamos garantir isso no futuro.
     // Por enquanto, apenas feedback visual.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Função de deletar em breve.')),
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
                      'Clique aqui para\ncriar sua primeira meta!',
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
      // --- BOTÃO FLUTUANTE CORRIGIDO ---
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton(
          // AQUI: Mudamos a cor para Emerald (Verde Escuro)
          backgroundColor: AppColors.emerald, 
          foregroundColor: Colors.white, // Ícone branco
          onPressed: _handleAddWeeklyGoal,
          tooltip: 'Adicionar meta semanal',
          child: const Icon(Icons.flag),
        ),
      ),
    );
  }
}