import 'dart:io';

import 'package:dio/dio.dart';

class RetryInterceptor extends Interceptor {
  static const _maxRetries = 3;
  static const _retryDelay = Duration(seconds: 2);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (_shouldRetry(err)) {
      final attempt = (err.requestOptions.extra['retryCount'] as int?) ?? 0;
      if (attempt < _maxRetries) {
        err.requestOptions.extra['retryCount'] = attempt + 1;
        await Future.delayed(_retryDelay * (attempt + 1));
        try {
          final response = await Dio().fetch(err.requestOptions);
          return handler.resolve(response);
        } on DioException catch (e) {
          return handler.next(e);
        }
      }
    }
    handler.next(err);
  }

  bool _shouldRetry(DioException err) =>
      err.type == DioExceptionType.connectionTimeout ||
      err.type == DioExceptionType.receiveTimeout ||
      err.error is SocketException;
}
