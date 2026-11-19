import 'auth_entities.dart';
import 'auth_repository.dart';

class LoginWithEmailUseCase {
  const LoginWithEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email, required String password}) =>
      _repository.loginWithEmail(email: email, password: password);
}

class SendPhoneLoginCodeUseCase {
  const SendPhoneLoginCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<PhoneCodeResult> call({required String phone}) =>
      _repository.sendPhoneLoginCode(phone: phone);
}

class VerifyPhoneLoginCodeUseCase {
  const VerifyPhoneLoginCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String verificationId, required String code}) =>
      _repository.verifyPhoneLoginCode(
        verificationId: verificationId,
        code: code,
      );
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
