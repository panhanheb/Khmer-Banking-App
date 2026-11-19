import 'dart:async';

import 'package:dio/dio.dart';

/// Returns the current Firebase ID token (`null` when signed out).
typedef IdTokenProvider = Future<String?> Function({bool forceRefresh});

/// Attaches the Firebase ID token as a bearer token.
///
/// Firebase refreshes ID tokens automatically. If the API still answers 401,
/// the token is force-refreshed once and the request replayed; if that is not
/// possible (user signed out, disabled or deleted) [onSessionExpired] fires and
/// the router shows the login page.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.idToken,
    this.onSessionExpired,
  });

  static const String skipAuthKey = 'kdb.skipAuth';
  static const String retriedKey = 'kdb.retried';

  /// The client this interceptor is attached to; used to replay requests.
  final Dio dio;
  final IdTokenProvider idToken;
  final void Function()? onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await _safeToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final request = err.requestOptions;
    final body = err.response?.data;
    if (err.response?.statusCode == 401 &&
        body is Map &&
        body['code'] == 'DEVICE_REVOKED') {
      // This device was signed out from another device: sign in again.
      onSessionExpired?.call();
      handler.next(err);
      return;
    }
    if (err.response?.statusCode != 401 ||
        request.extra[skipAuthKey] == true ||
        request.extra[retriedKey] == true) {
      handler.next(err);
      return;
    }

    final String? fresh;
    try {
      fresh = await idToken(forceRefresh: true);
    } catch (_) {
      // Refresh failed (e.g. offline or account disabled server-side);
      // surface the original 401 without signing the user out locally.
      handler.next(err);
      return;
    }
    if (fresh == null) {
      // No signed-in user any more.
      onSessionExpired?.call();
      handler.next(err);
      return;
    }

    try {
      final response = await dio.fetch<dynamic>(
        request.copyWith(
          headers: {...request.headers, 'Authorization': 'Bearer $fresh'},
          extra: {...request.extra, retriedKey: true},
        ),
      );
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<String?> _safeToken({bool forceRefresh = false}) async {
    try {
      return await idToken(forceRefresh: forceRefresh);
    } catch (_) {
      return null;
    }
  }
}
