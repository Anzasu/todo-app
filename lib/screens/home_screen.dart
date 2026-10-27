
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/navigation_provider.dart';
import '../providers/checklists_provider.dart';
import 'checklisten_screen.dart';
import 'wochenplan_screen.dart';
import 'einstellungen_screen.dart';
import 'weekly_task_form.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentIndex = 0;

  static const List<String> _titles = [
    'Checklisten',
    'Wochenplan',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Einstellungen',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EinstellungenScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          ChecklistenScreen(),
          WochenplanScreen(),
        ],
      ),
      floatingActionButton: _buildFab(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == _currentIndex) return;

          setState(() {
            _currentIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Checklisten',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_view_week_outlined),
            selectedIcon: Icon(Icons.calendar_view_week),
            label: 'Wochenplan',
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    if (_currentIndex == 0) {
      return FloatingActionButton(
        heroTag: 'fab_checklists',
        tooltip: 'Neue Checkliste',
        onPressed: _showCreateChecklistDialog,
        child: const Icon(Icons.add),
      );
    }

    final selectedDate = ref.watch(selectedDateProvider);

    return FloatingActionButton(
      heroTag: 'fab_weekly',
      tooltip: 'Neue Aufgabe',
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WeeklyTaskForm(date: selectedDate),
          ),
        );
      },
      child: const Icon(Icons.add),
    );
  }

  Future<void> _showCreateChecklistDialog() async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => const _ChecklistNameDialog(),
    );

    if (!mounted || name == null || name.trim().isEmpty) {
      return;
    }

    ref.read(checklistsProvider.notifier).addChecklist(name.trim());
  }
}

class _ChecklistNameDialog extends StatefulWidget {
  const _ChecklistNameDialog({super.key});

  @override
  State<_ChecklistNameDialog> createState() =>
      _ChecklistNameDialogState();
}

class _ChecklistNameDialogState extends State<_ChecklistNameDialog> {
  late final TextEditingController _controller;
  final _formKey = GlobalKey<FormState>();

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    if (_isSubmitting) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final name = _controller.text.trim();

    setState(() {
      _isSubmitting = true;
    });

    Navigator.of(context).pop(name);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Neue Checkliste'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _controller,
          autofocus: true,
          enabled: !_isSubmitting,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Name',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Bitte einen Namen eingeben';
            }

            return null;
          },
          onFieldSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _isSubmitting ? null : _submit,
          child: const Text('Erstellen'),
        ),
      ],
    );
  }
}
