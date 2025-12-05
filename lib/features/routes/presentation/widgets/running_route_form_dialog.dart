import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/routes/domain/entities/running_route.dart';
import 'package:runsafe/features/routes/presentation/providers/waypoints_provider.dart';
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
  final Set<String> _selectedWaypointIds = {};
  bool _isLoadingWaypoints = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial?.name ?? '');
    
    // Se estamos editando, marca os waypoints já existentes na rota
    if (widget.initial != null) {
      for (var wp in widget.initial!.waypoints) {
        _selectedWaypointIds.add(wp.timestamp.toIso8601String());
      }
    }
    
    // Carrega waypoints do provider remoto
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<WaypointsProvider>();
      await provider.loadWaypoints();
      if (mounted) {
        setState(() => _isLoadingWaypoints = false);
      }
    });
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
    
    // 1. Pega o provider de Waypoints
    final waypointsProvider = context.read<WaypointsProvider>();
    
    // 2. Filtra apenas os waypoints selecionados
    final selectedWaypoints = waypointsProvider.waypoints
        .where((wp) => _selectedWaypointIds.contains(wp.timestamp.toIso8601String()))
        .toList();

    // 3. Verifica a invariante de domínio (precisa de pelo menos 1 waypoint)
    if (selectedWaypoints.isEmpty) {
      _showError('Selecione pelo menos 1 waypoint para criar a rota.');
      return;
    }

    try {
      final id = widget.initial?.id ?? const Uuid().v4();
      
      final newRoute = RunningRoute(
        id: id,
        name: name,
        waypoints: selectedWaypoints,
      );

      Navigator.of(context).pop(newRoute);

    } catch (e) {
      _showError(e.toString().replaceAll('ArgumentError: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initial != null;
    final waypointsProvider = context.watch<WaypointsProvider>();
    final availableWaypoints = waypointsProvider.waypoints;

    return AlertDialog(
      title: Text(isEditing ? 'Editar Rota' : 'Adicionar Nova Rota'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome da Rota'),
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              const Text(
                'Waypoints da rota:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              
              if (_isLoadingWaypoints)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (availableWaypoints.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Nenhum waypoint disponível. Cadastre waypoints primeiro.',
                    style: TextStyle(color: Colors.orange),
                  ),
                )
              else
                ...availableWaypoints.map((waypoint) {
                  final id = waypoint.timestamp.toIso8601String();
                  final isSelected = _selectedWaypointIds.contains(id);
                  
                  return CheckboxListTile(
                    dense: true,
                    title: Text(
                      '${waypoint.latitude.toStringAsFixed(4)}, ${waypoint.longitude.toStringAsFixed(4)}',
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      waypoint.timestamp.toString().split('.')[0],
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedWaypointIds.add(id);
                        } else {
                          _selectedWaypointIds.remove(id);
                        }
                      });
                    },
                  );
                }).toList(),
              
              if (_selectedWaypointIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '${_selectedWaypointIds.length} waypoint(s) selecionado(s)',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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