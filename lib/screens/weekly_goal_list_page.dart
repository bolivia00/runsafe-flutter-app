import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// 1. Caminho do Repositório corrigido para "domain/repositories"
import 'package:runsafe/domain/repositories/weekly_goal_repository.dart'; 
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/widgets/forms/weekly_goal_form_dialog.dart';

class WeeklyGoalListPage extends StatelessWidget {
  const WeeklyGoalListPage({super.key});

  void _addGoal(BuildContext context) async {
    // 2. CORREÇÃO DE LINT: Capturamos o repositório ANTES do 'await'
    //    para evitar o aviso 'use_build_context_synchronously'.
    final repository = context.read<WeeklyGoalRepository>();
    final newGoal = await showWeeklyGoalFormDialog(context);

    if (newGoal != null) {
      repository.addGoal(newGoal);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas Semanais'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addGoal(context),
        child: const Icon(Icons.add),
      ),
      body: Consumer<WeeklyGoalRepository>(
        builder: (context, repository, child) {
          // 3. Agora 'repository' é do tipo correto e 'repository.goals' funciona.
          return _buildBody(repository.goals); 
        },
      ),
    );
  }

  Widget _buildBody(List<WeeklyGoal> goals) {
    if (goals.isEmpty) {
      return const Center(
        child: Text(
          'Nenhuma meta cadastrada.\nUse o botão "+" para criar sua primeira meta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

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
}