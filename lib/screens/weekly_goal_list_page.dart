import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/domain/repositories/weekly_goal_repository.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/widgets/forms/weekly_goal_form_dialog.dart';

// 1. Convertemos para StatefulWidget e adicionamos o 'mixin' de animação
class WeeklyGoalListPage extends StatefulWidget {
  const WeeklyGoalListPage({super.key});

  @override
  State<WeeklyGoalListPage> createState() => _WeeklyGoalListPageState();
}

// 2. A DECLARAÇÃO DA CLASSE CORRIGIDA (com a chave '{' no final)
class _WeeklyGoalListPageState extends State<WeeklyGoalListPage>
    with SingleTickerProviderStateMixin {
      
  // --- Variáveis de Estado da UI (dos slides) ---
  bool _showTip = true;
  bool _showTutorial = false;
  
  // Controladores para a animação do FAB (dos slides)
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    
    // --- Lógica de Animação do FAB (dos slides) ---
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this, 
    );
    
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate( 
      CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut),
    );

    // Se a dica estiver ativa, o FAB começa a pulsar
    if (_showTip) {
      _fabController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _fabController.dispose(); 
    super.dispose();
  }

  /// Função para adicionar meta (lógica que já tínhamos + lógica dos slides)
  void _addGoal(BuildContext context) async {
    final repository = context.read<WeeklyGoalRepository>();
    final newGoal = await showWeeklyGoalFormDialog(context);

    if (newGoal != null) {
      repository.addGoal(newGoal);
      
      // Quando o usuário adiciona um item, escondemos a dica
      // e paramos a animação do FAB.
      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  /// Constrói o layout da tela usando um Stack (dos slides)
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas Semanais'),
        actions: [
          // Botão para reativar o tutorial (bônus)
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => _showTutorial = true),
          ),
        ],
      ),
      // O FAB agora é um widget separado
      floatingActionButton: _buildFab(context),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      body: Stack(
        children: [
          // 1. O conteúdo principal (nossa lista)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              // O buildBody agora é um Consumer
              child: Consumer<WeeklyGoalRepository>(
                builder: (context, repository, child) {
                  return _buildBody(repository.goals); // Passa a lista
                },
              ),
            ),
          ),
          
          // 2. O Overlay de Tutorial (se estiver ativo)
          if (_showTutorial) _buildTutorialOverlay(context),
          
          // 3. O botão de "Opt-Out" da dica
          _buildOptOutButton(context),
          
          // 4. A "Bolha de Dica" (se estiver ativa)
          if (_showTip) _buildTipBubble(context),
        ],
      ),
    );
  }

  /// O FAB animado (dos slides)
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
  Widget _buildBody(List<WeeklyGoal> goals) {
    if (goals.isEmpty) {
      // Estado Vazio (dos slides)
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

    // Lista de Metas (Nossa lógica de ontem)
    return ListView.builder(
      itemCount: goals.length,
      itemBuilder: (context, index) {
        final goal = goals[index];
        final progress = (goal.progressPercentage * 100).toStringAsFixed(0);

        return ListTile(
          title: Text('Meta: ${goal.targetKm} km'),
          subtitle: Text('Progresso: ${goal.currentKm} km ($progress%)'),
          trailing: CircularProgressIndicator(
            value: goal.progressPercentage,
            backgroundColor: Colors.grey.shade300,
          ),
        );
      },
    );
  }

  /// O Overlay de Tutorial (dos slides)
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

  /// O Botão de Opt-Out (dos slides)
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

  /// A Bolha de Dica (dos slides)
  Widget _buildTipBubble(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 90, // Posição acima do FAB
      child: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          // Animação de "flutuar" (dos slides)
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