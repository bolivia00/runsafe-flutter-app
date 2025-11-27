import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/routes/data/repositories/waypoint_repository.dart';
import 'package:runsafe/features/routes/data/dtos/waypoint_dto.dart';
import 'package:runsafe/features/routes/domain/entities/waypoint.dart';
import 'package:runsafe/features/routes/presentation/widgets/waypoint_list_widget.dart';

/// Página de listagem de waypoints com suporte a paginação e filtros por coordenadas
class WaypointListPageWithPagination extends StatefulWidget {
  const WaypointListPageWithPagination({super.key});

  @override
  State<WaypointListPageWithPagination> createState() =>
      _WaypointListPageWithPaginationState();
}

class _WaypointListPageWithPaginationState
    extends State<WaypointListPageWithPagination>
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
      if (mounted && context.read<WaypointRepository>().waypoints.isEmpty && _showTip) {
        _fabController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _addWaypoint(BuildContext context) async {
    final repository = context.read<WaypointRepository>();
    final latController = TextEditingController();
    final lonController = TextEditingController();

    final result = await showDialog<Waypoint>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Novo Waypoint'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: latController,
              decoration: const InputDecoration(
                labelText: 'Latitude (-90 a 90)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: lonController,
              decoration: const InputDecoration(
                labelText: 'Longitude (-180 a 180)',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              try {
                final lat = double.parse(latController.text);
                final lon = double.parse(lonController.text);
                final waypoint = Waypoint(
                  latitude: lat,
                  longitude: lon,
                  timestamp: DateTime.now(),
                );
                Navigator.pop(context, waypoint);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            },
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );

    if (result != null && mounted) {
      repository.addWaypoint(result);

      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  void _deleteWaypoint(BuildContext context, WaypointDto waypointDto) async {
    try {
      final repository = context.read<WaypointRepository>();
      // Encontrar o waypoint na repository e deletar
      final waypoint = repository.waypoints.firstWhere(
        (w) => w.timestamp.toIso8601String() == waypointDto.ts,
        orElse: () => Waypoint(
          latitude: waypointDto.lat,
          longitude: waypointDto.lon,
          timestamp: DateTime.parse(waypointDto.ts),
        ),
      );
      repository.deleteWaypoint(waypoint.timestamp);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar waypoint: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos de Rota (Waypoints)'),
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
            child: WaypointListWidget(
              onDelete: (waypointDto) => _deleteWaypoint(context, waypointDto),
            ),
          ),
          if (_showTutorial) _buildTutorialOverlay(context),
          _buildOptOutButton(context),
          if (_showTip && context.watch<WaypointRepository>().waypoints.isEmpty)
            _buildTipBubble(context),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton(
        onPressed: () => _addWaypoint(context),
        child: const Icon(Icons.location_on),
      ),
    );
  }

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
                  'Aqui você verá seus waypoints com paginação e filtros por coordenadas.\n\nUse o botão "+" para adicionar um novo waypoint.\nDeslize para a esquerda para deletar.',
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
      bottom: MediaQuery.of(context).padding.bottom + 90,
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
            'Toque aqui para adicionar um waypoint',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
