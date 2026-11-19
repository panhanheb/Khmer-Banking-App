import 'auth_entities.dart';
import 'auth_repository.dart';

class RegisterUseCase {
  const RegisterUseCase(this._repository);

  final AuthRepository _repository;

  Future<PhoneCodeResult> call(RegisterParams params) =>
      _repository.register(params);
}

class VerifyRegistrationCodeUseCase {
  const VerifyRegistrationCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String verificationId, required String code}) =>
      _repository.verifyRegistrationCode(
        verificationId: verificationId,
        code: code,
      );
}
