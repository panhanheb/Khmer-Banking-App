import 'dart:async';

import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Attaches the bearer token and transparently rotates tokens on 401.
///
/// * Single-flight: concurrent 401s share ONE `POST /auth/refresh` call. The
///   backend revokes the whole token family when a refresh token is reused,
///   so two parallel refreshes would log the user out.
/// * If the server rejects the refresh, tokens are wiped and
///   [onSessionExpired] fires (the router then shows the login page).
///   Pure connectivity failures during refresh are propagated as-is without
///   logging the user out.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required this.dio,
    required this.refreshDio,
    required this.tokenStorage,
    this.onSessionExpired,
    this.refreshPath = '/auth/refresh',
  });

  static const String skipAuthKey = 'kdb.skipAuth';
  static const String retriedKey = 'kdb.retried';

  /// The client this interceptor is attached to; used to replay requests.
  final Dio dio;

  /// A separate client WITHOUT this interceptor, used for the refresh call.
  final Dio refreshDio;
  final TokenStorage tokenStorage;
  final void Function()? onSessionExpired;
  final String refreshPath;

  Future<String?>? _inFlightRefresh;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[skipAuthKey] != true) {
      final token = await tokenStorage.readAccessToken();
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
    final isUnauthorized = err.response?.statusCode == 401;
    if (!isUnauthorized ||
        request.extra[skipAuthKey] == true ||
        request.extra[retriedKey] == true) {
      handler.next(err);
      return;
    }

    final usedToken = _bearerOf(request);
    final currentToken = await tokenStorage.readAccessToken();

    String? freshToken;
    if (currentToken != null &&
        usedToken != null &&
        currentToken != usedToken) {
      // Another request already rotated the tokens while this one was in flight.
      freshToken = currentToken;
    } else {
      freshToken = await refreshTokens();
    }

    if (freshToken == null) {
      handler.next(err);
      return;
    }

    try {
      final retryOptions = request.copyWith(
        headers: {...request.headers, 'Authorization': 'Bearer $freshToken'},
        extra: {...request.extra, retriedKey: true},
      );
      final response = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  /// Rotates tokens once, sharing the result with concurrent callers.
  /// Returns the new access token, or `null` if the session is gone.
  Future<String?> refreshTokens() {
    final existing = _inFlightRefresh;
    if (existing != null) return existing;
    final future = _doRefresh();
    _inFlightRefresh = future;
    future.whenComplete(() => _inFlightRefresh = null).ignore();
    return future;
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }
    try {
      final response = await refreshDio.post<dynamic>(
        refreshPath,
        data: {'refreshToken': refreshToken},
        options: Options(extra: {skipAuthKey: true}),
      );
      final data = response.data;
      final access = data is Map ? data['accessToken'] as String? : null;
      final refresh = data is Map ? data['refreshToken'] as String? : null;
      if (access == null || refresh == null) {
        await _expireSession();
        return null;
      }
      await tokenStorage.saveTokens(accessToken: access, refreshToken: refresh);
      return access;
    } on DioException catch (e) {
      if (e.response != null) {
        // Server rejected the refresh token (expired, revoked or reused).
        await _expireSession();
      }
      return null;
    }
  }

  Future<void> _expireSession() async {
    await tokenStorage.clearTokens();
    onSessionExpired?.call();
  }

  static String? _bearerOf(RequestOptions options) {
    final header = options.headers['Authorization'];
    if (header is String && header.startsWith('Bearer ')) {
      return header.substring(7);
    }
    return null;
  }
}
