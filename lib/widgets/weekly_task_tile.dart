import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weekly_task_model.dart';

class WeeklyTaskTile extends StatelessWidget {
  final WeeklyTaskModel task;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const WeeklyTaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDone = task.isCompleted;
    final isMissed = task.isMissed && !isDone;

    Color textColor;
    TextDecoration textDeco;
    Color? tileColor;

    if (isDone) {
      textColor = Colors.grey;
      textDeco = TextDecoration.lineThrough;
      tileColor = null;
    } else if (isMissed) {
      textColor = Colors.deepOrange.shade400;
      textDeco = TextDecoration.lineThrough;
      tileColor = Colors.deepOrange.withOpacity(0.05);
    } else {
      textColor = colorScheme.onSurface;
      textDeco = TextDecoration.none;
      tileColor = null;
    }

    return Dismissible(
      key: ValueKey('dismiss_${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        color: tileColor,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 48,
                  margin: const EdgeInsets.only(left: 8, right: 4),
                  decoration: BoxDecoration(
                    color: isDone || isMissed
                        ? Colors.grey.withOpacity(0.3)
                        : _priorityColor(task.priority),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Checkbox
                Checkbox(
                  value: isDone,
                  onChanged: (_) => onToggle(),
                  activeColor: isDone ? Colors.grey : null,
                ),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.description,
                        style: TextStyle(
                          decoration: textDeco,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (task.deadline != null || isMissed)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              if (isMissed)
                                _Badge(
                                  label: 'Verpasst',
                                  color: Colors.deepOrange,
                                ),
                              if (isMissed && task.deadline != null)
                                const SizedBox(width: 6),
                              if (task.deadline != null)
                                _Badge(
                                  icon: Icons.event_outlined,
                                  label: DateFormat('dd.MM.yy')
                                      .format(task.deadline!),
                                  color: _deadlineColor(
                                      task.deadline!, isDone || isMissed),
                                ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                // Drag handle
                const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(Icons.drag_handle, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.high => Colors.red,
        TaskPriority.medium => Colors.orange,
        TaskPriority.low => Colors.green,
      };

  Color _deadlineColor(DateTime deadline, bool faded) {
    if (faded) return Colors.grey;
    final daysLeft = deadline.difference(DateTime.now()).inDays;
    if (daysLeft < 0) return Colors.red;
    if (daysLeft <= 1) return Colors.orange;
    return Colors.blueGrey;
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const _Badge({required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
