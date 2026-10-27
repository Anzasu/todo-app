import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/weekly_task_model.dart';
import '../providers/weekly_tasks_provider.dart';

class WeeklyTaskForm extends ConsumerStatefulWidget {
  final DateTime date;
  final WeeklyTaskModel? task;

  const WeeklyTaskForm({super.key, required this.date, this.task});

  @override
  ConsumerState<WeeklyTaskForm> createState() => _WeeklyTaskFormState();
}

class _WeeklyTaskFormState extends ConsumerState<WeeklyTaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descController;

  late TaskPriority _priority;
  DateTime? _deadline;
  late Set<NotificationTiming> _notifications;
  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final t = widget.task;
    _descController = TextEditingController(text: t?.description ?? '');
    _priority = t?.priority ?? TaskPriority.medium;
    _deadline = t?.deadline;
    _notifications = Set.from(t?.notifications ?? []);
  }

  @override
  void dispose() {
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Aufgabe bearbeiten' : 'Neue Aufgabe'),
        actions: _isEditing
            ? [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Löschen',
                  onPressed: _deleteTask,
                ),
              ]
            : null,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Description
            TextFormField(
              controller: _descController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Beschreibung',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Bitte Beschreibung eingeben' : null,
              maxLines: 2,
              minLines: 1,
            ),
            const SizedBox(height: 20),

            // Priority
            Text('Priorität', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<TaskPriority>(
              segments: TaskPriority.values.map((p) {
                final color = _priorityColor(p);
                return ButtonSegment(
                  value: p,
                  label: Text(p.label),
                  icon: Icon(Icons.circle, color: color, size: 12),
                );
              }).toList(),
              selected: {_priority},
              onSelectionChanged: (s) => setState(() => _priority = s.first),
            ),
            const SizedBox(height: 20),

            // Deadline
            Text('Deadline (optional)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_deadline == null
                        ? 'Kein Datum'
                        : DateFormat('dd. MMMM yyyy', 'de_DE')
                            .format(_deadline!)),
                    onPressed: _pickDeadline,
                  ),
                ),
                if (_deadline != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Deadline entfernen',
                    onPressed: () => setState(() {
                      _deadline = null;
                      _notifications.clear();
                    }),
                  ),
                ],
              ],
            ),

            // Notifications (only if deadline set)
            if (_deadline != null) ...[
              const SizedBox(height: 20),
              Text('Benachrichtigungen',
                  style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 8),
              ...NotificationTiming.values.map(
                (t) => CheckboxListTile(
                  title: Text(t.label),
                  value: _notifications.contains(t),
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      _notifications.add(t);
                    } else {
                      _notifications.remove(t);
                    }
                  }),
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
            ],

            const SizedBox(height: 32),
            FilledButton.icon(
              icon: Icon(_isEditing ? Icons.save_outlined : Icons.add),
              label: Text(_isEditing ? 'Speichern' : 'Hinzufügen'),
              onPressed: _save,
            ),
          ],
        ),
      ),
    );
  }

  Color _priorityColor(TaskPriority p) => switch (p) {
        TaskPriority.high => Colors.red,
        TaskPriority.medium => Colors.orange,
        TaskPriority.low => Colors.green,
      };

  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline ?? widget.date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      locale: const Locale('de', 'DE'),
    );
    if (picked != null) setState(() => _deadline = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(weeklyTasksProvider.notifier);
    final desc = _descController.text.trim();

    if (_isEditing) {
      final updated = widget.task!.copyWith(
        description: desc,
        deadline: _deadline,
        priority: _priority,
        notifications: _notifications.toList(),
      );
      await notifier.updateTask(updated);
    } else {
      final task = WeeklyTaskModel.create(
        description: desc,
        assignedDate: widget.date,
        deadline: _deadline,
        priority: _priority,
        notifications: _notifications.toList(),
      );
      await notifier.addTask(task);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _deleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Löschen?'),
        content: const Text('Aufgabe wirklich löschen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(weeklyTasksProvider.notifier).deleteTask(widget.task!.id);
      if (mounted) Navigator.of(context).pop();
    }
  }
}
