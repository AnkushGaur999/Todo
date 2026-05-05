import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class DeleteTodoUseCase {
  final TodoRepository repository;

  DeleteTodoUseCase({required this.repository});

  Future<void> call(TodoModel todo) async {
    return repository.deleteTodo(todo);
  }
}
