part of 'todo_bloc.dart';

sealed class TodoEvents {}

final class LoadTodos extends TodoEvents {}

final class AddTodo extends TodoEvents {
  final String title;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isCompleted;

  AddTodo(this.title,
      {this.createdAt, this.updatedAt, this.isCompleted = false});
}

final class ToggleTodo extends TodoEvents {
  final TodoModel todo;

  ToggleTodo(this.todo);
}

final class DeleteTodo extends TodoEvents {
  final TodoModel todo;

  DeleteTodo(this.todo);
}

final class UpdateTodo extends TodoEvents {
  final TodoModel todo;

  UpdateTodo(this.todo);
}

final class SearchTodos extends TodoEvents {
  final String query;

  SearchTodos(this.query);
}

final class UpdateSync extends TodoEvents{

  final bool isSync;
  UpdateSync({required this.isSync});

}

final class SyncTodos extends TodoEvents {}

final class ConnectionRestored extends TodoEvents {}

final class ConnectionLost extends TodoEvents {}
