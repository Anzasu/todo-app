
import 'package:uuid/uuid.dart';

class ChecklistItemModel {
  final String id;
  final String description;
  final bool isCompleted;

  const ChecklistItemModel({
    required this.id,
    required this.description,
    this.isCompleted = false,
  });

  factory ChecklistItemModel.create(String description) =>
      ChecklistItemModel(
        id: const Uuid().v4(),
        description: description,
      );

  ChecklistItemModel copyWith({
    String? description,
    bool? isCompleted,
  }) =>
      ChecklistItemModel(
        id: id,
        description: description ?? this.description,
        isCompleted: isCompleted ?? this.isCompleted,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'description': description,
        'isCompleted': isCompleted,
      };

  factory ChecklistItemModel.fromMap(Map<String, dynamic> map) {
    return ChecklistItemModel(
      id: map['id'] as String? ?? const Uuid().v4(),
      description: map['description'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }
}

class ChecklistModel {
  final String id;
  final String name;
  final List<ChecklistItemModel> items;

  ChecklistModel({
    required this.id,
    required this.name,
    required List<ChecklistItemModel> items,
  }) : items = List.unmodifiable(items);

  factory ChecklistModel.create(String name) => ChecklistModel(
        id: const Uuid().v4(),
        name: name,
        items: const [],
      );

  ChecklistModel copyWith({
    String? name,
    List<ChecklistItemModel>? items,
  }) =>
      ChecklistModel(
        id: id,
        name: name ?? this.name,
        items: items ?? this.items,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'items': items.map((i) => i.toMap()).toList(),
      };

  factory ChecklistModel.fromMap(Map<String, dynamic> map) {
    final rawItems = map['items'];

    return ChecklistModel(
      id: map['id'] as String? ?? const Uuid().v4(),
      name: map['name'] as String? ?? '',
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(ChecklistItemModel.fromMap)
              .toList()
          : const [],
    );
  }
}
