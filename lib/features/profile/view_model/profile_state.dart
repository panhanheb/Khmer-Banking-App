import 'package:equatable/equatable.dart';

import '../../../core/bloc/load_status.dart';
import '../model/user_profile.dart';

class ProfileState extends Equatable {
  const ProfileState({
    this.status = LoadStatus.initial,
    this.user,
    this.error,
  });

  final LoadStatus status;
  final UserProfile? user;
  final Object? error;

  @override
  List<Object?> get props => [status, user, error];
}
