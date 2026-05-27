import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:todo_app/core/network/interceptors/auth_interceptor.dart';

class MockRequestInterceptorHandler extends Mock
    implements RequestInterceptorHandler {}

void main() {
  late AuthInterceptor authInterceptor;
  late MockRequestInterceptorHandler mockHandler;

  setUp(() {
    authInterceptor = AuthInterceptor();
    mockHandler = MockRequestInterceptorHandler();
  });

  test('should add Authorization header to request', () {
    final options = RequestOptions(path: '/test');

    authInterceptor.onRequest(options, mockHandler);

    expect(options.headers['Authorization'], 'Bearer test123');
    verify(() => mockHandler.next(options)).called(1);
  });
}
