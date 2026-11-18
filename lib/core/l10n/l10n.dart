import 'package:flutter/widgets.dart';

import '../../l10n/app_localizations.dart';
import '../network/api_exception.dart';

export '../../l10n/app_localizations.dart';

extension L10nX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);

  /// Current language code (`km` or `en`).
  String get languageCode => Localizations.localeOf(this).languageCode;
}

/// Maps any error raised by the data layer to a localized, user-facing
/// message. Server `detail` text is not shown verbatim because it is English
/// only; stable `code`s are translated instead.
String localizedError(AppLocalizations l10n, Object error) {
  if (error is! ApiException) return l10n.errorGeneric;
  switch (error.code) {
    case ApiException.networkError:
      return l10n.errorNetwork;
    case ApiException.timeout:
      return l10n.errorTimeout;
    case ApiException.invalidCredentials:
      return l10n.errorInvalidCredentials;
    case ApiException.tokenExpired:
    case ApiException.tokenInvalid:
      return l10n.sessionExpired;
    case ApiException.accountLocked:
      return l10n.errorAccountLocked;
    case ApiException.pinLocked:
      return l10n.errorPinLocked;
    case ApiException.invalidOtp:
      return l10n.errorInvalidOtp;
    case ApiException.otpExpired:
      return l10n.errorOtpExpired;
    case ApiException.invalidPin:
      return l10n.errorInvalidPin;
    case ApiException.pinNotSet:
      return l10n.errorPinNotSet;
    case ApiException.forbidden:
      return l10n.errorForbidden;
    case ApiException.notFound:
      return l10n.errorNotFound;
    case ApiException.recipientNotFound:
      return l10n.errorRecipientNotFound;
    case ApiException.duplicate:
      return l10n.errorDuplicate;
    case ApiException.idempotencyConflict:
      return l10n.errorIdempotencyConflict;
    case ApiException.phoneAlreadyRegistered:
      return l10n.errorPhoneRegistered;
    case ApiException.insufficientBalance:
      return l10n.errorInsufficientBalance;
    case ApiException.limitExceeded:
      return l10n.errorLimitExceeded;
    case ApiException.accountNotActive:
      return l10n.errorAccountNotActive;
    case ApiException.sameAccount:
      return l10n.errorSameAccount;
    case ApiException.rateLimited:
      return l10n.errorRateLimited;
    case ApiException.validationError:
      return l10n.errorValidation;
    default:
      return l10n.errorGeneric;
  }
}
