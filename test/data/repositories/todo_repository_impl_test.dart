import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_app/data/datasources/local/todo_local_datasource.dart';
import 'package:todo_app/data/datasources/remote/todo_remote_datasource.dart';
import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/data/repositories/todo_repository_impl.dart';

class MockRemoteDataSource extends Mock implements TodoRemoteDataSource {}

class MockLocalDataSource extends Mock implements TodoLocalDataSource {}

class MockConnectivity extends Mock implements Connectivity {}

void main() {
  late TodoRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;
  late MockLocalDataSource mockLocal;
  late MockConnectivity mockConnectivity;

  setUpAll(() {
    registerFallbackValue(TodoModel(id: 0, title: '', completed: false));
    registerFallbackValue(ConnectivityResult.wifi);
  });

  setUp(() {
    mockRemote = MockRemoteDataSource();
    mockLocal = MockLocalDataSource();
    mockConnectivity = MockConnectivity();
    repository = TodoRepositoryImpl(
      remote: mockRemote,
      local: mockLocal,
      connectivity: mockConnectivity,
    );
  });

  final tTodoModel = TodoModel(
    id: 1,
    title: 'Test Todo',
    completed: false,
  );

  final tTodoList = [tTodoModel];

  void setupOnline() {
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
  }

  void setupOffline() {
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.none]);
  }

  group('getTodos', () {
    test(
        'should return local data when device is online and remote fetch is successful',
        () async {
      setupOnline();
      when(() => mockRemote.getTodos()).thenAnswer((_) async => tTodoList);
      when(() => mockLocal.cacheTodos(any())).thenAnswer((_) async => {});
      when(() => mockLocal.getCachedTodos()).thenReturn(tTodoList);

      final result = await repository.getTodos();

      verify(() => mockRemote.getTodos()).called(1);
      verify(() => mockLocal.cacheTodos(tTodoList)).called(1);
      expect(result, equals(tTodoList));
    });

    test(
        'should return local data when device is online but remote fetch fails',
        () async {
      setupOnline();
      when(() => mockRemote.getTodos()).thenThrow(Exception());
      when(() => mockLocal.getCachedTodos()).thenReturn(tTodoList);

      final result = await repository.getTodos();

      verify(() => mockRemote.getTodos()).called(1);
      verifyNever(() => mockLocal.cacheTodos(any()));
      expect(result, equals(tTodoList));
    });

    test('should return local data when device is offline', () async {
      setupOffline();
      when(() => mockLocal.getCachedTodos()).thenReturn(tTodoList);

      final result = await repository.getTodos();

      verifyZeroInteractions(mockRemote);
      expect(result, equals(tTodoList));
    });
  });

  group('addTodo', () {
    const tTitle = 'New Todo';

    test('should perform optimistic save and sync when online', () async {
      setupOnline();
      final syncedTodo = tTodoModel.copyWith(id: 100, title: tTitle);
      when(() => mockLocal.saveTodo(any())).thenAnswer((_) async => {});
      when(() => mockRemote.createTodo(any()))
          .thenAnswer((_) async => syncedTodo);
      when(() => mockLocal.deleteTodoByKey(any())).thenAnswer((_) async => {});

      final result = await repository.addTodo(tTitle);

      // Optimistic
      verify(() => mockLocal.saveTodo(any(
            that: isA<TodoModel>()
                .having((t) => t.pendingAction, 'pendingAction', 'create')
                .having((t) => t.id, 'id', -1),
          ))).called(1);

      verify(() => mockRemote.createTodo(tTitle)).called(1);
      verify(() => mockLocal.deleteTodoByKey(any())).called(1);

      // Confirmed
      verify(() => mockLocal.saveTodo(any(
            that: isA<TodoModel>()
                .having((t) => t.id, 'id', 100)
                .having((t) => t.pendingAction, 'pendingAction', 'none'),
          ))).called(1);

      expect(result.id, 100);
    });

    test('should return optimistic todo when offline', () async {
      setupOffline();
      when(() => mockLocal.saveTodo(any())).thenAnswer((_) async => {});

      final result = await repository.addTodo(tTitle);

      verify(() => mockLocal.saveTodo(any())).called(1);
      verifyNever(() => mockRemote.createTodo(any()));
      expect(result.id, -1);
      expect(result.pendingAction, 'create');
    });
  });

  group('toggleTodo', () {
    test('should update local and sync with remote when online and id is valid',
        () async {
      setupOnline();
      when(() => mockLocal.saveTodo(any())).thenAnswer((_) async => {});
      when(() => mockRemote.updateTodo(any(), any()))
          .thenAnswer((_) async => true);

      final result = await repository.toggleTodo(tTodoModel);

      // Optimistic
      verify(() => mockLocal.saveTodo(any(
            that: isA<TodoModel>()
                .having((t) => t.completed, 'completed', true)
                .having((t) => t.pendingAction, 'pendingAction', 'update'),
          ))).called(1);

      verify(() => mockRemote.updateTodo(tTodoModel.id, true)).called(1);

      // Confirmed
      verify(() => mockLocal.saveTodo(any(
            that: isA<TodoModel>()
                .having((t) => t.completed, 'completed', true)
                .having((t) => t.pendingAction, 'pendingAction', 'none'),
          ))).called(1);

      expect(result.completed, true);
    });
  });

  group('syncPending', () {
    test('should sync all pending actions when online', () async {
      setupOnline();
      final pendingTodo =
          tTodoModel.copyWith(id: 1, pendingAction: 'update', isSynced: false);
      when(() => mockLocal.getUnsyncedTodos()).thenReturn([pendingTodo]);
      when(() => mockRemote.updateTodo(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockLocal.saveTodo(any())).thenAnswer((_) async => {});

      final result = await repository.syncPending();

      verify(() => mockRemote.updateTodo(1, false)).called(1);
      verify(() => mockLocal.saveTodo(any(
            that: isA<TodoModel>()
                .having((t) => t.id, 'id', 1)
                .having((t) => t.pendingAction, 'pendingAction', 'none')
                .having((t) => t.isSynced, 'isSynced', true),
          ))).called(1);

      expect(result.success, true);
      expect(result.synced, 1);
    });
  });
}
