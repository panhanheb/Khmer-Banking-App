import 'auth_entities.dart';
import 'auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<RegistrationResult> call(RegisterParams params) =>
      _repository.register(params);
}

class VerifyOtpUseCase {
  const VerifyOtpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String challengeId, required String code}) =>
      _repository.verifyOtp(challengeId: challengeId, code: code);
}
