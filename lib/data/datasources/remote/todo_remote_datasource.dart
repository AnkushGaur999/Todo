import 'package:dio/dio.dart';
import 'package:todo_app/core/network/api_client.dart';
import '../../models/todo_model.dart';

abstract class TodoRemoteDataSource {
  Future<List<TodoModel>> getTodos();

  Future<TodoModel> createTodo(String title);

  Future<bool> updateTodo(int id, bool completed);

  Future<void> deleteTodo(int id);
}

class TodoRemoteDataSourceImpl implements TodoRemoteDataSource {
  final ApiClient apiClient;

  TodoRemoteDataSourceImpl(this.apiClient);

  @override
  Future<List<TodoModel>> getTodos() async {
    try {
      final response = await apiClient.get(
        path: 'todos',
        queryParameters: {'_limit': 20},
      );
      return (response.data as List)
          .map((e) => TodoModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<TodoModel> createTodo(String title) async {
    try {
      final response = await apiClient.post(
        path: 'todos',
        data: {'title': title, 'completed': false, 'userId': 1},
      );
      return TodoModel.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<bool> updateTodo(int id, bool completed) async {
    try {
      final response = await apiClient.update(
        path: 'todos/$id',
        data: {'completed': completed},
      );
      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  @override
  Future<void> deleteTodo(int id) async {
    try {
      await apiClient.delete(path: 'todos/$id');
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Exception _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return Exception('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return Exception('No internet connection.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        return Exception('Server error: $statusCode');
      default:
        return Exception('Unexpected error: ${e.message}');
    }
  }
}
