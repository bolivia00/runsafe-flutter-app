import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/domain/repositories/running_route_repository.dart';
import 'package:runsafe/domain/entities/running_route.dart';
import 'package:runsafe/widgets/forms/running_route_form_dialog.dart';

class RunningRouteListPage extends StatefulWidget {
  const RunningRouteListPage({super.key});

  @override
  State<RunningRouteListPage> createState() => _RunningRouteListPageState();
}

class _RunningRouteListPageState extends State<RunningRouteListPage>
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

  void _editRoute(BuildContext context, RunningRoute routeToEdit) async {
    final repository = context.read<RunningRouteRepository>();
    final updatedRoute = await showRunningRouteFormDialog(
      context,
      initial: routeToEdit, 
    );

    if (updatedRoute != null) {
      repository.editRoute(updatedRoute);
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
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<RunningRouteRepository>(
                builder: (context, repository, child) {
                  return _buildBody(context, repository.routes);
                },
              ),
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

  Widget _buildBody(BuildContext context, List<RunningRoute> routes) {
    if (routes.isEmpty) { 
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.route_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhuma rota cadastrada.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Use o botão "+" abaixo para criar uma nova rota.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: routes.length,
      separatorBuilder: (context, index) => const Divider(height: 1), 
      itemBuilder: (context, index) {
        final route = routes[index];
        return Dismissible(
          key: Key(route.id),
          direction: DismissDirection.endToStart,
          
          onDismissed: (direction) {
            context.read<RunningRouteRepository>().deleteRoute(route.id);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Rota excluída.')),
            );
          },
          
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          
          child: ListTile(
            leading: const Icon(Icons.route),
            title: Text(route.name),
            subtitle: Text('Waypoints: ${route.waypoints.length} - Distância (simulada): ${route.totalDistanceInKm.toStringAsFixed(2)} km'),
            onTap: () {
              _editRoute(context, route);
            },
          ),
        );
      },
    );
  }

  // --- O resto dos métodos de UI (Tutorial, OptOut, TipBubble) ---
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
                  'Aqui você verá suas rotas de corrida.\nUse o botão "+" para adicionar uma nova rota.',
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