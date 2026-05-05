import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class GetTodosUseCase {
  final TodoRepository repository;

  GetTodosUseCase({required this.repository});

  Future<List<TodoModel>> call() async {
    return repository.getTodos();
  }
}
