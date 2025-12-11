import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

class WeeklyGoalListPageNew extends StatefulWidget {
  const WeeklyGoalListPageNew({super.key});

  @override
  State<WeeklyGoalListPageNew> createState() => _WeeklyGoalListPageNewState();
}

class _WeeklyGoalListPageNewState extends State<WeeklyGoalListPageNew>
    with SingleTickerProviderStateMixin {
  
  bool _showTip = true;
  bool _showTutorial = false;
  
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this, 
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate( 
      CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && context.read<WeeklyGoalsProvider>().items.isEmpty && _showTip) {
        _fabController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose(); 
    super.dispose();
  }

  void _addGoal(BuildContext context) async {
    final targetController = TextEditingController();
    
    final result = await showDialog<double>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova Meta Semanal'),
        content: TextField(
          controller: targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Meta (km)',
            hintText: 'Ex: 10.5',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.flag_circle),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final target = double.tryParse(targetController.text);
              if (target != null && target > 0) {
                Navigator.pop(dialogContext, target);
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Digite uma meta válida (maior que 0)'),
                  ),
                );
              }
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      try {
        final goal = WeeklyGoal(
          userId: 'default-user',
          targetKm: result,
        );
        
        await context.read<WeeklyGoalsProvider>().addGoal(goal);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta adicionada com sucesso!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao adicionar meta: $e')),
          );
        }
      }
      
      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  void _editGoal(BuildContext context, WeeklyGoal goalToEdit) async {
    final targetController = TextEditingController(
      text: goalToEdit.targetKm.toStringAsFixed(1),
    );
    final currentController = TextEditingController(
      text: goalToEdit.currentKm.toStringAsFixed(1),
    );

    final result = await showDialog<Map<String, double>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Meta'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: targetController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Meta (km)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag_circle),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: currentController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Progresso atual (km)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.directions_run),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final target = double.tryParse(targetController.text);
              final current = double.tryParse(currentController.text);
              
              if (target != null && target > 0 && current != null && current >= 0) {
                Navigator.pop(dialogContext, {
                  'target': target,
                  'current': current,
                });
              } else {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(
                    content: Text('Digite valores válidos'),
                  ),
                );
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (result != null && context.mounted) {
      try {
        final updatedGoal = WeeklyGoal(
          id: goalToEdit.id,
          userId: goalToEdit.userId,
          targetKm: result['target']!,
          currentKm: result['current']!,
        );
        
        await context.read<WeeklyGoalsProvider>().updateGoal(updatedGoal);
        
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta atualizada com sucesso!')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro ao atualizar meta: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Metas Semanais'),
        actions: [
          Consumer<WeeklyGoalsProvider>(
            builder: (context, provider, child) {
              return IconButton(
                icon: provider.loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.sync),
                tooltip: 'Sincronizar',
                onPressed: provider.loading ? null : () => provider.syncNow(),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => _showTutorial = true),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<WeeklyGoalsProvider>(
                builder: (context, provider, child) {
                  return _buildBodyWithRefresh(context, provider);
                },
              ),
            ),
          ),
          
          if (_showTutorial) _buildTutorialOverlay(context),
          _buildOptOutButton(context),
          if (_showTip && context.watch<WeeklyGoalsProvider>().items.isEmpty)
             _buildTipBubble(context),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton(
        onPressed: () => _addGoal(context),
        child: const Icon(Icons.flag_circle),
      ),
    );
  }

  /// Corpo com RefreshIndicator para sincronização remota
  Widget _buildBodyWithRefresh(BuildContext context, WeeklyGoalsProvider provider) {
    // Mostra indicador de carregamento se estiver carregando e não há dados
    if (provider.loading && provider.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) {
          await provider.syncNow();
        }
      },
      child: provider.items.isEmpty
          ? _buildEmptyList()
          : _buildGoalsList(context, provider.items),
    );
  }

  /// Lista vazia com scroll habilitado para pull-to-refresh
  Widget _buildEmptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.flag_circle_outlined, size: 72, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhuma meta cadastrada ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Use o botão "+" abaixo para criar sua primeira meta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lista de metas com dismissible
  Widget _buildGoalsList(BuildContext context, List<WeeklyGoal> goals) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: goals.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final goal = goals[index];
        return Dismissible(
          key: Key(goal.id),
          direction: DismissDirection.endToStart,
          
          onDismissed: (direction) async {
            try {
              await context.read<WeeklyGoalsProvider>().remove(goal.id);
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Meta removida com sucesso!')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro ao remover meta: $e')),
                );
              }
            }
          },
          
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          
          child: _buildGoalCard(context, goal),
        );
      },
    );
  }

  /// Card de meta individual
  Widget _buildGoalCard(BuildContext context, WeeklyGoal goal) {
    final progress = goal.progressPercentage;
    final isCompleted = progress >= 1.0;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () => _editGoal(context, goal),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.flag_circle,
                        color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Meta Semanal',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            '${goal.targetKm.toStringAsFixed(1)} km',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isCompleted ? Colors.green : Theme.of(context).primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Theme.of(context).primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${goal.currentKm.toStringAsFixed(1)} km percorridos',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${(goal.targetKm - goal.currentKm).clamp(0, double.infinity).toStringAsFixed(1)} km faltam',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTutorialOverlay(BuildContext context) {
    return GestureDetector(
      onTap: () => setState(() => _showTutorial = false),
      child: Container(
        color: Colors.black54,
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(32),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.info_outline, size: 48, color: Colors.blue),
                  const SizedBox(height: 16),
                  const Text(
                    'Como usar:',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '• Toque no botão + para criar uma nova meta\n'
                    '• Toque em uma meta para editá-la\n'
                    '• Arraste para a esquerda para excluir\n'
                    '• Arraste para baixo para sincronizar\n'
                    '• Use o botão 🔄 para sincronizar manualmente',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => setState(() => _showTutorial = false),
                    child: const Text('Entendi'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptOutButton(BuildContext context) {
    if (!_showTip) return const SizedBox.shrink();
    
    return Positioned(
      top: 8,
      right: 8,
      child: IconButton(
        icon: const Icon(Icons.close, size: 20),
        tooltip: 'Desabilitar dica',
        onPressed: () {
          setState(() => _showTip = false);
          _fabController.stop();
          _fabController.reset();
        },
      ),
    );
  }

  Widget _buildTipBubble(BuildContext context) {
    return Positioned(
      bottom: 90,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8),
          ),
          constraints: const BoxConstraints(maxWidth: 200),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_downward, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Flexible(
                child: Text(
                  'Toque aqui para criar sua primeira meta!',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
