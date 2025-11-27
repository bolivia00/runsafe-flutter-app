import 'package:flutter/material.dart';
import 'package:runsafe/domain/dto/weekly_goal_dto.dart';

/// Widget de item individual para meta semanal
class WeeklyGoalListItem extends StatelessWidget {
  final WeeklyGoalDto goal;
  final Function(WeeklyGoalDto)? onEdit;
  final Function(WeeklyGoalDto)? onDelete;

  const WeeklyGoalListItem({
    super.key,
    required this.goal,
    this.onEdit,
    this.onDelete,
  });

  double _calculateProgressPercent() {
    if (goal.target_km <= 0) return 0.0;
    final progress = (goal.current_progress_km / goal.target_km) * 100;
    return progress.clamp(0.0, 100.0);
  }

  String _formatProgress() {
    final progress = _calculateProgressPercent();
    return '${progress.toStringAsFixed(1)}%';
  }

  @override
  Widget build(BuildContext context) {
    final progressPercent = _calculateProgressPercent();

    return Dismissible(
      key: ValueKey('${goal.target_km}_${goal.current_progress_km}'),
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
          'Meta: ${goal.target_km.toStringAsFixed(2)} km',
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
                '${goal.current_progress_km.toStringAsFixed(2)} / ${goal.target_km.toStringAsFixed(2)} km - ${_formatProgress()}',
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
