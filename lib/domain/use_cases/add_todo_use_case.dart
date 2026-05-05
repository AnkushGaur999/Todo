import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class AddTodoUseCase {
  final TodoRepository repository;

  AddTodoUseCase({required this.repository});

  Future<TodoModel> call(String title,
      {DateTime? createdAt,
      DateTime? updatedAt,
      bool isCompleted = false}) async {
    return await repository.addTodo(title,
        createdAt: createdAt, updatedAt: updatedAt, isCompleted: isCompleted);
  }
}
