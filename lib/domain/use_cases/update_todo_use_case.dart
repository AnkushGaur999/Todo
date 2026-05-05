import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class UpdateTodoUseCase {
  final TodoRepository repository;

  UpdateTodoUseCase({required this.repository});

  Future<TodoModel> call(TodoModel todo) async {
    return repository.updateTodo(todo);
  }
}
