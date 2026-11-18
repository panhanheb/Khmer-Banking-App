import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import '../core/bloc/app_event_bus.dart';
import '../core/config/app_config.dart';
import '../core/device/device_info_service.dart';
import '../core/network/api_client.dart';
import '../core/network/auth_interceptor.dart';
import '../core/security/biometric_service.dart';
import '../core/storage/key_value_store.dart';
import '../core/storage/token_storage.dart';
import '../features/accounts/model/accounts_remote_data_source.dart';
import '../features/accounts/model/accounts_repository_impl.dart';
import '../features/accounts/model/account.dart';
import '../features/accounts/model/accounts_repository.dart';
import '../features/accounts/model/account_usecases.dart';
import '../features/accounts/view_model/account_detail_bloc.dart';
import '../features/accounts/view_model/accounts_bloc.dart';
import '../features/accounts/view_model/open_account_bloc.dart';
import '../features/auth/model/auth_remote_data_source.dart';
import '../features/auth/model/auth_repository_impl.dart';
import '../features/auth/model/auth_repository.dart';
import '../features/auth/model/credential_usecases.dart';
import '../features/auth/model/login_usecases.dart';
import '../features/auth/model/registration_usecases.dart';
import '../features/auth/view_model/auth_bloc.dart';
import '../features/auth/view_model/login_bloc.dart';
import '../features/auth/view_model/otp_bloc.dart';
import '../features/auth/view_model/password_reset_bloc.dart';
import '../features/auth/view_model/pin_setup_bloc.dart';
import '../features/auth/view_model/register_bloc.dart';
import '../features/home/view_model/home_bloc.dart';
import '../features/profile/model/profile_remote_data_source.dart';
import '../features/profile/model/profile_repository_impl.dart';
import '../features/profile/model/profile_repository.dart';
import '../features/profile/model/get_current_user.dart';
import '../features/profile/view_model/change_password_bloc.dart';
import '../features/profile/view_model/devices_bloc.dart';
import '../features/profile/view_model/profile_bloc.dart';
import '../features/settings/model/settings_repository_impl.dart';
import '../features/settings/model/settings_repository.dart';
import '../features/settings/model/settings_usecases.dart';
import '../features/settings/view_model/settings_bloc.dart';
import '../features/transactions/model/transactions_remote_data_source.dart';
import '../features/transactions/model/transactions_repository_impl.dart';
import '../features/transactions/model/bank_transaction.dart';
import '../features/transactions/model/transactions_repository.dart';
import '../features/transactions/model/transaction_usecases.dart';
import '../features/transactions/view_model/transaction_detail_bloc.dart';
import '../features/transactions/view_model/transactions_bloc.dart';
import '../features/transfer/model/transfer_remote_data_source.dart';
import '../features/transfer/model/transfer_repository_impl.dart';
import '../features/transfer/model/transfer_repository.dart';
import '../features/transfer/model/transfer_usecases.dart';
import '../features/transfer/view_model/transfer_bloc.dart';

final GetIt sl = GetIt.instance;

