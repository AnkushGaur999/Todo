import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class ToggleTodoUseCase {
  final TodoRepository repository;

  ToggleTodoUseCase({required this.repository});

  Future<TodoModel> call(TodoModel todo) async {
    return await repository.toggleTodo(todo);
  }
}
