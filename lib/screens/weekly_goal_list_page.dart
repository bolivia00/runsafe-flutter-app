import 'package:flutter/material.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart';
import 'package:runsafe/widgets/forms/weekly_goal_form_dialog.dart'; // Importa o formulário

// Esta tela é um StatefulWidget porque ela gerencia uma lista local de "items"
class WeeklyGoalListPage extends StatefulWidget {
  const WeeklyGoalListPage({super.key});

  @override
  State<WeeklyGoalListPage> createState() => _WeeklyGoalListPageState();
}

class _WeeklyGoalListPageState extends State<WeeklyGoalListPage> {
  // O estado local que guarda as metas criadas
  final List<WeeklyGoal> _items = [];

  /// Chama o formulário e, se receber uma entidade de volta,
  /// atualiza a lista na tela.
  void _addGoal() async {
    // 1. Chama o formulário que criamos
    final newGoal = await showWeeklyGoalFormDialog(context);

    // 2. Se o usuário não cancelou...
    if (newGoal != null) {
      // 3. Atualiza o estado e insere o item no topo da lista
      setState(() {
        _items.insert(0, newGoal);
      });
    }
  }

  // (No futuro, você adicionaria uma função _editGoal(WeeklyGoal goal) aqui)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Metas Semanais'),
      ),
      // 3. O FAB (Floating Action Button) que chama a dialog
      floatingActionButton: FloatingActionButton(
        onPressed: _addGoal,
        child: const Icon(Icons.add),
      ),
      // 4. O corpo da tela
      body: _buildBody(),
    );
  }

  /// Constrói o corpo, mostrando "Estado Vazio" ou a "Lista"
  Widget _buildBody() {
    if (_items.isEmpty) {
      // 5. Estado Vazio amigável
      return const Center(
        child: Text(
          'Nenhuma meta cadastrada.\nUse o botão "+" para criar sua primeira meta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    // 6. Lista de metas
    return ListView.builder(
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final goal = _items[index];
        final progress = (goal.progressPercentage * 100).toStringAsFixed(0);

        return ListTile(
          title: Text('Meta: ${goal.targetKm} km'),
          subtitle: Text('Progresso: ${goal.currentKm} km ($progress%)'),
          trailing: CircularProgressIndicator(
            value: goal.progressPercentage,
            backgroundColor: Colors.grey.shade300,
          ),
          // (No futuro, um onTap aqui poderia chamar o modo "Editar")
        );
      },
    );
  }
}