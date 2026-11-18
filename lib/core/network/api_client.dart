import 'package:dio/dio.dart';

import 'api_exception.dart';
import 'auth_interceptor.dart';

/// Thin wrapper around [Dio] that returns decoded bodies and converts every
/// failure into an [ApiException].
class ApiClient {
  ApiClient(this.dio);

  final Dio dio;

  static Options _options({
    bool authenticated = true,
    Map<String, dynamic>? headers,
  }) {
    return Options(
      headers: headers,
      extra: {if (!authenticated) AuthInterceptor.skipAuthKey: true},
    );
  }

  Future<dynamic> get(
    String path, {
    Map<String, dynamic>? query,
    bool authenticated = true,
  }) {
    return _guard(() => dio.get<dynamic>(
          path,
          queryParameters: query,
          options: _options(authenticated: authenticated),
        ));
  }

  Future<dynamic> post(
    String path, {
    Object? data,
    bool authenticated = true,
    Map<String, dynamic>? headers,
  }) {
    return _guard(() => dio.post<dynamic>(
          path,
          data: data,
          options: _options(authenticated: authenticated, headers: headers),
        ));
  }

  Future<dynamic> put(String path, {Object? data, bool authenticated = true}) {
    return _guard(() => dio.put<dynamic>(
          path,
          data: data,
          options: _options(authenticated: authenticated),
        ));
  }

  Future<dynamic> delete(String path, {bool authenticated = true}) {
    return _guard(() => dio.delete<dynamic>(
          path,
          options: _options(authenticated: authenticated),
        ));
  }

  Future<dynamic> _guard(Future<Response<dynamic>> Function() call) async {
    try {
      final response = await call();
      return response.data;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

/// Builds a configured [Dio] instance for the banking API.
Dio buildDio(
  String baseUrl, {
  Duration connectTimeout = const Duration(seconds: 15),
  Duration receiveTimeout = const Duration(seconds: 30),
}) {
  return Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
      headers: const {'Accept': 'application/json, application/problem+json'},
    ),
  );
}

/// Decodes a JSON object body.
Map<String, dynamic> asJsonMap(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  throw const ApiException(code: ApiException.unknown, detail: 'Unexpected response body');
}

/// Decodes a JSON array body of objects.
List<Map<String, dynamic>> asJsonList(Object? data) {
  if (data is List) {
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }
  throw const ApiException(code: ApiException.unknown, detail: 'Unexpected response body');
}
