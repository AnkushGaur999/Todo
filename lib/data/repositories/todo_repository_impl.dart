import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';
import 'package:uuid/uuid.dart';
import '../datasources/local/todo_local_datasource.dart';
import '../datasources/remote/todo_remote_datasource.dart';
import '../models/todo_model.dart';

class TodoRepositoryImpl extends TodoRepository {
  final TodoRemoteDataSource remote;
  final TodoLocalDataSource local;
  final Connectivity connectivity;
  final _uuid = const Uuid();

  TodoRepositoryImpl({
    required this.remote,
    required this.local,
    required this.connectivity,
  });

  Future<bool> get _isOnline async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  @override
  Future<List<TodoModel>> getTodos() async {
    if (await _isOnline) {
      try {
        final todos = await remote.getTodos();
        await local.cacheTodos(todos);
        return local.getCachedTodos();
      } catch (_) {
        return local.getCachedTodos();
      }
    }
    return local.getCachedTodos();
  }

  @override
  Future<TodoModel> addTodo(String title,
      {DateTime? createdAt,
      DateTime? updatedAt,
      bool isCompleted = false}) async {
    final localId = _uuid.v4();
    final now = DateTime.now();
    final optimistic = TodoModel(
      id: -1,
      title: title,
      completed: isCompleted,
      isSynced: false,
      localId: localId,
      pendingAction: 'create',
      createdAt: createdAt ?? now,
      updatedAt: updatedAt ?? now,
    );
    await local.saveTodo(optimistic);

    if (await _isOnline) {
      try {
        final synced = await remote.createTodo(title);
        await local.deleteTodoByKey(localId);
        final confirmed = synced.copyWith(
          completed: isCompleted,
          isSynced: true,
          localId: localId,
          pendingAction: 'none',
          createdAt: createdAt ?? now,
          updatedAt: updatedAt ?? now,
        );
        await local.saveTodo(confirmed);
        return confirmed;
      } catch (e) {
        return optimistic;
      }
    }

    return optimistic;
  }

  @override
  Future<TodoModel> toggleTodo(TodoModel todo) async {
    final toggled = todo.copyWith(
      completed: !todo.completed,
      updatedAt: DateTime.now(),
      isSynced: false,
      pendingAction: todo.pendingAction == 'create' ? 'create' : 'update',
    );
    await local.saveTodo(toggled);

    if (await _isOnline && todo.id != -1) {
      try {
        final success = await remote.updateTodo(todo.id, toggled.completed);
        final confirmed = toggled.copyWith(
          isSynced: success,
          localId: todo.localId,
          pendingAction: 'none',
          updatedAt: DateTime.now(),
        );
        await local.saveTodo(confirmed);
        return confirmed;
      } catch (_) {
        return toggled;
      }
    }

    return toggled;
  }

  @override
  Future<TodoModel> updateTodo(TodoModel todo) async {
    final updatedTodo = todo.copyWith(
      completed: todo.completed,
      updatedAt: DateTime.now(),
      isSynced: false,
      pendingAction: 'update',
    );
    await local.saveTodo(updatedTodo);

    if (await _isOnline && todo.id != -1) {
      try {
        final success = await remote.updateTodo(todo.id, updatedTodo.completed);
        final confirmed = updatedTodo.copyWith(
          isSynced: success,
          localId: todo.localId,
          pendingAction: 'none',
          updatedAt: DateTime.now(),
        );
        await local.saveTodo(confirmed);
        return confirmed;
      } catch (_) {
        return updatedTodo;
      }
    }

    return updatedTodo;
  }

  @override
  Future<void> deleteTodo(TodoModel todo) async {
    if (await _isOnline) {
      try {
        if (todo.id != -1) {
          await remote.deleteTodo(todo.id);
        }
        await local.deleteTodoByKey(todo.key);
        return;
      } catch (_) {}
    }

    if (todo.pendingAction == 'create') {
      await local.deleteTodoByKey(todo.key);
    } else {
      await local.saveTodo(
        todo.copyWith(
          isSynced: false,
          pendingAction: 'delete',
          deletedAt: DateTime.now(),
        ),
      );
    }
  }

  @override
  Future<SyncResult> syncPending() async {
    if (!await _isOnline) {
      return const SyncResult(success: false, message: 'Still offline');
    }

    final unsynced = local.getUnsyncedTodos();
    if (unsynced.isEmpty) {
      return const SyncResult(success: true, message: 'Nothing to sync');
    }

    int synced = 0;
    int failed = 0;

    for (final todo in unsynced) {
      try {
        switch (todo.pendingAction) {
          case 'create':
            final serverTodo = await remote.createTodo(todo.title);
            await local.deleteTodoByKey(todo.key);
            await local.saveTodo(serverTodo.copyWith(
              isSynced: true,
              localId: todo.localId,
              pendingAction: 'none',
            ));
            synced++;
            break;

          case 'update':
            final success = await remote.updateTodo(todo.id, todo.completed);
            await local.saveTodo(todo.copyWith(
              isSynced: success,
              localId: todo.localId,
              pendingAction: 'none',
            ));
            synced++;
            break;

          case 'delete':
            await remote.deleteTodo(todo.id);
            await local.deleteTodoByKey(todo.key);
            synced++;
            break;
        }
      } catch (e) {
        failed++;
      }
    }

    return SyncResult(
      success: failed == 0,
      synced: synced,
      failed: failed,
      message: failed == 0
          ? 'Synced $synced item(s)'
          : 'Synced $synced, failed $failed',
    );
  }
}

class SyncResult {
  final bool success;
  final int synced;
  final int failed;
  final String message;

  const SyncResult({
    required this.success,
    required this.message,
    this.synced = 0,
    this.failed = 0,
  });
}
