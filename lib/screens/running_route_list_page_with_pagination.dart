import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/domain/repositories/running_route_repository.dart';
import 'package:runsafe/domain/dto/running_route_dto.dart';
import 'package:runsafe/widgets/forms/running_route_form_dialog.dart';
import 'package:runsafe/widgets/running_route_list_widget.dart';
import 'package:runsafe/domain/mappers/running_route_mapper.dart';
import 'package:runsafe/domain/mappers/waypoint_mapper.dart';

/// Página de listagem de rotas com suporte a paginação, filtros e busca
/// Integra o novo RunningRouteListWidget com a repository existente
class RunningRouteListPageWithPagination extends StatefulWidget {
  const RunningRouteListPageWithPagination({super.key});

  @override
  State<RunningRouteListPageWithPagination> createState() =>
      _RunningRouteListPageWithPaginationState();
}

class _RunningRouteListPageWithPaginationState
    extends State<RunningRouteListPageWithPagination>
    with SingleTickerProviderStateMixin {
  bool _showTip = true;
  bool _showTutorial = false;

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  // Mapper para converter DTO <-> Entity
  final RunningRouteMapper _mapper =
      RunningRouteMapper(WaypointMapper());

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
      if (mounted && context.read<RunningRouteRepository>().routes.isEmpty && _showTip) {
        _fabController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    super.dispose();
  }

  void _addRoute(BuildContext context) async {
    final repository = context.read<RunningRouteRepository>();
    final newRoute = await showRunningRouteFormDialog(context);

    if (newRoute != null) {
      repository.addRoute(newRoute);

      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  void _editRoute(BuildContext context, RunningRouteDto routeDto) async {
    try {
      // Converter DTO para Entity
      final routeEntity = _mapper.toEntity(routeDto);

      final repository = context.read<RunningRouteRepository>();
      final updatedRoute = await showRunningRouteFormDialog(
        context,
        initial: routeEntity,
      );

      if (updatedRoute != null) {
        repository.editRoute(updatedRoute);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao editar rota: $e')),
      );
    }
  }

  void _deleteRoute(BuildContext context, RunningRouteDto routeDto) async {
    try {
      final repository = context.read<RunningRouteRepository>();
      repository.deleteRoute(routeDto.route_id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar rota: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minhas Rotas de Corrida'),
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
            child: RunningRouteListWidget(
              onEdit: (routeDto) => _editRoute(context, routeDto),
              onDelete: (routeDto) => _deleteRoute(context, routeDto),
            ),
          ),
          if (_showTutorial) _buildTutorialOverlay(context),
          _buildOptOutButton(context),
          if (_showTip && context.watch<RunningRouteRepository>().routes.isEmpty)
            _buildTipBubble(context),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton(
        onPressed: () => _addRoute(context),
        child: const Icon(Icons.route),
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
                  'Aqui você verá suas rotas de corrida com busca, filtros e paginação.\n\nUse o botão "+" para adicionar uma nova rota.\nClique em uma rota para editar.\nDeslize para a esquerda para deletar.',
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
            'Toque aqui para adicionar uma rota',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
