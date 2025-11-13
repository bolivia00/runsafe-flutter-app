import 'package:flutter/material.dart';
import 'package:runsafe/domain/entities/weekly_goal.dart'; // Importa sua Entidade!

/// Esta é a função "pública" que a sua tela vai chamar.
/// Ela retorna a Entidade pronta, ou null se o usuário cancelar.
Future<WeeklyGoal?> showWeeklyGoalFormDialog(
  BuildContext context, {
  WeeklyGoal? initial, // Opcional, para o modo "Editar"
}) {
  return showDialog<WeeklyGoal>(
    context: context,
    builder: (ctx) => _WeeklyGoalFormDialog(initial: initial),
  );
}

/// Este é o widget interno do formulário.
class _WeeklyGoalFormDialog extends StatefulWidget {
  final WeeklyGoal? initial;
  const _WeeklyGoalFormDialog({this.initial});

  @override
  State<_WeeklyGoalFormDialog> createState() => _WeeklyGoalFormDialogState();
}

class _WeeklyGoalFormDialogState extends State<_WeeklyGoalFormDialog> {
  final _formKey = GlobalKey<FormState>();
  
  // 1. Controladores para os campos do formulário
  late final TextEditingController _targetKmController;
  late final TextEditingController _currentKmController;

  // 2. Inicialização: preenche os campos se estiver em modo "Editar"
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

  // 3. Limpeza: faz o dispose dos controllers
  @override
  void dispose() {
    _targetKmController.dispose();
    _currentKmController.dispose();
    super.dispose();
  }

  // 4. Feedback de Erro (conforme o PDF)
  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  // 5. Ação de Confirmação (o "coração" da lógica)
  void _onConfirm() {
    // Validação mínima da UI
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

    // 6. Defesa em Profundidade: A UI tenta criar a Entidade.
    // A Entidade (nosso código de antes) vai validar as regras de negócio
    // (invariantes) e pode "falhar" (lançar um erro).
    try {
      final newGoal = WeeklyGoal(
        targetKm: targetKm,
        currentKm: currentKm,
      );

      // 7. Sucesso! Retorna a entidade pronta
      Navigator.of(context).pop(newGoal);

    } catch (e) {
      // Exceção! A Entidade recusou os dados (ex: targetKm <= 0)
      // Mostra o erro da nossa própria Entidade para o usuário.
      _showError(e.toString().replaceAll('ArgumentError: ', ''));
    }
  }

  // 8. Construção da UI (AlertDialog)
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
                decoration: const InputDecoration(labelText: 'Meta (em km)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _currentKmController,
                decoration: const InputDecoration(labelText: 'Progresso Atual (em km)'),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null), // Retorna null
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _onConfirm, // Chama nossa lógica de validação
          child: Text(isEditing ? 'Salvar' : 'Adicionar'),
        ),
      ],
    );
  }
}