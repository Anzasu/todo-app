import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/checklist_model.dart';
import '../services/storage_service.dart';
import 'storage_provider.dart';

final checklistsProvider =
    StateNotifierProvider<ChecklistsNotifier, List<ChecklistModel>>((ref) {
  return ChecklistsNotifier(ref.read(storageServiceProvider));
});

class ChecklistsNotifier extends StateNotifier<List<ChecklistModel>> {
  final StorageService _storage;

  ChecklistsNotifier(this._storage) : super([]) {
    state = _storage.loadChecklists();
  }

  Future<void> addChecklist(String name) async {
    state = [...state, ChecklistModel.create(name)];
    await _storage.saveChecklists(state);
  }

  Future<void> renameChecklist(String id, String newName) async {
    state = state
        .map((c) => c.id == id ? c.copyWith(name: newName) : c)
        .toList();
    await _storage.saveChecklists(state);
  }

  Future<void> deleteChecklist(String id) async {
    state = state.where((c) => c.id != id).toList();
    await _storage.saveChecklists(state);
  }

  Future<void> addItem(String checklistId, String description) async {
    state = state.map((c) {
      if (c.id != checklistId) return c;
      return c.copyWith(items: [...c.items, ChecklistItemModel.create(description)]);
    }).toList();
    await _storage.saveChecklists(state);
  }

  Future<void> toggleItem(String checklistId, String itemId) async {
    state = state.map((c) {
      if (c.id != checklistId) return c;
      return c.copyWith(
        items: c.items
            .map((i) => i.id == itemId
                ? i.copyWith(isCompleted: !i.isCompleted)
                : i)
            .toList(),
      );
    }).toList();
    await _storage.saveChecklists(state);
  }

  Future<void> updateItem(
      String checklistId, String itemId, String description) async {
    state = state.map((c) {
      if (c.id != checklistId) return c;
      return c.copyWith(
        items: c.items
            .map((i) => i.id == itemId ? i.copyWith(description: description) : i)
            .toList(),
      );
    }).toList();
    await _storage.saveChecklists(state);
  }

  Future<void> deleteItem(String checklistId, String itemId) async {
    state = state.map((c) {
      if (c.id != checklistId) return c;
      return c.copyWith(items: c.items.where((i) => i.id != itemId).toList());
    }).toList();
    await _storage.saveChecklists(state);
  }
}
