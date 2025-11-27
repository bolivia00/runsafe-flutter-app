import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/routes/domain/entities/running_route.dart';
import 'package:runsafe/features/routes/domain/entities/waypoint.dart';
import 'package:runsafe/features/routes/data/repositories/waypoint_repository.dart';
import 'package:uuid/uuid.dart';

/// Função pública para chamar o formulário
Future<RunningRoute?> showRunningRouteFormDialog(
  BuildContext context, {
  RunningRoute? initial,
}) {
  return showDialog<RunningRoute>(
    context: context,
    builder: (ctx) => _RunningRouteFormDialog(initial: initial),
  );
}

class _RunningRouteFormDialog extends StatefulWidget {
  final RunningRoute? initial;
  const _RunningRouteFormDialog({this.initial});

  @override
  State<_RunningRouteFormDialog> createState() => _RunningRouteFormDialogState();
}

class _RunningRouteFormDialogState extends State<_RunningRouteFormDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _onConfirm() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _showError('O nome da rota é obrigatório.');
      return;
    }
    
    // 1. Pega o repositório de Waypoints (precisamos do 'listen: false' aqui)
    final waypointRepository = context.read<WaypointRepository>();
    
    // 2. Pega a lista de waypoints que o usuário já cadastrou
    List<Waypoint> waypointsToUse;
    
    // Se estamos editando, mantemos os waypoints originais
    if (widget.initial != null) {
      waypointsToUse = widget.initial!.waypoints;
    } else {
      // Se estamos criando, "atribuímos" todos os waypoints existentes a esta nova rota
      waypointsToUse = waypointRepository.waypoints;
    }

    // 3. Verifica a invariante de domínio (precisa de pelo menos 1 waypoint)
    if (waypointsToUse.isEmpty) {
      _showError('Não é possível criar uma rota. Adicione Waypoints primeiro.');
      return;
    }

    try {
      final id = widget.initial?.id ?? const Uuid().v4();
      
      final newRoute = RunningRoute(
        id: id,
        name: name,
        waypoints: waypointsToUse,
      );

      Navigator.of(context).pop(newRoute);

    } catch (e) {
      _showError(e.toString().replaceAll('ArgumentError: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final waypointsCount = context.watch<WaypointRepository>().waypoints.length;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Rota' : 'Adicionar Nova Rota'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nome da Rota'),
              textInputAction: TextInputAction.done,
            ),
            if (!isEditing)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Text(
                  'Esta rota será criada usando os $waypointsCount Waypoints já cadastrados.',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
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