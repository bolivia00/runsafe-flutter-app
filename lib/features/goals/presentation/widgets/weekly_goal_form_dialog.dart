import 'package:flutter/material.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';
// O import do 'uuid' não é mais necessário aqui, pois a própria Entidade já cuida disso.

// --- CORREÇÃO: Removido o 'class' antes de 'Future' ---
Future<WeeklyGoal?> showWeeklyGoalFormDialog(
  BuildContext context, {
  WeeklyGoal? initial,
}) {
  return showDialog<WeeklyGoal>(
    context: context,
    builder: (ctx) => _WeeklyGoalFormDialog(initial: initial),
  );
}

class _WeeklyGoalFormDialog extends StatefulWidget {
  final WeeklyGoal? initial;
  const _WeeklyGoalFormDialog({this.initial});

  @override
  State<_WeeklyGoalFormDialog> createState() => _WeeklyGoalFormDialogState();
}

class _WeeklyGoalFormDialogState extends State<_WeeklyGoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late final TextEditingController _targetKmController;
  late final TextEditingController _currentKmController;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _targetKmController = TextEditingController(
      text: initial?.targetKm.toString() ?? '',
    );
    _currentKmController = TextEditingController(
      text: initial?.currentKm.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _targetKmController.dispose();
    _currentKmController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _onConfirm() {
    final targetText = _targetKmController.text.trim();
    final currentText = _currentKmController.text.trim();

    if (targetText.isEmpty || currentText.isEmpty) {
      _showError('Ambos os campos são obrigatórios.');
      return;
    }

    final targetKm = double.tryParse(targetText);
    final currentKm = double.tryParse(currentText);

    if (targetKm == null || currentKm == null) {
      _showError('Valores devem ser números válidos (ex: 10.5 ou 10).');
      return;
    }

    try {
      // --- LÓGICA DE ID CORRIGIDA ---
      // 1. Se estamos editando, passamos o ID da meta original.
      // 2. Se estamos criando, deixamos o ID nulo (a Entidade vai gerar um novo).
      final newGoal = WeeklyGoal(
        id: widget.initial?.id, 
        targetKm: targetKm,
        currentKm: currentKm,
        // (Se estivermos editando, os outros campos como userId serão mantidos)
      );

      Navigator.of(context).pop(newGoal);

    } catch (e) {
      _showError(e.toString().replaceAll('ArgumentError: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Meta Semanal' : 'Adicionar Meta Semanal'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _targetKmController,
                decoration: const InputDecoration(
                  labelText: 'Meta (em km)',
                  hintText: 'Ex: 10.0',
                  prefixIcon: Icon(Icons.flag),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentKmController,
                decoration: const InputDecoration(
                  labelText: 'Progresso Atual (em km)',
                  hintText: 'Ex: 5.5',
                  prefixIcon: Icon(Icons.directions_run),
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), 
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onConfirm, 
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}