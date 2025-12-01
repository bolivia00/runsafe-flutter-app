import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/features/alerts/presentation/providers/safety_alerts_provider.dart';
import 'package:runsafe/features/alerts/domain/entities/safety_alert.dart';
import 'package:runsafe/features/alerts/presentation/widgets/safety_alert_form_dialog.dart';

class SafetyAlertListPage extends StatefulWidget {
  const SafetyAlertListPage({super.key});

  @override
  State<SafetyAlertListPage> createState() => _SafetyAlertListPageState();
}

class _SafetyAlertListPageState extends State<SafetyAlertListPage>
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
      if (mounted && context.read<SafetyAlertsProvider>().alerts.isEmpty && _showTip) {
        _fabController.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _fabController.dispose(); 
    super.dispose();
  }

  void _addAlert(BuildContext context) async {
    final newAlert = await showSafetyAlertFormDialog(context);

    if (newAlert != null && context.mounted) {
      // Nota: novo repositório não tem addAlert, apenas sync do servidor
      // Para adicionar localmente, precisaria estender o repositório ou fazer pelo Supabase direto
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Adicionar alerta não implementado no novo repositório')),
      );
      
      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  void _editAlert(BuildContext context, SafetyAlert alertToEdit) async {
    final updatedAlert = await showSafetyAlertFormDialog(
      context,
      initial: alertToEdit,
    );

    if (updatedAlert != null && context.mounted) {
      // Nota: novo repositório não tem editAlert, apenas sync do servidor
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editar alerta não implementado no novo repositório')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas de Segurança'),
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
              child: Consumer<SafetyAlertsProvider>(
                builder: (context, provider, child) {
                  return _buildBodyWithRefresh(context, provider);
                },
              ),
            ),
          ),
          
          if (_showTutorial) _buildTutorialOverlay(context),
          _buildOptOutButton(context),
          if (_showTip && context.watch<SafetyAlertsProvider>().alerts.isEmpty)
             _buildTipBubble(context),
        ],
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return ScaleTransition(
      scale: _fabScale,
      child: FloatingActionButton(
        onPressed: () => _addAlert(context),
        child: const Icon(Icons.add_alert),
      ),
    );
  }

  /// Corpo com RefreshIndicator para sincronização remota
  Widget _buildBodyWithRefresh(BuildContext context, SafetyAlertsProvider provider) {
    // Mostra indicador de carregamento se estiver carregando e não há dados
    if (provider.isLoading && provider.alerts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        if (mounted) {
          await provider.syncNow();
        }
      },
      child: provider.alerts.isEmpty
          ? _buildEmptyList()
          : _buildAlertsList(context, provider.alerts),
    );
  }

  /// Lista vazia com scroll habilitado para pull-to-refresh
  Widget _buildEmptyList() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: const [
        SizedBox(height: 100),
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.shield_outlined, size: 72, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Nenhum alerta cadastrado ainda.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 8),
              Text(
                'Use o botão "+" abaixo para reportar um alerta.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Lista de alertas com dismissible
  Widget _buildAlertsList(BuildContext context, List<SafetyAlert> alerts) {
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: alerts.length,
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final alert = alerts[index];
        return Dismissible(
          key: Key(alert.id),
          direction: DismissDirection.endToStart,
          
          onDismissed: (direction) {
            // Nota: novo repositório não tem deleteAlert local
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Deletar alerta não implementado no novo repositório')),
            );
          },
          
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: const Icon(Icons.delete, color: Colors.white),
          ),
          
          child: ListTile(
            leading: Icon(_getIconForAlertType(alert.type)),
            title: Text(alert.description),
            subtitle: Text(
                'Tipo: ${alert.type.toString().split('.').last} - Severidade: ${alert.severity}'),
            trailing: Text(
              '${alert.timestamp.day}/${alert.timestamp.month}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            onTap: () {
              _editAlert(context, alert);
            },
          ),
        );
      },
    );
  }

  IconData _getIconForAlertType(AlertType type) {
    switch (type) {
      case AlertType.pothole:
        return Icons.dangerous;
      case AlertType.noLighting:
        return Icons.lightbulb_outline;
      case AlertType.suspiciousActivity:
        return Icons.person_search;
      case AlertType.other:
        return Icons.help_outline;
    }
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
                  'Aqui você verá os alertas de segurança.\nUse o botão flutuante para reportar um novo alerta.',
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
            'Toque aqui para reportar um alerta',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}

