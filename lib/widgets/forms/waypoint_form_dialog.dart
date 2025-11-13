import 'package:flutter/material.dart';
import 'package:runsafe/domain/entities/waypoint.dart';

/// Função pública para chamar o formulário
Future<Waypoint?> showWaypointFormDialog(
  BuildContext context, {
  Waypoint? initial,
}) {
  return showDialog<Waypoint>(
    context: context,
    builder: (ctx) => _WaypointFormDialog(initial: initial),
  );
}

class _WaypointFormDialog extends StatefulWidget {
  final Waypoint? initial;
  const _WaypointFormDialog({this.initial});

  @override
  State<_WaypointFormDialog> createState() => _WaypointFormDialogState();
}

class _WaypointFormDialogState extends State<_WaypointFormDialog> {
  late final TextEditingController _latController;
  late final TextEditingController _lonController;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _latController = TextEditingController(text: initial?.latitude.toString() ?? '');
    _lonController = TextEditingController(text: initial?.longitude.toString() ?? '');
    _selectedDate = initial?.timestamp ?? DateTime.now();
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onConfirm() {
    final latText = _latController.text.trim();
    final lonText = _lonController.text.trim();

    if (latText.isEmpty || lonText.isEmpty) {
      _showError('Latitude e Longitude são obrigatórias.');
      return;
    }

    final latitude = double.tryParse(latText);
    final longitude = double.tryParse(lonText);

    if (latitude == null || longitude == null) {
      _showError('Valores devem ser números válidos (ex: -23.5505).');
      return;
    }
    
    final timestamp = widget.initial?.timestamp ?? DateTime.now();

    try {
      final newWaypoint = Waypoint(
        latitude: latitude,
        longitude: longitude,
        timestamp: timestamp,
      );

      Navigator.of(context).pop(newWaypoint);

    } catch (e) {
      _showError(e.toString().replaceAll('ArgumentError: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Ponto' : 'Adicionar Ponto de Rota'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _latController,
              decoration: const InputDecoration(labelText: 'Latitude'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _lonController,
              decoration: const InputDecoration(labelText: 'Longitude'),
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              textInputAction: TextInputAction.done,
            ),
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text('Data/Hora: ${_selectedDate.toLocal()}', style: const TextStyle(color: Colors.grey)),
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