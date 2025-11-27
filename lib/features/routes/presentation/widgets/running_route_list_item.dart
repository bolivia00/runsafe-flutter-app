import 'package:flutter/material.dart';
import 'package:runsafe/features/routes/data/dtos/running_route_dto.dart';

/// Item individual de uma rota de corrida na listagem
/// Exibe: ícone, nome, número de waypoints, imagem (se houver)
class RunningRouteListItem extends StatelessWidget {
  final RunningRouteDto route;

  /// Callback quando o item é tocado para edição
  final Function(RunningRouteDto)? onEdit;

  /// Callback quando a rota é deletada (via Dismissible)
  final Function(RunningRouteDto)? onDelete;

  const RunningRouteListItem({
    super.key,
    required this.route,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(route.route_id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        onDelete?.call(route);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rota excluída.')),
        );
      },
      child: ListTile(
        leading: const Icon(Icons.route),
        title: Text(route.route_name),
        subtitle: _buildSubtitle(),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onEdit?.call(route),
      ),
    );
  }

  Widget _buildSubtitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Waypoints: ${route.waypoints.length}',
          style: const TextStyle(fontSize: 12),
        ),
        if (route.waypoints.isNotEmpty)
          Text(
            'Primeiro ponto: (${route.waypoints.first.lat.toStringAsFixed(4)}, ${route.waypoints.first.lon.toStringAsFixed(4)})',
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
      ],
    );
  }
}
