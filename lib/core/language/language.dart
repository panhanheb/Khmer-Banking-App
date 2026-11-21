import 'package:flutter/widgets.dart';

import '../network/api_exception.dart';
import 'tr.dart';

export 'tr.dart';

extension LanguageX on BuildContext {
  /// Current language code (`km` or `en`).
  String get languageCode => Localizations.localeOf(this).languageCode;
}

/// Maps any error raised by the data layer to a localized, user-facing
/// message. Server `detail` text is not shown verbatim because it is English
/// only; stable `code`s are translated instead.
String localizedError(Object error) {
  if (error is! ApiException) return 'errorGeneric'.tr;
  final key = switch (error.code) {
    ApiException.networkError => 'errorNetwork',
    ApiException.timeout => 'errorTimeout',
    ApiException.invalidCredentials => 'errorInvalidCredentials',
    ApiException.tokenExpired || ApiException.tokenInvalid => 'sessionExpired',
    ApiException.accountLocked => 'errorAccountLocked',
    ApiException.pinLocked => 'errorPinLocked',
    ApiException.invalidOtp => 'errorInvalidOtp',
    ApiException.otpExpired => 'errorOtpExpired',
    ApiException.invalidPin => 'errorInvalidPin',
    ApiException.pinNotSet => 'errorPinNotSet',
    ApiException.forbidden => 'errorForbidden',
    ApiException.notFound => 'errorNotFound',
    ApiException.recipientNotFound => 'errorRecipientNotFound',
    ApiException.duplicate => 'errorDuplicate',
    ApiException.idempotencyConflict => 'errorIdempotencyConflict',
    ApiException.phoneAlreadyRegistered => 'errorPhoneRegistered',
    ApiException.emailAlreadyRegistered => 'errorEmailRegistered',
    ApiException.insufficientBalance => 'errorInsufficientBalance',
    ApiException.limitExceeded => 'errorLimitExceeded',
    ApiException.accountNotActive => 'errorAccountNotActive',
    ApiException.sameAccount => 'errorSameAccount',
    ApiException.rateLimited => 'errorRateLimited',
    ApiException.validationError => 'errorValidation',
    _ => 'errorGeneric',
  };
  return key.tr;
}
