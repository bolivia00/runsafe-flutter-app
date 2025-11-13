import 'package:flutter/material.dart';
import 'package:runsafe/domain/entities/safety_alert.dart';
import 'package:uuid/uuid.dart';

Future<SafetyAlert?> showSafetyAlertFormDialog(
  BuildContext context, {
  SafetyAlert? initial,
}) {
  return showDialog<SafetyAlert>(
    context: context,
    builder: (ctx) => _SafetyAlertFormDialog(initial: initial),
  );
}

class _SafetyAlertFormDialog extends StatefulWidget {
  final SafetyAlert? initial;
  const _SafetyAlertFormDialog({this.initial});

  @override
  State<_SafetyAlertFormDialog> createState() => _SafetyAlertFormDialogState();
}

class _SafetyAlertFormDialogState extends State<_SafetyAlertFormDialog> {
  late final TextEditingController _descriptionController;
  AlertType _selectedType = AlertType.other;
  double _severity = 1.0;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _selectedType = initial?.type ?? AlertType.other;
    _severity = (initial?.severity ?? 1).toDouble();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
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
    final description = _descriptionController.text.trim();
    if (description.isEmpty) {
      _showError('A descrição é obrigatória.');
      return;
    }
    
    final id = widget.initial?.id ?? const Uuid().v4();
    final severityInt = _severity.round();

    try {
      final newAlert = SafetyAlert(
        id: id,
        description: description,
        type: _selectedType,
        timestamp: DateTime.now(),
        severity: severityInt,
      );
      Navigator.of(context).pop(newAlert);
    } catch (e) {
      _showError(e.toString().replaceAll('ArgumentError: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Alerta' : 'Adicionar Alerta de Segurança'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descrição do Alerta'),
              textInputAction: TextInputAction.next,
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            const Text('Tipo de Alerta', style: TextStyle(fontSize: 12)),
            DropdownButton<AlertType>(
              value: _selectedType,
              isExpanded: true,
              items: AlertType.values.map((type) {
                return DropdownMenuItem(
                  value: type,
                  child: Text(type.toString().split('.').last),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedType = value);
                }
              },
            ),
            const SizedBox(height: 16),
            Text('Severidade: ${_severity.round()}', style: const TextStyle(fontSize: 12)),
            Slider(
              value: _severity,
              min: 1.0,
              max: 5.0,
              divisions: 4,
              label: _severity.round().toString(),
              onChanged: (value) {
                setState(() => _severity = value);
              },
            ),
          ],
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