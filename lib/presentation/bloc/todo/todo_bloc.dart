import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:todo_app/domain/use_cases/add_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/delete_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/get_todos_use_case.dart';
import 'package:todo_app/domain/use_cases/search_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/sync_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/toggle_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/update_todo_use_case.dart';
import '../../../data/models/todo_model.dart';

part 'todo_events.dart';

part 'todo_states.dart';

class TodoBloc extends Bloc<TodoEvents, TodoStates> {
  final GetTodosUseCase getTodosUseCase;
  final AddTodoUseCase addTodoUseCase;
  final DeleteTodoUseCase deleteTodoUseCase;
  final ToggleTodoUseCase toggleTodoUseCase;
  final UpdateTodoUseCase updateTodoUseCase;
  final SearchTodoUseCase searchTodoUseCase;
  final SyncTodoUseCase syncTodoUseCase;
  final Connectivity connectivity;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _wasOffline = false;

  TodoBloc({
    required this.getTodosUseCase,
    required this.addTodoUseCase,
    required this.deleteTodoUseCase,
    required this.toggleTodoUseCase,
    required this.updateTodoUseCase,
    required this.searchTodoUseCase,
    required this.syncTodoUseCase,
    required this.connectivity,
  }) : super(TodoInitial()) {
    on<LoadTodos>(_onLoadTodos);
    on<AddTodo>(_onAddTodo);
    on<ToggleTodo>(_onToggleTodo);
    on<UpdateTodo>(_updateTodo);
    on<DeleteTodo>(_onDeleteTodo);
    on<SearchTodos>(
      _onSearchTodos,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<SyncTodos>(_onSyncTodos);
    on<ConnectionRestored>(_onConnectionRestored);
    on<ConnectionLost>(_onConnectionLost);

    _startConnectivityListener();
  }

  EventTransformer<E> _debounce<E>(Duration duration) {
    return (events, mapper) => events.debounce(duration).switchMap(mapper);
  }

  void _startConnectivityListener() {
    _connectivitySub = connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isOnline =
          results.isNotEmpty && !results.contains(ConnectivityResult.none);

      print("Connection isOnline: $isOnline");

      if (isOnline && _wasOffline) {
        add(ConnectionRestored());
      } else if (!isOnline && !_wasOffline) {
        add(ConnectionLost());
      }
      _wasOffline = !isOnline;
    });
  }

  Future<void> _onLoadTodos(LoadTodos event, Emitter<TodoStates> emit) async {
    emit(TodoLoading());
    try {
      final isOnline = await _checkOnline();
      final todos = await getTodosUseCase();
      emit(TodoLoaded(todos: todos, isOnline: isOnline));
    } catch (e) {
      emit(TodoError('Failed to load tasks: ${e.toString()}'));
    }
  }

  Future<void> _onAddTodo(AddTodo event, Emitter<TodoStates> emit) async {
    if (state is! TodoLoaded) return;
    final current = state as TodoLoaded;

    try {
      final newTodo = await addTodoUseCase(
        event.title,
        createdAt: event.createdAt,
        updatedAt: event.updatedAt,
        isCompleted: event.isCompleted,
      );
      final updated = [newTodo, ...current.todos];
      emit(
        current.copyWith(
          todos: updated,
          filtered: _applyFilter(updated, current.searchQuery),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(errorMessage: 'Failed to add task: $e'));
    }
  }

  Future<void> _onToggleTodo(ToggleTodo event, Emitter<TodoStates> emit) async {
    if (state is! TodoLoaded) return;
    final current = state as TodoLoaded;
    final optimisticList = _replaceInList(
      current.todos,
      event.todo.copyWith(completed: !event.todo.completed),
    );
    emit(
      current.copyWith(
        todos: optimisticList,
        filtered: _applyFilter(optimisticList, current.searchQuery),
      ),
    );

    try {
      final updated = await toggleTodoUseCase(event.todo);
      final confirmedList = _replaceInList(current.todos, updated);
      emit(
        current.copyWith(
          todos: confirmedList,
          filtered: _applyFilter(confirmedList, current.searchQuery),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(errorMessage: 'Failed to update task: $e'));
    }
  }

  Future<void> _updateTodo(UpdateTodo event, Emitter<TodoStates> emit) async {
    if (state is! TodoLoaded) return;
    final current = state as TodoLoaded;

    final optimisticList = _replaceInList(current.todos, event.todo);

    emit(
      current.copyWith(
        todos: optimisticList,
        filtered: _applyFilter(optimisticList, current.searchQuery),
      ),
    );

    try {
      final updated = await updateTodoUseCase(event.todo);

      final confirmedList = _replaceInList(current.todos, updated);

      emit(
        current.copyWith(
          todos: confirmedList,
          filtered: _applyFilter(confirmedList, current.searchQuery),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(current.copyWith(errorMessage: 'Failed to update task: $e'));
    }
  }

  Future<void> _onDeleteTodo(DeleteTodo event, Emitter<TodoStates> emit) async {
    if (state is! TodoLoaded) return;
    final current = state as TodoLoaded;
    final optimisticList = current.todos
        .where((t) => t.key != event.todo.key)
        .toList();
    emit(
      current.copyWith(
        todos: optimisticList,
        filtered: _applyFilter(optimisticList, current.searchQuery),
      ),
    );

    try {
      await deleteTodoUseCase(event.todo);
    } catch (e) {
      emit(current.copyWith(errorMessage: 'Failed to delete task: $e'));
    }
  }

  void _onSearchTodos(SearchTodos event, Emitter<TodoStates> emit) {
    if (state is! TodoLoaded) return;
    final current = state as TodoLoaded;
    emit(
      current.copyWith(
        searchQuery: event.query,
        filtered: _applyFilter(current.todos, event.query),
      ),
    );
  }

  Future<void> _onSyncTodos(SyncTodos event, Emitter<TodoStates> emit) async {
    if (state is! TodoLoaded) return;
    final current = state as TodoLoaded;

    emit(current.copyWith(isSyncing: true, clearSyncMessage: true));
    try {
      final result = await syncTodoUseCase();
      final freshTodos = await getTodosUseCase();
      emit(
        TodoLoaded(
          todos: freshTodos,
          searchQuery: current.searchQuery,
          filtered: _applyFilter(freshTodos, current.searchQuery),
          isOnline: true,
          isSyncing: false,
          syncMessage: result.message,
        ),
      );
    } catch (e) {
      emit(current.copyWith(isSyncing: false, errorMessage: 'Sync failed: $e'));
    }
  }

  Future<void> _onConnectionRestored(
    ConnectionRestored event,
    Emitter<TodoStates> emit,
  ) async {
    if (state is! TodoLoaded) {
      add(LoadTodos());
      return;
    }

    final current = state as TodoLoaded;
    emit(
      current.copyWith(isOnline: true, isSyncing: true, clearSyncMessage: true),
    );

    try {
      final syncResult = await syncTodoUseCase();

      final freshTodos = await getTodosUseCase();

      emit(
        TodoLoaded(
          todos: freshTodos,
          searchQuery: current.searchQuery,
          filtered: _applyFilter(freshTodos, current.searchQuery),
          isOnline: true,
          isSyncing: false,
          syncMessage: 'Back online · ${syncResult.message}',
        ),
      );
    } catch (e) {
      emit(
        current.copyWith(
          isOnline: true,
          isSyncing: false,
          errorMessage: 'Sync failed after reconnect: $e',
        ),
      );
    }
  }

  void _onConnectionLost(ConnectionLost event, Emitter<TodoStates> emit) {
    if (state is TodoLoaded) {
      final current = state as TodoLoaded;
      emit(current.copyWith(isOnline: false));
    }
  }

  Future<bool> _checkOnline() async {
    final result = await connectivity.checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  List<TodoModel> _applyFilter(List<TodoModel> todos, String query) {
    if (query.isEmpty) return todos;
    return todos
        .where((t) => t.title.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  List<TodoModel> _replaceInList(List<TodoModel> todos, TodoModel updated) {
    return todos.map((t) => t.key == updated.key ? updated : t).toList();
  }

  @override
  Future<void> close() {
    _connectivitySub?.cancel();
    return super.close();
  }
}
