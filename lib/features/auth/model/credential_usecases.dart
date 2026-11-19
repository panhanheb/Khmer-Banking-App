import 'auth_entities.dart';
import 'auth_repository.dart';

class SendPasswordResetEmailUseCase {
  const SendPasswordResetEmailUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) =>
      _repository.sendPasswordResetEmail(email: email);
}

class ChangePasswordUseCase {
  const ChangePasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String currentPassword,
    required String newPassword,
  }) => _repository.changePassword(
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
