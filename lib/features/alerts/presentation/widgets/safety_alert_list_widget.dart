import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/alerts/presentation/providers/safety_alerts_provider.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';
// Se você tiver o safety_alert_form_dialog.dart, importe-o aqui
// import 'package:runsafe/features/alerts/presentation/widgets/safety_alert_form_dialog.dart';

class SafetyAlertListWidget extends StatelessWidget {
  const SafetyAlertListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SafetyAlertsProvider>(
      builder: (context, provider, child) {
        final alerts = provider.alerts;

        if (alerts.isEmpty) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          return const Center(child: Text('Nenhum alerta encontrado.'));
        }

        return ListView.separated(
          itemCount: alerts.length,
          separatorBuilder: (ctx, index) => const Divider(height: 1),
          itemBuilder: (ctx, index) {
            final alert = alerts[index];
            // Usando o ListItem que vimos no Canvas, ou construindo aqui direto
            return SafetyAlertListItem(
              alert: alert,
              onTap: () {
                // Lógica de edição simplificada (se houver form dialog)
                // _editAlert(context, alert); 
              },
            );
          },
        );
      },
    );
  }
}

// O ListItem que vimos no Canvas deve estar aqui ou em arquivo separado
class SafetyAlertListItem extends StatelessWidget {
  final SafetyAlert alert;
  final VoidCallback? onTap;

  const SafetyAlertListItem({
    super.key, 
    required this.alert,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(_getIconForType(alert.type)),
      title: Text(alert.description),
      subtitle: Text(
        'Severidade: ${alert.severity} • ${alert.timestamp.day}/${alert.timestamp.month}',
      ),
      onTap: onTap,
      trailing: IconButton(
        icon: const Icon(Icons.delete, color: Colors.red),
        onPressed: () {
             // Nota: novo repositório não tem deleteAlert
             ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Deletar não implementado')),
             );
        },
      ),
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