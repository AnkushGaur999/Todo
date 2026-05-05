part of 'todo_bloc.dart';

sealed class TodoStates extends Equatable {
  @override
  List<Object?> get props => [];
}

final class TodoInitial extends TodoStates {}

final class TodoLoading extends TodoStates {}

final class TodoLoaded extends TodoStates {
  final List<TodoModel> todos;
  final List<TodoModel> filtered;
  final String searchQuery;
  final bool isOnline;
  final bool isSyncing;
  final String? syncMessage;
  final String? errorMessage;

  TodoLoaded({
    required this.todos,
    List<TodoModel>? filtered,
    this.searchQuery = '',
    this.isOnline = true,
    this.isSyncing = false,
    this.syncMessage,
    this.errorMessage,
  }) : filtered = filtered ?? todos;

  TodoLoaded copyWith({
    List<TodoModel>? todos,
    List<TodoModel>? filtered,
    String? searchQuery,
    bool? isOnline,
    bool? isSyncing,
    String? syncMessage,
    String? errorMessage,
    bool clearSyncMessage = false,
    bool clearError = false,
  }) =>
      TodoLoaded(
        todos: todos ?? this.todos,
        filtered: filtered ?? this.filtered,
        searchQuery: searchQuery ?? this.searchQuery,
        isOnline: isOnline ?? this.isOnline,
        isSyncing: isSyncing ?? this.isSyncing,
        syncMessage:
            clearSyncMessage ? null : (syncMessage ?? this.syncMessage),
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );

  int get pendingCount => todos.where((t) => !t.isSynced).length;

  @override
  List<Object?> get props => [
        todos,
        filtered,
        searchQuery,
        isOnline,
        isSyncing,
        syncMessage,
        errorMessage,
      ];
}

final class TodoError extends TodoStates {
  final String message;

  TodoError(this.message);

  @override
  List<Object?> get props => [message];
}
