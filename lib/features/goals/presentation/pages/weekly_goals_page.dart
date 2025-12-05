import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/goals/presentation/providers/weekly_goals_provider.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

/// Página de listagem de metas semanais
class WeeklyGoalsPage extends StatefulWidget {
  final String userId;

  const WeeklyGoalsPage({super.key, required this.userId});

  @override
  State<WeeklyGoalsPage> createState() => _WeeklyGoalsPageState();
}

class _WeeklyGoalsPageState extends State<WeeklyGoalsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<WeeklyGoalsProvider>().load(widget.userId);
      }
    });
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
            icon: const Icon(Icons.add),
            onPressed: () => _showAddGoalDialog(context),
          ),
        ],
      ),
      body: Consumer<WeeklyGoalsProvider>(
        builder: (context, provider, child) {
          if (provider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Erro: ${provider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.load(widget.userId),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }

          if (provider.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                if (mounted) {
                  await provider.syncNow();
                }
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.flag_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Nenhuma meta cadastrada',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (mounted) {
                await provider.syncNow();
              }
            },
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: provider.count,
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final goal = provider.items[index];
                return _GoalCard(
                  goal: goal,
                  onAddRun: (km) => provider.addRunForGoal(goal.id, km),
                  onEdit: () => _showEditGoalDialog(context, provider, goal),
                  onDelete: () => _confirmDelete(context, provider, goal),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Nova Meta Semanal'),
        content: TextField(
          controller: targetController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Meta (km)',
            hintText: 'Ex: 10.5',
            border: OutlineInputBorder(),
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
                final goal = WeeklyGoal(
                  userId: widget.userId,
                  targetKm: target,
                );
                context.read<WeeklyGoalsProvider>().addGoal(goal);
                Navigator.pop(dialogContext);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
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
  }

  void _showEditGoalDialog(
    BuildContext context,
    WeeklyGoalsProvider provider,
    WeeklyGoal goal,
  ) {
    debugPrint('[WeeklyGoals] 🎯 Iniciando abertura de diálogo para meta: ${goal.id}');
    debugPrint('[WeeklyGoals] 📊 Valores atuais - Target: ${goal.targetKm}, Current: ${goal.currentKm}');
    
    final targetController = TextEditingController(text: goal.targetKm.toString());
    final currentController = TextEditingController(text: goal.currentKm.toString());

    try {
      showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          debugPrint('[WeeklyGoals] ✅ Builder do diálogo executado');
          return AlertDialog(
            title: const Text('Editar Meta'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: targetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Meta (km)',
                      hintText: 'Ex: 10.5',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: currentController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Progresso Atual (km)',
                      hintText: 'Ex: 5.2',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  debugPrint('[WeeklyGoals] ❌ Cancelar clicado');
                  Navigator.pop(dialogContext);
                },
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () {
                  debugPrint('[WeeklyGoals] 💾 Salvar clicado');
                  final target = double.tryParse(targetController.text);
                  final current = double.tryParse(currentController.text);
                  
                  if (target != null && target > 0 && current != null && current >= 0) {
                    final updatedGoal = WeeklyGoal(
                      id: goal.id,
                      userId: goal.userId,
                      targetKm: target,
                      currentKm: current,
                    );
                    provider.updateGoal(updatedGoal);
                    Navigator.pop(dialogContext);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Digite valores válidos (meta > 0, progresso >= 0)'),
                      ),
                    );
                  }
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      );
      debugPrint('[WeeklyGoals] 🚀 showDialog executado com sucesso');
    } catch (e, stackTrace) {
      debugPrint('[WeeklyGoals] ❗ ERRO ao abrir diálogo: $e');
      debugPrint('[WeeklyGoals] Stack trace: $stackTrace');
    }
  }

  void _confirmDelete(
    BuildContext context,
    WeeklyGoalsProvider provider,
    WeeklyGoal goal,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remover Meta'),
        content: Text(
          'Deseja remover a meta de ${goal.targetKm.toStringAsFixed(1)} km?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.remove(goal.id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final WeeklyGoal goal;
  final Function(double) onAddRun;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _GoalCard({
    required this.goal,
    required this.onAddRun,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final progress = goal.progressPercentage;
    final isCompleted = progress >= 1.0;

    return Dismissible(
      key: Key(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Confirmar remoção'),
            content: Text(
              'Deseja remover a meta de ${goal.targetKm.toStringAsFixed(1)} km?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Remover'),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        onDelete();
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          title: Text(
            'Meta: ${goal.targetKm.toStringAsFixed(1)} km',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text(
                'Atual: ${goal.currentKm.toStringAsFixed(1)} km',
                style: TextStyle(
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 12,
                  backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(progress * 100).toStringAsFixed(0)}% completo',
                style: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 28)
              else
                const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
          onTap: () {
            onEdit();
          },
        ),
      ),
    );
  }
}
