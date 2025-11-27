import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:runsafe/domain/repositories/safety_alert_repository.dart';
import 'package:runsafe/domain/dto/safety_alert_dto.dart';
import 'package:runsafe/widgets/forms/safety_alert_form_dialog.dart';
import 'package:runsafe/widgets/safety_alert_list_widget.dart';
import 'package:runsafe/domain/mappers/safety_alert_mapper.dart';

/// Página de listagem de alertas de segurança com suporte a paginação e filtros
class SafetyAlertListPageWithPagination extends StatefulWidget {
  const SafetyAlertListPageWithPagination({super.key});

  @override
  State<SafetyAlertListPageWithPagination> createState() =>
      _SafetyAlertListPageWithPaginationState();
}

class _SafetyAlertListPageWithPaginationState
    extends State<SafetyAlertListPageWithPagination>
    with SingleTickerProviderStateMixin {
  bool _showTip = true;
  bool _showTutorial = false;

  late final AnimationController _fabController;
  late final Animation<double> _fabScale;

  final SafetyAlertMapper _mapper = SafetyAlertMapper();

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
      if (mounted &&
          context.read<SafetyAlertRepository>().alerts.isEmpty &&
          _showTip) {
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
    final repository = context.read<SafetyAlertRepository>();
    final newAlert = await showSafetyAlertFormDialog(context);

    if (newAlert != null) {
      repository.addAlert(newAlert);

      if (_showTip) {
        setState(() => _showTip = false);
        _fabController.stop();
        _fabController.reset();
      }
    }
  }

  void _editAlert(BuildContext context, SafetyAlertDto alertDto) async {
    final repository = context.read<SafetyAlertRepository>();
    
    final alertEntity = _mapper.toEntity(alertDto);
    
    final updatedAlert = await showSafetyAlertFormDialog(
      context,
      initial: alertEntity,
    );

    if (updatedAlert != null) {
      repository.editAlert(updatedAlert);
    }
  }

  void _deleteAlert(BuildContext context, SafetyAlertDto alertDto) async {
    try {
      final repository = context.read<SafetyAlertRepository>();
      repository.deleteAlert(alertDto.alert_id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao deletar alerta: $e')),
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
            child: SafetyAlertListWidget(
              onEdit: (alertDto) => _editAlert(context, alertDto),
              onDelete: (alertDto) => _deleteAlert(context, alertDto),
            ),
          ),
          if (_showTutorial) _buildTutorialOverlay(context),
          _buildOptOutButton(context),
          if (_showTip && context.watch<SafetyAlertRepository>().alerts.isEmpty)
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
                  'Aqui você verá alertas de segurança com filtros por severidade, busca e paginação.\n\nUse o botão "+" para adicionar um novo alerta.\nClique em um alerta para editar.\nDeslize para a esquerda para deletar.',
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
            'Toque aqui para adicionar um alerta',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
