import 'package:flutter/material.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';

class SafetyAlertListItem extends StatelessWidget {
  final SafetyAlert alert; // Recebe a Entidade
  final VoidCallback? onTap;

  const SafetyAlertListItem({
    super.key, 
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      // A Entidade usa 'type' (Enum) e 'timestamp' (DateTime)
      leading: Icon(_getIconForType(alert.type)), 
      title: Text(alert.description),
      subtitle: Text(
        'Severidade: ${alert.severity} • ${alert.timestamp.day}/${alert.timestamp.month}',
      ),
      onTap: onTap,
    );
  }

  IconData _getIconForType(AlertType type) {
    switch (type) {
      case AlertType.pothole: return Icons.dangerous;
      case AlertType.noLighting: return Icons.lightbulb;
      case AlertType.suspiciousActivity: return Icons.visibility;
      default: return Icons.info;
    }
  }
}