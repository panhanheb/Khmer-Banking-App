import 'auth_entities.dart';
import 'auth_repository.dart';

class ForgotPasswordUseCase {
  const ForgotPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<String> call({required String phone}) =>
      _repository.forgotPassword(phone: phone);
}

class ResetPasswordUseCase {
  const ResetPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String challengeId,
    required String code,
    required String newPassword,
  }) =>
      _repository.resetPassword(
        challengeId: challengeId,
        code: code,
        newPassword: newPassword,
      );
}

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) =>
      _repository.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
}

class SetPinUseCase {
  const SetPinUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({String? currentPin, required String newPin}) =>
      _repository.setPin(currentPin: currentPin, newPin: newPin);
}

class GetDevicesUseCase {
  const GetDevicesUseCase(this._repository);

  final AuthRepository _repository;

  Future<List<DeviceSession>> call() => _repository.getDevices();
}

class RevokeDeviceUseCase {
  const RevokeDeviceUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String id) => _repository.revokeDevice(id);
}
