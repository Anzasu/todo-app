
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/checklist_model.dart';
import '../providers/checklists_provider.dart';

class ChecklistDetailScreen extends ConsumerWidget {
  final String checklistId;

  const ChecklistDetailScreen({
    super.key,
    required this.checklistId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklists = ref.watch(checklistsProvider);

    ChecklistModel? checklist;
    for (final candidate in checklists) {
      if (candidate.id == checklistId) {
        checklist = candidate;
        break;
      }
    }

    if (checklist == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkliste')),
        body: const Center(
          child: Text('Checkliste nicht gefunden'),
        ),
      );
    }

    final sortedItems = List<ChecklistItemModel>.of(checklist.items)
      ..sort((a, b) {
        if (a.isCompleted == b.isCompleted) return 0;
        return a.isCompleted ? 1 : -1;
      });

    return Scaffold(
      appBar: AppBar(title: Text(checklist.name)),
      body: sortedItems.isEmpty
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_task, size: 72, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'Keine Aufgaben',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tippe auf + um eine Aufgabe hinzuzufügen',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                vertical: 8,
                horizontal: 12,
              ),
              itemCount: sortedItems.length,
              itemBuilder: (context, index) {
                return _ItemTile(
                  checklistId: checklistId,
                  item: sortedItems[index],
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context, ref),
        tooltip: 'Aufgabe hinzufügen',
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showAddDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final description = await showDialog<String>(
      context: context,
      builder: (_) => const _ChecklistItemDialog(),
    );

    if (description == null || description.isEmpty) return;

    // The screen may have been removed while the dialog was open.
    if (!context.mounted) return;

    // Do not add an item if its checklist was deleted in the meantime.
    final checklistExists = ref
        .read(checklistsProvider)
        .any((checklist) => checklist.id == checklistId);

    if (!checklistExists) return;

    ref.read(checklistsProvider.notifier).addItem(
          checklistId,
          description,
        );
  }
}

class _ItemTile extends ConsumerWidget {
  final String checklistId;
  final ChecklistItemModel item;

  const _ItemTile({
    required this.checklistId,
    required this.item,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.delete_outline,
          color: Colors.white,
        ),
      ),
      onDismissed: (_) {
        ref.read(checklistsProvider.notifier).deleteItem(
              checklistId,
              item.id,
            );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding: const EdgeInsets.only(left: 4, right: 12),
          leading: Checkbox(
            value: item.isCompleted,
            onChanged: (_) {
              ref.read(checklistsProvider.notifier).toggleItem(
                    checklistId,
                    item.id,
                  );
            },
          ),
          title: Text(
            item.description,
            style: item.isCompleted
                ? const TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.grey,
                  )
                : null,
          ),
          onTap: () => _showEditDialog(context, ref),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showDialog<_EditItemResult>(
      context: context,
      builder: (_) => _EditChecklistItemDialog(
        initialDescription: item.description,
      ),
    );

    if (result == null) return;

    if (!context.mounted) return;

    final checklistExists = ref
        .read(checklistsProvider)
        .any((checklist) => checklist.id == checklistId);

    if (!checklistExists) return;

    final itemExists = ref
        .read(checklistsProvider)
        .where((checklist) => checklist.id == checklistId)
        .expand((checklist) => checklist.items)
        .any((currentItem) => currentItem.id == item.id);

    if (!itemExists) return;

    switch (result.action) {
      case _EditItemAction.delete:
        ref.read(checklistsProvider.notifier).deleteItem(
              checklistId,
              item.id,
            );

      case _EditItemAction.save:
        final description = result.description!.trim();
        if (description.isEmpty) return;

        ref.read(checklistsProvider.notifier).updateItem(
              checklistId,
              item.id,
              description,
            );
    }
  }
}

class _ChecklistItemDialog extends StatefulWidget {
  const _ChecklistItemDialog();

  @override
  State<_ChecklistItemDialog> createState() =>
      _ChecklistItemDialogState();
}

class _ChecklistItemDialogState extends State<_ChecklistItemDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  void _submit() {
    Navigator.of(context).pop(_controller.text.trim());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Aufgabe'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Beschreibung',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Hinzufügen'),
        ),
      ],
    );
  }
}

enum _EditItemAction { save, delete }

class _EditItemResult {
  final _EditItemAction action;
  final String? description;

  const _EditItemResult.save(String description)
      : action = _EditItemAction.save,
        description = description;

  const _EditItemResult.delete()
      : action = _EditItemAction.delete,
        description = null;
}

class _EditChecklistItemDialog extends StatefulWidget {
  final String initialDescription;

  const _EditChecklistItemDialog({
    required this.initialDescription,
  });

  @override
  State<_EditChecklistItemDialog> createState() =>
      _EditChecklistItemDialogState();
}

class _EditChecklistItemDialogState
    extends State<_EditChecklistItemDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.initialDescription,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Aufgabe bearbeiten'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textCapitalization: TextCapitalization.sentences,
        decoration: const InputDecoration(
          labelText: 'Beschreibung',
          border: OutlineInputBorder(),
        ),
        onSubmitted: (_) {
          Navigator.of(context).pop(
            _EditItemResult.save(_controller.text.trim()),
          );
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              const _EditItemResult.delete(),
            );
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
          child: const Text('Löschen'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop(
              _EditItemResult.save(_controller.text.trim()),
            );
          },
          child: const Text('Speichern'),
        ),
      ],
    );
  }
}