/// Registers every dependency. Call once before `runApp`.
Future<void> configureDependencies({
  String baseUrl = AppConfig.apiBaseUrl,
  KeyValueStore? store,
}) async {
  // ---- Core ----
  sl
    ..registerLazySingleton<KeyValueStore>(() => store ?? SecureKeyValueStore())
    ..registerLazySingleton(() => TokenStorage(sl()))
    ..registerLazySingleton(() => DeviceInfoService(sl()))
    ..registerLazySingleton(BiometricService.new)
    ..registerLazySingleton(AppEventBus.new);

  final dio = buildDio(
    baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  );
  final refreshDio = buildDio(
    baseUrl,
    connectTimeout: AppConfig.connectTimeout,
    receiveTimeout: AppConfig.receiveTimeout,
  );
  dio.interceptors.add(AuthInterceptor(
    dio: dio,
    refreshDio: refreshDio,
    tokenStorage: sl(),
    onSessionExpired: () => sl<AuthBloc>().add(const AuthSessionExpired()),
  ));
  sl
    ..registerSingleton<Dio>(dio)
    ..registerLazySingleton(() => ApiClient(sl()));

  // ---- Data sources ----
  sl
    ..registerLazySingleton(() => AuthRemoteDataSource(sl()))
    ..registerLazySingleton(() => ProfileRemoteDataSource(sl()))
    ..registerLazySingleton(() => AccountsRemoteDataSource(sl()))
    ..registerLazySingleton(() => TransactionsRemoteDataSource(sl()))
    ..registerLazySingleton(() => TransferRemoteDataSource(sl()));

  // ---- Repositories ----
  sl
    ..registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
          remote: sl(),
          tokenStorage: sl(),
          deviceInfo: sl(),
        ))
    ..registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(sl()))
    ..registerLazySingleton<ProfileRepository>(
        () => ProfileRepositoryImpl(sl()))
    ..registerLazySingleton<AccountsRepository>(
        () => AccountsRepositoryImpl(sl()))
    ..registerLazySingleton<TransactionsRepository>(
        () => TransactionsRepositoryImpl(sl()))
    ..registerLazySingleton<TransferRepository>(
        () => TransferRepositoryImpl(sl()));

  // ---- Use cases ----
  sl
    ..registerFactory(() => LoginUseCase(sl()))
    ..registerFactory(() => VerifyLoginMfaUseCase(sl()))
    ..registerFactory(() => CheckSessionUseCase(sl()))
    ..registerFactory(() => LogoutUseCase(sl()))
    ..registerFactory(() => RegisterUseCase(sl()))
    ..registerFactory(() => VerifyOtpUseCase(sl()))
    ..registerFactory(() => ForgotPasswordUseCase(sl()))
    ..registerFactory(() => ResetPasswordUseCase(sl()))
    ..registerFactory(() => ChangePasswordUseCase(sl()))
    ..registerFactory(() => SetPinUseCase(sl()))
    ..registerFactory(() => GetDevicesUseCase(sl()))
    ..registerFactory(() => RevokeDeviceUseCase(sl()))
    ..registerFactory(() => LoadSettingsUseCase(sl()))
    ..registerFactory(() => UpdateLanguageUseCase(sl()))
    ..registerFactory(() => UpdateThemeModeUseCase(sl()))
    ..registerFactory(() => UpdateBiometricUseCase(sl()))
    ..registerFactory(() => GetCurrentUserUseCase(sl()))
    ..registerFactory(() => GetAccountsUseCase(sl()))
    ..registerFactory(() => GetAccountUseCase(sl()))
    ..registerFactory(() => OpenAccountUseCase(sl()))
    ..registerFactory(() => GetAccountTransactionsUseCase(sl()))
    ..registerFactory(() => GetTransactionsUseCase(sl()))
    ..registerFactory(() => GetTransactionUseCase(sl()))
    ..registerFactory(() => LookupRecipientUseCase(sl()))
    ..registerFactory(() => GetTransferQuoteUseCase(sl()))
    ..registerFactory(() => SubmitTransferUseCase(sl()));

  // ---- App-wide BLoCs ----
  final initialSettings = await sl<SettingsRepository>().load();
  sl
    ..registerLazySingleton(() => AuthBloc(
          checkSession: sl(),
          logout: sl(),
          settings: sl(),
        ))
    ..registerLazySingleton(() => SettingsBloc(
          loadSettings: sl(),
          updateLanguage: sl(),
          updateTheme: sl(),
          updateBiometric: sl(),
          initial: initialSettings,
        ));

  // ---- Screen BLoCs (new instance per screen) ----
  sl
    ..registerFactory(() => LoginBloc(login: sl()))
    ..registerFactory(() => RegisterBloc(register: sl()))
    ..registerFactoryParam<OtpBloc, OtpArgs, void>(
      (args, _) => OtpBloc(args: args, verifyOtp: sl(), verifyLoginMfa: sl()),
    )
    ..registerFactory(() => PasswordResetBloc(
          forgotPassword: sl(),
          resetPassword: sl(),
        ))
    ..registerFactoryParam<PinSetupBloc, PinSetupMode, void>(
      (mode, _) => PinSetupBloc(mode: mode, setPin: sl()),
    )
    ..registerFactory(() => HomeBloc(
          getCurrentUser: sl(),
          getAccounts: sl(),
          getTransactions: sl(),
          eventBus: sl(),
        ))
    ..registerFactory(() => ProfileBloc(getCurrentUser: sl(), eventBus: sl()))
    ..registerFactory(() => DevicesBloc(getDevices: sl(), revokeDevice: sl()))
    ..registerFactory(() => ChangePasswordBloc(changePassword: sl()))
    ..registerFactory(() => AccountsBloc(getAccounts: sl(), eventBus: sl()))
    ..registerFactory(() => OpenAccountBloc(openAccount: sl(), eventBus: sl()))
    ..registerFactoryParam<AccountDetailBloc, String, Account?>(
      (id, initial) => AccountDetailBloc(
        accountId: id,
        getAccount: sl(),
        initial: initial,
      ),
    )
    ..registerFactory(() {
      final useCase = sl<GetTransactionsUseCase>();
      return TransactionsBloc(
        loadPage: ({required page, required size, required filter}) =>
            useCase(page: page, size: size, filter: filter),
      );
    })
    ..registerFactoryParam<TransactionDetailBloc, BankTransaction?, void>(
      (initial, _) => TransactionDetailBloc(
        getTransaction: sl(),
        initial: initial,
      ),
    )
    ..registerFactory(() => TransferBloc(
          getAccounts: sl(),
          lookupRecipient: sl(),
          getQuote: sl(),
          submitTransfer: sl(),
          eventBus: sl(),
        ));
}

/// History bloc bound to a single account's endpoint.
TransactionsBloc accountHistoryBloc(String accountId) {
  final useCase = sl<GetAccountTransactionsUseCase>();
  return TransactionsBloc(
    loadPage: ({required page, required size, required filter}) =>
        useCase(accountId, page: page, size: size, filter: filter),
  );
}
