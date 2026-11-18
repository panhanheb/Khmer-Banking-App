/// Route paths.
class Routes {
  const Routes._();

  static const splash = '/splash';
  static const lock = '/lock';
  static const login = '/login';
  static const register = '/register';
  static const otp = '/otp';
  static const forgotPassword = '/forgot-password';

  static const home = '/home';
  static const transactions = '/transactions';
  static const transfer = '/transfer';
  static const transferReceipt = '/transfer/receipt';
  static const profile = '/profile';

  static const accounts = '/accounts';
  static const openAccount = '/accounts/open';
  static const setPin = '/set-pin';
  static const devices = '/profile/devices';
  static const changePassword = '/profile/change-password';

  static String accountDetail(String id) => '/accounts/$id';
  static String transactionDetail(String id) => '/transactions/$id';
  static String transferFrom(String accountId) => '/transfer?from=$accountId';

  /// Reachable without a session.
  static const public = {login, register, otp, forgotPassword};
}
