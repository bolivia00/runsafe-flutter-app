import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/safety_alert_dto.dart';

/// Item individual de um alerta de segurança na listagem
class SafetyAlertListItem extends StatelessWidget {
  final SafetyAlertDto alert;
  final Function(SafetyAlertDto)? onEdit;
  final Function(SafetyAlertDto)? onDelete;
  final Color Function(int) getSeverityColor;
  final String Function(int) getSeverityLabel;

  const SafetyAlertListItem({
    super.key,
    required this.alert,
    this.onEdit,
    this.onDelete,
    required this.getSeverityColor,
    required this.getSeverityLabel,
  });

  @override
  Widget build(BuildContext context) {
    final color = getSeverityColor(alert.severity);
    final severityLabel = getSeverityLabel(alert.severity);

    return Dismissible(
      key: Key(alert.alert_id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        onDelete?.call(alert);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alerta excluído.')),
        );
      },
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
          ),
          child: Center(
            child: Text(
              '${alert.severity}',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ),
        title: Text(
          alert.alert_type,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              alert.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(
                    severityLabel,
                    style: const TextStyle(fontSize: 11, color: Colors.white),
                  ),
                  backgroundColor: color,
                  padding: EdgeInsets.zero,
                ),
                const SizedBox(width: 8),
                Text(
                  alert.timestamp.split('T')[0], // Data apenas
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => onEdit?.call(alert),
      ),
    );
  }
}
