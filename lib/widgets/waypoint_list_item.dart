import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/waypoint_dto.dart';

/// Item individual de um waypoint na listagem
class WaypointListItem extends StatelessWidget {
  final WaypointDto waypoint;
  final Function(WaypointDto)? onEdit;
  final Function(WaypointDto)? onDelete;

  const WaypointListItem({
    super.key,
    required this.waypoint,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key('${waypoint.lat}_${waypoint.lon}_${waypoint.ts}'),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        onDelete?.call(waypoint);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Waypoint excluído.')),
        );
      },
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.blue.withValues(alpha: 0.2),
          ),
          child: const Center(
            child: Icon(Icons.location_on, color: Colors.blue, size: 20),
          ),
        ),
        title: Text(
          'Ponto de Rota',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Lat: ${waypoint.lat.toStringAsFixed(6)}, Lon: ${waypoint.lon.toStringAsFixed(6)}',
              style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
            const SizedBox(height: 4),
            Text(
              'Timestamp: ${_formatTimestamp(waypoint.ts)}',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onEdit?.call(waypoint),
      ),
    );
  }

  String _formatTimestamp(String ts) {
    try {
      final date = DateTime.parse(ts);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return ts;
    }
  }
}
