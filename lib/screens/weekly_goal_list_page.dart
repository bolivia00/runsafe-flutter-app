import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/domain/repositories/weekly_goal_repository.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/widgets/forms/weekly_goal_form_dialog.dart';

class WeeklyGoalListPage extends StatefulWidget {
  const WeeklyGoalListPage({super.key});

  @override
  State<WeeklyGoalListPage> createState() => _WeeklyGoalListPageState();
}

class _WeeklyGoalListPageState extends State<WeeklyGoalListPage>
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
      if (mounted && context.read<WeeklyGoalRepository>().goals.isEmpty && _showTip) {
        _fabController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose(); 
    super.dispose();
  }

  /// Função para ADICIONAR meta
  void _addGoal(BuildContext context) async {
    final repository = context.read<WeeklyGoalRepository>();
    final newGoal = await showWeeklyGoalFormDialog(context); 

    if (newGoal != null) {
      repository.addGoal(newGoal);
      
      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  /// Função para EDITAR meta
  void _editGoal(BuildContext context, WeeklyGoal goalToEdit) async {
    final repository = context.read<WeeklyGoalRepository>();
    
    final updatedGoal = await showWeeklyGoalFormDialog(
      context,
      initial: goalToEdit, 
    );

    if (updatedGoal != null) {
      repository.editGoal(updatedGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas Semanais'),
        actions: [
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
              child: Consumer<WeeklyGoalRepository>(
                builder: (context, repository, child) {
                  return _buildBody(context, repository.goals); 
                },
              ),
            ),
          ),
          if (_showTutorial) _buildTutorialOverlay(context),
          _buildOptOutButton(context),
          // Bônus: A dica só aparece se a lista estiver vazia
          if (_showTip && context.watch<WeeklyGoalRepository>().goals.isEmpty)
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
        child: const Icon(Icons.add),
      ),
    );
  }

  /// O Corpo da tela (Estado Vazio vs. Lista)
  Widget _buildBody(BuildContext context, List<WeeklyGoal> goals) {
    if (goals.isEmpty) {
      // --- CÓDIGO DO ESTADO VAZIO (CORRIGIDO) ---
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inbox,
              size: 72,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Nenhuma meta cadastrada ainda.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Use o botão "+" abaixo para criar a primeira.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Lista de Metas
    return ListView.builder(
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final progress = (goal.progressPercentage * 100).toStringAsFixed(0);

        // --- 'Dismissible' para Excluir ---
        return Dismissible(
          key: Key(goal.id), // Agora 'goal.id' existe!
          direction: DismissDirection.endToStart, 
          
          onDismissed: (direction) {
            context.read<WeeklyGoalRepository>().deleteGoal(goal.id); //
            
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Meta excluída com sucesso.')),
            );
          },
          
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          
          child: ListTile(
            title: Text('Meta: ${goal.targetKm} km'),
            subtitle: Text('Progresso: ${goal.currentKm} km ($progress%)'),
            trailing: CircularProgressIndicator(
              value: goal.progressPercentage,
              backgroundColor: Colors.grey.shade300,
            ),
            onTap: () {
              _editGoal(context, goal); //
            },
          ),
        );
      },
    );
  }

  // --- O resto dos métodos (Tutorial, OptOut, TipBubble) ---
  
  Widget _buildTutorialOverlay(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black45,
        alignment: Alignment.center,
        child: Card(
          margin: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Tutorial', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                const Text(
                  'Aqui você verá suas metas semanais.\nUse o botão flutuante para adicionar uma nova meta.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() => _showTutorial = false),
                  child: const Text('Entendi'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptOutButton(BuildContext context) {
    return Positioned(
      left: 16,
      bottom: MediaQuery.of(context).padding.bottom + 12,
      child: TextButton(
        onPressed: () => setState(() {
          _showTip = false;
          _fabController.stop();
          _fabController.reset();
        }),
        child: const Text(
          'Não exibir dica novamente',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTipBubble(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 90, // Posição acima do FAB
      child: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          final v = _fabController.value;
          return Transform.translate(
            offset: Offset(0, 5 * (1 - v)),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(8.0),
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
          ),
          child: Text(
            'Toque aqui para adicionar uma meta',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}