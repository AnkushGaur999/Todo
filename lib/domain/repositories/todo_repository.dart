import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/data/repositories/todo_repository_impl.dart';

abstract class TodoRepository {
  Future<List<TodoModel>> getTodos();

  Future<TodoModel> addTodo(String title,
      {DateTime? createdAt, DateTime? updatedAt, bool isCompleted = false});

  Future<TodoModel> updateTodo(TodoModel todo);

  Future<TodoModel> toggleTodo(TodoModel todo);

  Future<void> deleteTodo(TodoModel todo);

  Future<SyncResult> syncPending();
}
