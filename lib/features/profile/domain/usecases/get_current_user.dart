import '../entities/user_profile.dart';
import '../repositories/profile_repository.dart';

class GetCurrentUserUseCase {
  const GetCurrentUserUseCase(this._repository);

  final ProfileRepository _repository;

  Future<UserProfile> call() => _repository.getMe();
}
