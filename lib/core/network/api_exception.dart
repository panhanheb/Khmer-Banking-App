import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';

/// Error raised by the data layer. Built from RFC 7807 problem details
/// returned by the backend (`code` is the stable machine-readable key) or
/// from transport failures (network, timeout).
class ApiException extends Equatable implements Exception {
  const ApiException({
    required this.code,
    this.statusCode,
    this.title,
    this.detail,
    this.traceId,
    this.fieldErrors = const {},
  });

  // Client-side codes (never sent by the server).
  static const String networkError = 'NETWORK_ERROR';
  static const String timeout = 'TIMEOUT';
  static const String cancelled = 'CANCELLED';
  static const String unknown = 'UNKNOWN';
  static const String serverError = 'SERVER_ERROR';

  // Server codes (see docs/API.md).
  static const String validationError = 'VALIDATION_ERROR';
  static const String invalidCredentials = 'INVALID_CREDENTIALS';
  static const String tokenExpired = 'TOKEN_EXPIRED';
  static const String tokenInvalid = 'TOKEN_INVALID';
  static const String accountLocked = 'ACCOUNT_LOCKED';
  static const String pinLocked = 'PIN_LOCKED';
  static const String invalidOtp = 'INVALID_OTP';
  static const String otpExpired = 'OTP_EXPIRED';
  static const String invalidPin = 'INVALID_PIN';
  static const String pinNotSet = 'PIN_NOT_SET';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String recipientNotFound = 'RECIPIENT_NOT_FOUND';
  static const String duplicate = 'DUPLICATE';
  static const String idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const String phoneAlreadyRegistered = 'PHONE_ALREADY_REGISTERED';
  static const String insufficientBalance = 'INSUFFICIENT_BALANCE';
  static const String limitExceeded = 'LIMIT_EXCEEDED';
  static const String accountNotActive = 'ACCOUNT_NOT_ACTIVE';
  static const String sameAccount = 'SAME_ACCOUNT';
  static const String rateLimited = 'RATE_LIMITED';

  final String code;
  final int? statusCode;
  final String? title;
  final String? detail;
  final String? traceId;
  final Map<String, String> fieldErrors;

  /// True when the request may not have reached the server. Money-moving
  /// calls may only be retried with the same Idempotency-Key.
  bool get isConnectivity => code == networkError || code == timeout;

  factory ApiException.fromDioException(DioException e) {
    final inner = e.error;
    if (inner is ApiException) return inner;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return const ApiException(code: timeout);
      case DioExceptionType.connectionError:
      case DioExceptionType.badCertificate:
        return const ApiException(code: networkError);
      case DioExceptionType.cancel:
        return const ApiException(code: cancelled);
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        final response = e.response;
        if (response == null) {
          return const ApiException(code: networkError);
        }
        return ApiException.fromResponse(response.statusCode, response.data);
    }
  }

  /// Maps an HTTP error body (ideally RFC 7807) to an [ApiException].
  factory ApiException.fromResponse(int? status, Object? data) {
    Map<String, dynamic>? body;
    if (data is Map) {
      body = Map<String, dynamic>.from(data);
    } else if (data is String && data.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) body = Map<String, dynamic>.from(decoded);
      } on FormatException {
        body = null;
      }
    }
    final rawErrors = body?['errors'];
    final fieldErrors = <String, String>{};
    if (rawErrors is Map) {
      rawErrors.forEach((k, v) => fieldErrors['$k'] = '$v');
    }
    return ApiException(
      code: (body?['code'] as String?) ?? _codeForStatus(status),
      statusCode: (body?['status'] as num?)?.toInt() ?? status,
      title: body?['title'] as String?,
      detail: body?['detail'] as String?,
      traceId: body?['traceId'] as String?,
      fieldErrors: fieldErrors,
    );
  }

  static String _codeForStatus(int? status) {
    switch (status) {
      case 400:
        return validationError;
      case 401:
        return tokenInvalid;
      case 403:
        return forbidden;
      case 404:
        return notFound;
      case 409:
        return duplicate;
      case 429:
        return rateLimited;
      default:
        if (status != null && status >= 500) return serverError;
        return unknown;
    }
  }

  @override
  List<Object?> get props =>
      [code, statusCode, title, detail, traceId, fieldErrors];

  @override
  String toString() => 'ApiException($code, $statusCode, $detail)';
}
