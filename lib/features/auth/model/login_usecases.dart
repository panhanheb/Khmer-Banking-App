import 'auth_entities.dart';
import 'auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);

  final AuthRepository _repository;

  Future<LoginResult> call({required String phone, required String password}) =>
      _repository.login(phone: phone, password: password);
}

class VerifyLoginMfaUseCase {
  const VerifyLoginMfaUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String challengeId, required String code}) =>
      _repository.verifyLoginMfa(challengeId: challengeId, code: code);
}

class CheckSessionUseCase {
  const CheckSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<bool> call() => _repository.hasSession();
}

class LogoutUseCase {
  const LogoutUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.logout();
}
