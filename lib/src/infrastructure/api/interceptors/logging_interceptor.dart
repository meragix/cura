import 'package:dio/dio.dart';

/// Interceptor : Logging HTTP (verbose mode uniquement)
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    print('→ ${options.method} ${options.uri}');
    if (options.data != null) {
      print('  Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    print('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    print('✗ ${err.requestOptions.method} ${err.requestOptions.uri}');
    print('  Error: ${err.message}');
    handler.next(err);
  }
}
