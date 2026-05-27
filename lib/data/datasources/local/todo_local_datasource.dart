import 'package:hive_ce_flutter/adapters.dart';

import '../../models/todo_model.dart';

class TodoLocalDataSource {
  static const String _boxName = 'todos_box';
  late Box<TodoModel> _box;

  Future<void> init() async {
    _box = await Hive.openBox<TodoModel>(_boxName);
  }

  List<TodoModel> getCachedTodos() {
    final todos = _box.values.toList();
    todos.sort((a, b) => b.id.compareTo(a.id));
    return todos;
  }

  Future<void> cacheTodos(List<TodoModel> todos) async {
    final currentItems = _box.values.toList();
    final itemsToProtect = currentItems.where((t) {
      return t.pendingAction != 'none' || t.localId != null;
    }).toList();
    await _box.clear();
    for (final todo in todos) {
      await _box.put(todo.key, todo);
    }
    for (final todo in itemsToProtect) {
      await _box.put(todo.key, todo);
    }
  }

  Future<void> saveTodo(TodoModel todo) async {
    await _box.put(todo.key, todo);
  }

  Future<void> deleteTodoByKey(String key) async {
    await _box.delete(key);
  }

  List<TodoModel> getUnsyncedTodos() {
    return _box.values.where((t) => t.pendingAction != 'none').toList();
  }

  bool get isOpen => _box.isOpen;

  Future<void> clearAll() async {
    await _box.clear();
  }
}
