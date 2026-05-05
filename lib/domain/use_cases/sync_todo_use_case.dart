import 'package:todo_app/data/repositories/todo_repository_impl.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';

class SyncTodoUseCase {
  final TodoRepository repository;

  SyncTodoUseCase({required this.repository});

  Future<SyncResult> call() async {
    return repository.syncPending();
  }
}
