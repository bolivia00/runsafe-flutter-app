import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/domain/repositories/waypoint_repository.dart';
import 'package:runsafe/domain/entities/waypoint.dart';
import 'package:runsafe/widgets/forms/waypoint_form_dialog.dart';

// 1. StatefulWidget com o mixin de animação (dos slides) [cite: 76-80]
class WaypointListPage extends StatefulWidget {
  const WaypointListPage({super.key});

  @override
  State<WaypointListPage> createState() => _WaypointListPageState();
}

class _WaypointListPageState extends State<WaypointListPage>
    with SingleTickerProviderStateMixin {
  
  // Variáveis de estado da UI (dos slides) [cite: 81-89]
  bool _showTip = true;
  bool _showTutorial = false;
  
  // Controladores para a animação do FAB (dos slides) [cite: 90-91]
  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    
    // 2. Lógica de Animação do FAB (dos slides) [cite: 101-113]
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this, 
    );
    _fabScale = Tween<double>(begin: 1.0, end: 1.15).animate( 
      CurvedAnimation(parent: _fabController, curve: Curves.elasticInOut),
    );

    // Bônus: A animação do FAB só deve pulsar se a lista estiver vazia.
    // Usamos um 'addPostFrameCallback' para verificar a lista após a primeira renderização.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // [cite: 112]
      if (mounted && context.read<WaypointRepository>().waypoints.isEmpty && _showTip) {
        _fabController.repeat(reverse: true); 
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose(); // [cite: 117]
    super.dispose();
  }

  /// Função para ADICIONAR waypoint [cite: 234-241]
  void _addWaypoint(BuildContext context) async {
    final repository = context.read<WaypointRepository>();
    final newWaypoint = await showWaypointFormDialog(context);

    if (newWaypoint != null) {
      repository.addWaypoint(newWaypoint);
      
      // Quando o usuário adiciona um item, escondemos a dica
      // e paramos a animação do FAB.
      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  /// Função para EDITAR waypoint
  void _editWaypoint(BuildContext context, Waypoint waypointToEdit) async {
    final repository = context.read<WaypointRepository>();
    final updatedWaypoint = await showWaypointFormDialog(
      context,
      initial: waypointToEdit, // [cite: 311]
    );

    if (updatedWaypoint != null) {
      repository.editWaypoint(updatedWaypoint);
    }
  }

  /// 3. Layout da tela com Stack (dos slides) [cite: 133-154]
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pontos de Rota (Waypoints)'),
        actions: [
          // Botão para reativar o tutorial (bônus)
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () => setState(() => _showTutorial = true),
          ),
        ],
      ),
      floatingActionButton: _buildFab(context), // [cite: 151]
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      
      body: Stack( // [cite: 134]
        children: [
          // 1. O conteúdo principal (nossa lista)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Consumer<WaypointRepository>(
                builder: (context, repository, child) {
                  return _buildBody(context, repository.waypoints);
                },
              ),
            ),
          ),
          
          // 2. O Overlay de Tutorial (se estiver ativo) [cite: 146]
          if (_showTutorial) _buildTutorialOverlay(context),
          
          // 3. O botão de "Opt-Out" da dica [cite: 148]
          _buildOptOutButton(context),
          
          // 4. A "Bolha de Dica" (se estiver ativa) [cite: 150]
          if (_showTip && context.watch<WaypointRepository>().waypoints.isEmpty)
             _buildTipBubble(context),
        ],
      ),
    );
  }

  /// 4. FAB animado (dos slides) [cite: 232-249]
  Widget _buildFab(BuildContext context) {
    return ScaleTransition( // [cite: 232]
      scale: _fabScale, // [cite: 232]
      child: FloatingActionButton(
        onPressed: () => _addWaypoint(context),
        child: const Icon(Icons.add_location_alt),
      ),
    );
  }

  /// 5. Corpo da tela (Estado Vazio vs. Lista) (dos slides) [cite: 250-282]
  Widget _buildBody(BuildContext context, List<Waypoint> waypoints) {
    if (waypoints.isEmpty) { // [cite: 251]
      // Estado Vazio (dos slides) [cite: 252-270]
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Nenhum ponto de rota cadastrado.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              'Use o botão "+" abaixo para adicionar o primeiro ponto.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Lista de Waypoints [cite: 272-278]
    return ListView.separated(
      itemCount: waypoints.length,
      separatorBuilder: (context, index) => const Divider(height: 1), // [cite: 276]
      itemBuilder: (context, index) {
        final waypoint = waypoints[index];
        return Dismissible(
          key: Key(waypoint.timestamp.toIso8601String()), // Usamos o timestamp como chave
          direction: DismissDirection.endToStart,
          
          onDismissed: (direction) {
            context.read<WaypointRepository>().deleteWaypoint(waypoint.timestamp);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ponto de rota excluído.')),
            );
          },
          
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          
          child: ListTile(
            leading: const Icon(Icons.location_pin),
            title: Text('Lat: ${waypoint.latitude.toStringAsFixed(4)}'),
            subtitle: Text('Lon: ${waypoint.longitude.toStringAsFixed(4)}'),
            trailing: Text(
              '${waypoint.timestamp.hour}:${waypoint.timestamp.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              _editWaypoint(context, waypoint);
            },
          ),
        );
      },
    );
  }

  // --- 6. O resto dos métodos de UI (Tutorial, OptOut, TipBubble) ---
  // (São idênticos, apenas muda o texto)

  /// O Overlay de Tutorial (dos slides) [cite: 157-184]
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
                  'Aqui você verá seus pontos de rota salvos.\nUse o botão flutuante para adicionar um novo ponto.',
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

  /// O Botão de Opt-Out (dos slides) [cite: 185-198]
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

  /// A Bolha de Dica (dos slides) [cite: 199-231]
  Widget _buildTipBubble(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: MediaQuery.of(context).padding.bottom + 90, // Posição acima do FAB
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
            'Toque aqui para adicionar um ponto',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}