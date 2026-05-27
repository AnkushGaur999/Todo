import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_ce_flutter/adapters.dart';
import 'package:todo_app/core/network/api_client.dart';
import 'package:todo_app/core/network/interceptors/auth_interceptor.dart';
import 'package:todo_app/core/network/interceptors/retry_interceptor.dart';
import 'package:todo_app/data/datasources/local/todo_local_datasource.dart';
import 'package:todo_app/data/datasources/remote/todo_remote_datasource.dart';
import 'package:todo_app/data/models/todo_model.dart';
import 'package:todo_app/data/repositories/todo_repository_impl.dart';
import 'package:todo_app/domain/repositories/todo_repository.dart';
import 'package:todo_app/domain/use_cases/add_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/delete_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/get_todos_use_case.dart';
import 'package:todo_app/domain/use_cases/search_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/sync_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/toggle_todo_use_case.dart';
import 'package:todo_app/domain/use_cases/update_todo_use_case.dart';
import 'package:todo_app/presentation/bloc/auth/auth_bloc.dart';
import 'package:todo_app/presentation/bloc/todo/todo_bloc.dart';
import 'package:get_it/get_it.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();
  if (!Hive.isAdapterRegistered(0)) {
    Hive.registerAdapter(TodoModelAdapter());
  }
  final localDataSource = TodoLocalDataSource();
  await localDataSource.init();

  sl.registerSingleton<ApiClient>(
      ApiClient(AuthInterceptor(), RetryInterceptor()));

  sl.registerSingleton<TodoLocalDataSource>(localDataSource);

  sl.registerSingleton<TodoRemoteDataSource>(
    TodoRemoteDataSourceImpl(sl<ApiClient>()),
  );
  sl.registerSingleton<Connectivity>(Connectivity());

  sl.registerSingleton<TodoRepository>(
    TodoRepositoryImpl(
      remote: sl<TodoRemoteDataSource>(),
      local: sl<TodoLocalDataSource>(),
      connectivity: sl<Connectivity>(),
    ),
  );

  sl.registerFactory<AddTodoUseCase>(
      () => AddTodoUseCase(repository: sl<TodoRepository>()));
  sl.registerFactory<DeleteTodoUseCase>(
      () => DeleteTodoUseCase(repository: sl<TodoRepository>()));
  sl.registerFactory<GetTodosUseCase>(
      () => GetTodosUseCase(repository: sl<TodoRepository>()));
  sl.registerFactory<ToggleTodoUseCase>(
      () => ToggleTodoUseCase(repository: sl<TodoRepository>()));
  sl.registerFactory<SearchTodoUseCase>(
      () => SearchTodoUseCase(repository: sl<TodoRepository>()));
  sl.registerFactory<UpdateTodoUseCase>(
      () => UpdateTodoUseCase(repository: sl<TodoRepository>()));
  sl.registerFactory<SyncTodoUseCase>(
      () => SyncTodoUseCase(repository: sl<TodoRepository>()));

  sl.registerFactory<AuthBloc>(() => AuthBloc());

  sl.registerFactory<TodoBloc>(() => TodoBloc(
        addTodoUseCase: sl<AddTodoUseCase>(),
        deleteTodoUseCase: sl<DeleteTodoUseCase>(),
        getTodosUseCase: sl<GetTodosUseCase>(),
        toggleTodoUseCase: sl<ToggleTodoUseCase>(),
        searchTodoUseCase: sl<SearchTodoUseCase>(),
        updateTodoUseCase: sl<UpdateTodoUseCase>(),
        syncTodoUseCase: sl<SyncTodoUseCase>(),
        connectivity: sl<Connectivity>(),
      ));
}
