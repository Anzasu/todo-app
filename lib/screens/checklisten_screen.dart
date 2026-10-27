import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/checklists_provider.dart';
import 'checklist_detail_screen.dart';

class ChecklistenScreen extends ConsumerWidget {
  const ChecklistenScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checklists = ref.watch(checklistsProvider);

    if (checklists.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.checklist, size: 72, color: Colors.grey),
            SizedBox(height: 16),
            Text('Keine Checklisten vorhanden',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Tippe auf + um eine neue Checkliste zu erstellen',
                style: TextStyle(fontSize: 13, color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: checklists.length,
      itemBuilder: (context, index) {
        final checklist = checklists[index];
        final total = checklist.items.length;
        final done = checklist.items.where((i) => i.isCompleted).length;

        return Dismissible(
          key: Key(checklist.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 24),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.delete_outline, color: Colors.white),
          ),
          confirmDismiss: (_) => _confirmDelete(context, checklist.name),
          onDismissed: (_) =>
              ref.read(checklistsProvider.notifier).deleteChecklist(checklist.id),
          child: Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).colorScheme.primaryContainer,
                foregroundColor:
                    Theme.of(context).colorScheme.onPrimaryContainer,
                child: Text(
                  total == 0 ? '0' : '$done/$total',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(checklist.name,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: total == 0
                  ? const Text('Leer')
                  : done == total
                      ? const Text('Alle erledigt ✓')
                      : Text('$done von $total erledigt'),
              trailing: PopupMenuButton<String>(
                onSelected: (value) => _onMenuSelected(
                    context, ref, value, checklist.id, checklist.name),
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'rename',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined),
                      title: Text('Umbenennen'),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline, color: Colors.red),
                      title:
                          Text('Löschen', style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChecklistDetailScreen(checklistId: checklist.id),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _onMenuSelected(BuildContext context, WidgetRef ref,
      String value, String id, String name) async {
    if (value == 'rename') {
      await _showRenameDialog(context, ref, id, name);
    } else if (value == 'delete') {
      final confirmed = await _confirmDelete(context, name);
      if (confirmed == true) {
        ref.read(checklistsProvider.notifier).deleteChecklist(id);
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context, String name) =>
      showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Löschen?'),
          content: Text('"$name" wirklich löschen?\nAlle Aufgaben gehen verloren.'),
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

  Future<void> _showRenameDialog(
      BuildContext context, WidgetRef ref, String id, String current) async {
    final controller = TextEditingController(text: current);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Umbenennen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Speichern'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name != null && name.isNotEmpty) {
      ref.read(checklistsProvider.notifier).renameChecklist(id, name);
    }
  }
}
