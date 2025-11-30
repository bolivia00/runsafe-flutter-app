import 'package:flutter/material.dart';
import 'package:runsafe/features/goals/domain/entities/weekly_goal.dart';

/// Widget de item individual para meta semanal
class WeeklyGoalListItem extends StatelessWidget {
  final WeeklyGoal goal;
  final Function(WeeklyGoal)? onEdit;
  final Function(WeeklyGoal)? onDelete;

  const WeeklyGoalListItem({
    super.key,
    required this.goal,
    this.onEdit,
    this.onDelete,
  });

  double _calculateProgressPercent() {
    return goal.progressPercentage * 100;
  }

  String _formatProgress() {
    final progress = _calculateProgressPercent();
    return '${progress.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _calculateProgressPercent();

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) {
        onDelete?.call(goal);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Meta excluída'),
            action: SnackBarAction(label: 'Desfazer', onPressed: () {}),
          ),
        );
      },
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: ListTile(
        leading: const Icon(Icons.flag),
        title: Text(
          'Meta: ${goal.targetKm.toStringAsFixed(2)} km',
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: LinearProgressIndicator(
                value: progressPercent / 100.0,
                backgroundColor: Colors.grey[300],
                minHeight: 6,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(
                '${goal.currentKm.toStringAsFixed(2)} / ${goal.targetKm.toStringAsFixed(2)} km - ${_formatProgress()}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () => onEdit?.call(goal),
        ),
        onTap: () => onEdit?.call(goal),
      ),
    );
  }
}
