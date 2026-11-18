// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Khmer Digital Bank';

  @override
  String get appTagline => 'Banking made simple and secure';

  @override
  String get commonOk => 'OK';

  @override
  String get commonContinue => 'Continue';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonDone => 'Done';

  @override
  String get commonSave => 'Save';

  @override
  String get commonClose => 'Close';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonCopy => 'Copy';

  @override
  String get commonCopied => 'Copied to clipboard';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonApply => 'Apply';

  @override
  String get commonReset => 'Reset';

  @override
  String get commonAll => 'All';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonChange => 'Change';

  @override
  String get commonLoadMoreFailed => 'Couldn\'t load more. Tap to retry.';

  @override
  String get comingSoonTitle => 'Coming soon';

  @override
  String comingSoonMessage(String feature) {
    return '$feature is not available yet. We\'re working on it.';
  }

  @override
  String get navHome => 'Home';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navTransfer => 'Transfer';

  @override
  String get navProfile => 'Profile';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in with your phone number';

  @override
  String get phoneLabel => 'Phone number';

  @override
  String get phoneHint => '012 345 678';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign in';

  @override
  String get forgotPasswordLink => 'Forgot password?';

  @override
  String get noAccountPrompt => 'Don\'t have an account?';

  @override
  String get registerLink => 'Create account';

  @override
  String get haveAccountPrompt => 'Already have an account?';

  @override
  String get registerTitle => 'Create your account';

  @override
  String get registerSubtitle => 'Join Khmer Digital Bank in a minute';

  @override
  String get fullNameEnLabel => 'Full name (English)';

  @override
  String get fullNameKmLabel => 'Full name (Khmer)';

  @override
  String get emailLabel => 'Email';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get passwordPolicyHint =>
      'At least 8 characters with upper and lower case letters, a digit and a symbol';

  @override
  String get registerButton => 'Create account';

  @override
  String get otpTitle => 'Verify your phone';

  @override
  String get otpMfaTitle => 'Verify new device';

  @override
  String get otpSubtitle => 'Enter the 6-digit code we sent by SMS';

  @override
  String otpDevHint(String code) {
    return 'Development code: $code';
  }

  @override
  String get otpVerifyButton => 'Verify';

  @override
  String get otpVerifiedRegistration => 'Phone verified. Please sign in.';

  @override
  String get forgotTitle => 'Forgot password';

  @override
  String get forgotSubtitle =>
      'Enter your phone number to receive a reset code';

  @override
  String get sendCodeButton => 'Send code';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetSubtitle =>
      'Enter the code we sent and choose a new password';

  @override
  String get otpCodeLabel => 'Verification code';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get resetButton => 'Reset password';

  @override
  String get resetSuccess => 'Password reset. Please sign in again.';

  @override
  String get setPinTitle => 'Set transaction PIN';

  @override
  String get changePinTitle => 'Change transaction PIN';

  @override
  String get pinEnterCurrent => 'Enter your current PIN';

  @override
  String get pinEnterNew => 'Enter a new 6-digit PIN';

  @override
  String get pinConfirmNew => 'Re-enter the new PIN';

  @override
  String get pinMismatch => 'PINs do not match';

  @override
  String get pinWeak => 'Avoid simple PINs like 123456 or 111111';

  @override
  String get pinSetSuccess => 'Transaction PIN saved';

  @override
  String get pinNotSetBanner =>
      'Set your transaction PIN to start sending money';

  @override
  String get lockTitle => 'Unlock Khmer Digital Bank';

  @override
  String get lockUnlockButton => 'Unlock';

  @override
  String get lockUsePassword => 'Sign in with password';

  @override
  String get biometricReasonUnlock => 'Unlock your banking app';

  @override
  String get biometricReasonTransfer => 'Confirm this transfer';

  @override
  String get biometricFailed => 'Biometric authentication failed';

  @override
  String get logout => 'Log out';

  @override
  String get logoutConfirm => 'Are you sure you want to log out?';

  @override
  String get sessionExpired =>
      'Your session has expired. Please sign in again.';

  @override
  String get validationRequired => 'This field is required';

  @override
  String get validationPhone => 'Enter a valid Cambodian phone number';

  @override
  String get validationEmail => 'Enter a valid email';

  @override
  String get validationPassword => 'Password does not meet the policy';

  @override
  String get validationPasswordMatch => 'Passwords do not match';

  @override
  String get validationAmount => 'Enter a valid amount';

  @override
  String get validationAmountExceedsBalance =>
      'Amount exceeds available balance';

  @override
  String get validationAccountNumber => 'Enter a valid account number';

  @override
  String get validationOtp => 'Enter the 6-digit code';

  @override
  String get greetingMorning => 'Good morning';

  @override
  String get greetingAfternoon => 'Good afternoon';

  @override
  String get greetingEvening => 'Good evening';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get hideBalance => 'Hide balance';

  @override
  String get showBalance => 'Show balance';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get actionTransfer => 'Transfer';

  @override
  String get actionScanQr => 'Scan QR';

  @override
  String get actionDeposit => 'Deposit';

  @override
  String get actionWithdraw => 'Withdraw';

  @override
  String get actionPayBills => 'Pay bills';

  @override
  String get actionTopUp => 'Top up';

  @override
  String get actionHistory => 'History';

  @override
  String get myAccounts => 'My accounts';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get noAccountsYet => 'You don\'t have any accounts yet';

  @override
  String get noTransactionsYet => 'No transactions yet';

  @override
  String get accountsTitle => 'Accounts';

  @override
  String get openAccount => 'Open account';

  @override
  String get openAccountTitle => 'Open a new account';

  @override
  String get accountType => 'Account type';

  @override
  String get accountTypeCurrent => 'Current';

  @override
  String get accountTypeSavings => 'Savings';

  @override
  String get currency => 'Currency';

  @override
  String get nicknameLabel => 'Nickname';

  @override
  String get accountOpened => 'Account opened successfully';

  @override
  String get accountNumber => 'Account number';

  @override
  String get availableBalance => 'Available balance';

  @override
  String get ledgerBalance => 'Balance';

  @override
  String get accountStatus => 'Status';

  @override
  String get statusActive => 'Active';

  @override
  String get statusFrozen => 'Frozen';

  @override
  String get statusClosed => 'Closed';

  @override
  String openedOn(String date) {
    return 'Opened $date';
  }

  @override
  String get accountHistory => 'Account history';

  @override
  String get accountDetails => 'Account details';

  @override
  String get transactionsTitle => 'Transactions';

  @override
  String get searchTransactionsHint => 'Search reference, name or description';

  @override
  String get filters => 'Filters';

  @override
  String get filterType => 'Type';

  @override
  String get filterStatus => 'Status';

  @override
  String get filterCurrency => 'Currency';

  @override
  String get filterDateRange => 'Date range';

  @override
  String get selectDateRange => 'Select dates';

  @override
  String get txTypeTransfer => 'Transfer';

  @override
  String get txTypeDeposit => 'Deposit';

  @override
  String get txTypeWithdrawal => 'Withdrawal';

  @override
  String get txTypeFee => 'Fee';

  @override
  String get txTypeReversal => 'Reversal';

  @override
  String get txTypeQrPayment => 'QR payment';

  @override
  String get txTypeBillPayment => 'Bill payment';

  @override
  String get txTypeTopup => 'Top up';

  @override
  String get txStatusPending => 'Pending';

  @override
  String get txStatusCompleted => 'Completed';

  @override
  String get txStatusFailed => 'Failed';

  @override
  String get txStatusReversed => 'Reversed';

  @override
  String get simulatedBadge => 'SIMULATED';

  @override
  String get simulatedNotice =>
      'This is a simulated development transaction. No real money was moved.';

  @override
  String get transactionDetails => 'Transaction details';

  @override
  String get reference => 'Reference';

  @override
  String get description => 'Description';

  @override
  String get counterparty => 'Counterparty';

  @override
  String get fee => 'Fee';

  @override
  String get dateTime => 'Date and time';

  @override
  String get noTransactionsFound => 'No transactions match your filters';

  @override
  String get transferTitle => 'Transfer money';

  @override
  String get stepFrom => 'From';

  @override
  String get stepTo => 'To';

  @override
  String get stepAmount => 'Amount';

  @override
  String get stepReview => 'Review';

  @override
  String get selectSourceAccount => 'Select source account';

  @override
  String get recipientTitle => 'Who are you sending to?';

  @override
  String get byAccountNumber => 'Account number';

  @override
  String get byPhone => 'Phone number';

  @override
  String get findRecipient => 'Find recipient';

  @override
  String get recipient => 'Recipient';

  @override
  String get amountLabel => 'Amount';

  @override
  String get descriptionHint => 'What\'s it for?';

  @override
  String get reviewButton => 'Review transfer';

  @override
  String get reviewTitle => 'Review transfer';

  @override
  String get youSend => 'You send';

  @override
  String get recipientGets => 'Recipient gets';

  @override
  String get exchangeRate => 'Exchange rate';

  @override
  String get totalDebit => 'Total debit';

  @override
  String get dailyLimitRemaining => 'Daily limit remaining';

  @override
  String get confirmAndSend => 'Confirm and send';

  @override
  String get enterPinTitle => 'Enter transaction PIN';

  @override
  String get enterPinSubtitle =>
      'Authorize this transfer with your 6-digit PIN';

  @override
  String get processing => 'Processing...';

  @override
  String get receiptTitle => 'Transfer receipt';

  @override
  String get transferSuccessful => 'Transfer successful';

  @override
  String get transferPending => 'Transfer pending';

  @override
  String get transferFailed => 'Transfer failed';

  @override
  String get fromAccount => 'From account';

  @override
  String get toAccount => 'To account';

  @override
  String get newTransfer => 'New transfer';

  @override
  String get setPinAction => 'Set PIN';

  @override
  String get free => 'Free';

  @override
  String get bankName => 'Bank';

  @override
  String get profileTitle => 'Profile';

  @override
  String get personalInfo => 'Personal information';

  @override
  String get kycStatus => 'KYC status';

  @override
  String get kycPending => 'Pending verification';

  @override
  String get kycVerified => 'Verified';

  @override
  String get kycRejected => 'Rejected';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get languageEnglish => 'English';

  @override
  String get theme => 'Theme';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get themeSystem => 'System';

  @override
  String get security => 'Security';

  @override
  String get biometricUnlock => 'Biometric unlock';

  @override
  String get biometricUnlockSubtitle =>
      'Use fingerprint or Face ID to open the app';

  @override
  String get biometricUnavailable =>
      'Biometrics are not available on this device';

  @override
  String get devices => 'Devices';

  @override
  String get devicesSubtitle => 'Manage signed-in devices';

  @override
  String get thisDevice => 'This device';

  @override
  String get trusted => 'Trusted';

  @override
  String lastSeen(String date) {
    return 'Last seen $date';
  }

  @override
  String get revoke => 'Revoke';

  @override
  String revokeDeviceConfirm(String device) {
    return 'Revoke access for $device? It will be signed out.';
  }

  @override
  String get deviceRevoked => 'Device revoked';

  @override
  String get changePassword => 'Change password';

  @override
  String get passwordChanged => 'Password changed';

  @override
  String get changePin => 'Change PIN';

  @override
  String get noDevices => 'No devices found';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get errorNetwork =>
      'No internet connection. Check your network and try again.';

  @override
  String get errorTimeout => 'The request timed out. Please try again.';

  @override
  String get errorInvalidCredentials => 'Incorrect phone number or password';

  @override
  String get errorAccountLocked =>
      'Your account is temporarily locked. Try again later.';

  @override
  String get errorPinLocked =>
      'Your PIN is locked after too many wrong attempts';

  @override
  String get errorInvalidOtp => 'Invalid verification code';

  @override
  String get errorOtpExpired => 'The code has expired';

  @override
  String get errorInvalidPin => 'Incorrect PIN';

  @override
  String get errorPinNotSet => 'Please set your transaction PIN first';

  @override
  String get errorRecipientNotFound => 'Recipient not found';

  @override
  String get errorNotFound => 'Not found';

  @override
  String get errorPhoneRegistered => 'This phone number is already registered';

  @override
  String get errorDuplicate => 'Duplicate request';

  @override
  String get errorIdempotencyConflict =>
      'This transfer conflicts with an earlier request. Please start again.';

  @override
  String get errorInsufficientBalance => 'Insufficient balance';

  @override
  String get errorLimitExceeded => 'Transfer limit exceeded';

  @override
  String get errorAccountNotActive => 'The account is not active';

  @override
  String get errorSameAccount => 'You cannot transfer to the same account';

  @override
  String get errorRateLimited =>
      'Too many attempts. Please wait and try again.';

  @override
  String get errorForbidden => 'You don\'t have permission to do this';

  @override
  String get errorValidation => 'Please check the information you entered';
}
