import '../../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

class ProfileRemoteDataSource {
  const ProfileRemoteDataSource(this._client);

  final ApiClient _client;

  Future<UserProfileModel> getMe() async {
    final data = await _client.get('/users/me');
    return UserProfileModel.fromJson(asJsonMap(data));
  }
}
