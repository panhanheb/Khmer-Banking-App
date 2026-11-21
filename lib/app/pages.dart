import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../features/accounts/model/account.dart';
import '../features/accounts/view/account_detail_page.dart';
import '../features/accounts/view/accounts_page.dart';
import '../features/accounts/view/open_account_page.dart';
import '../features/accounts/view_model/account_detail_bloc.dart';
import '../features/accounts/view_model/accounts_bloc.dart';
import '../features/accounts/view_model/open_account_bloc.dart';
import '../features/auth/view/forgot_password_page.dart';
import '../features/auth/view/login_page.dart';
import '../features/auth/view/otp_page.dart';
import '../features/auth/view/register_page.dart';
import '../features/auth/view/set_pin_page.dart';
import '../features/auth/view_model/login_bloc.dart';
import '../features/auth/view_model/otp_bloc.dart';
import '../features/auth/view_model/password_reset_bloc.dart';
import '../features/auth/view_model/pin_setup_bloc.dart';
import '../features/auth/view_model/register_bloc.dart';
import '../features/home/view/home_page.dart';
import '../features/home/view_model/home_bloc.dart';
import '../features/profile/view/change_password_page.dart';
import '../features/profile/view/devices_page.dart';
import '../features/profile/view/profile_page.dart';
import '../features/profile/view_model/change_password_bloc.dart';
import '../features/profile/view_model/devices_bloc.dart';
import '../features/profile/view_model/profile_bloc.dart';
import '../features/transactions/model/bank_transaction.dart';
import '../features/transactions/view/transaction_detail_page.dart';
import '../features/transactions/view/transactions_page.dart';
import '../features/transactions/view_model/transaction_detail_bloc.dart';
import '../features/transactions/view_model/transactions_bloc.dart';
import '../features/transfer/model/transfer_entities.dart';
import '../features/transfer/view/transfer_page.dart';
import '../features/transfer/view/transfer_receipt_page.dart';
import '../features/transfer/view_model/transfer_bloc.dart';
import 'di.dart';

/// Builds every screen together with the BLoCs it needs.
/// Open one with `context.pushPage(Pages.xxx())` (see `navigation.dart`).
class Pages {
  const Pages._();

  // ---- Auth ----

  static Widget login() =>
      BlocProvider(create: (_) => sl<LoginBloc>(), child: const LoginPage());

  static Widget register() => BlocProvider(
    create: (_) => sl<RegisterBloc>(),
    child: const RegisterPage(),
  );

  static Widget otp(OtpArgs args) => BlocProvider(
    create: (_) => sl<OtpBloc>(param1: args),
    child: OtpPage(args: args),
  );

  static Widget forgotPassword() => BlocProvider(
    create: (_) => sl<PasswordResetBloc>(),
    child: const ForgotPasswordPage(),
  );

  static Widget setPin([PinSetupMode mode = PinSetupMode.set]) => BlocProvider(
    create: (_) => sl<PinSetupBloc>(param1: mode),
    child: SetPinPage(mode: mode),
  );

  // ---- Main tabs ----

  static Widget home() => BlocProvider(
    create: (_) => sl<HomeBloc>()..add(const HomeStarted()),
    child: const HomePage(),
  );

  static Widget transactions() => BlocProvider(
    create: (_) => sl<TransactionsBloc>()..add(const TransactionsStarted()),
    child: const TransactionsPage(),
  );

  /// The Transfer tab, or a transfer started from an account ([fromAccountId]).
  static Widget transfer({String? fromAccountId}) => BlocProvider(
    create: (_) =>
        sl<TransferBloc>()
          ..add(TransferStarted(preselectedAccountId: fromAccountId)),
    child: TransferPage(preselectedAccountId: fromAccountId),
  );

  static Widget profile() => BlocProvider(
    create: (_) => sl<ProfileBloc>()..add(const ProfileRequested()),
    child: const ProfilePage(),
  );

  // ---- Accounts ----

  static Widget accounts() => BlocProvider(
    create: (_) => sl<AccountsBloc>()..add(const AccountsRequested()),
    child: const AccountsPage(),
  );

  static Widget openAccount() => BlocProvider(
    create: (_) => sl<OpenAccountBloc>(),
    child: const OpenAccountPage(),
  );

  static Widget accountDetail(String id, {Account? initial}) =>
      MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (_) =>
                sl<AccountDetailBloc>(param1: id, param2: initial)
                  ..add(const AccountDetailRequested()),
          ),
          BlocProvider(
            create: (_) =>
                accountHistoryBloc(id)..add(const TransactionsStarted()),
          ),
        ],
        child: const AccountDetailPage(),
      );

  // ---- Transactions & transfers ----

  static Widget transactionDetail(String id, {BankTransaction? initial}) =>
      BlocProvider(
        create: (_) =>
            sl<TransactionDetailBloc>(param1: initial)
              ..add(TransactionDetailRequested(id)),
        child: const TransactionDetailPage(),
      );

  static Widget transferReceipt(TransferReceipt receipt) =>
      TransferReceiptPage(receipt: receipt);

  // ---- Profile ----

  static Widget devices() => BlocProvider(
    create: (_) => sl<DevicesBloc>()..add(const DevicesRequested()),
    child: const DevicesPage(),
  );

  static Widget changePassword() => BlocProvider(
    create: (_) => sl<ChangePasswordBloc>(),
    child: const ChangePasswordPage(),
  );
}
