import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/bloc/app_event_bus.dart';
import '../../../core/bloc/load_status.dart';
import '../model/get_current_user.dart';
import 'profile_event.dart';
import 'profile_state.dart';

export 'profile_event.dart';
export 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  ProfileBloc({
    required GetCurrentUserUseCase getCurrentUser,
    AppEventBus? eventBus,
  }) : _getCurrentUser = getCurrentUser,
       super(const ProfileState()) {
    on<ProfileRequested>(_onRequested);
    _subscription = eventBus?.stream
        .where((e) => e == AppEvent.profileChanged)
        .listen((_) => add(const ProfileRequested()));
  }

  final GetCurrentUserUseCase _getCurrentUser;
  StreamSubscription<AppEvent>? _subscription;

  Future<void> _onRequested(
    ProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileState(status: LoadStatus.loading, user: state.user));
    try {
      final user = await _getCurrentUser();
      emit(ProfileState(status: LoadStatus.success, user: user));
    } catch (e) {
      emit(
        ProfileState(status: LoadStatus.failure, user: state.user, error: e),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
