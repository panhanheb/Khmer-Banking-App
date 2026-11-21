import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/language/language.dart';
import '../../../core/security/biometric_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/widgets.dart';
import '../../auth/view_model/auth_bloc.dart';
import '../../auth/view_model/pin_setup_state.dart';
import '../../settings/view_model/settings_bloc.dart';
import '../model/user_profile.dart';
import '../view_model/profile_bloc.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: AppLabel('profileTitle'.tr)),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(state.error!),
                retryLabel: 'commonRetry'.tr,
                onRetry: () =>
                    context.read<ProfileBloc>().add(const ProfileRequested()),
              );
            }
            return Padding(
              padding: const EdgeInsets.all(16),
              child: LoadingWidget.card(height: 240),
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<ProfileBloc>()
                ..add(const ProfileRequested());
              await bloc.stream.firstWhere((s) => !s.status.isLoading);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: [
                _ProfileHeader(user: user),
                const SizedBox(height: 16),
                SectionHeader(title: 'personalInfo'.tr),
                _PersonalInfo(user: user),
                const SizedBox(height: 8),
                SectionHeader(title: 'settings'.tr),
                const _SettingsSection(),
                const SizedBox(height: 8),
                SectionHeader(title: 'security'.tr),
                _SecuritySection(user: user),
                const SizedBox(height: 24),
                AppButton(
                  label: 'logout'.tr,
                  icon: Icons.logout,
                  variant: AppButtonVariant.outline,
                  onPressed: () => _logout(context),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await ConfirmationBottomSheet.show(
      context,
      title: 'logout'.tr,
      message: 'logoutConfirm'.tr,
      icon: Icons.logout,
      confirmLabel: 'logout'.tr,
      cancelLabel: 'commonCancel'.tr,
      destructive: true,
    );
    if (confirmed && context.mounted) {
      context.read<AuthBloc>().add(const AuthLogoutRequested());
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: AppColors.gold.withValues(alpha: 0.25),
          child: AppLabel(
            user.initials,
            style: const TextStyle(
              color: AppColors.navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppLabel(
                user.displayName(context.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              AppLabel(
                user.phone,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PersonalInfo extends StatelessWidget {
  const _PersonalInfo({required this.user});

  final UserProfile user;

  @override
  Widget build(BuildContext context) {
    final (kycLabel, kycColor) = switch (user.kycStatus) {
      'VERIFIED' => ('kycVerified'.tr, AppColors.success),
      'REJECTED' => ('kycRejected'.tr, AppColors.error),
      _ => ('kycPending'.tr, AppColors.warning),
    };
    final nameKm = user.fullNameKm;
    final email = user.email;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            DetailRow(label: 'fullNameEnLabel'.tr, value: user.fullNameEn),
            if (nameKm != null && nameKm.trim().isNotEmpty)
              DetailRow(label: 'fullNameKmLabel'.tr, value: nameKm),
            DetailRow(label: 'phoneLabel'.tr, value: user.phone),
            if (email != null && email.isNotEmpty)
              DetailRow(label: 'emailLabel'.tr, value: email),
            DetailRow(
              label: 'kycStatus'.tr,
              value: '',
              trailing: AppBadge(label: kycLabel, color: kycColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SettingsBloc, SettingsState>(
      builder: (context, state) {
        final settings = state.settings;
        final language = settings.languageCode ?? context.languageCode;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppLabel('language'.tr),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: 'km',
                      label: AppLabel('languageKhmer'.tr),
                    ),
                    ButtonSegment(
                      value: 'en',
                      label: AppLabel('languageEnglish'.tr),
                    ),
                  ],
                  selected: {language},
                  onSelectionChanged: (s) => context.read<SettingsBloc>().add(
                    SettingsLanguageChanged(s.first),
                  ),
                ),
                const SizedBox(height: 16),
                AppLabel('theme'.tr),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: AppLabel('themeLight'.tr),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: AppLabel('themeDark'.tr),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_outlined),
                      label: AppLabel('themeSystem'.tr),
                    ),
                  ],
                  selected: {settings.themeMode},
                  onSelectionChanged: (s) => context.read<SettingsBloc>().add(
                    SettingsThemeChanged(s.first),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({required this.user});

  final UserProfile user;

  Future<void> _toggleBiometric(BuildContext context, bool enable) async {
    final settings = context.read<SettingsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    if (!enable) {
      settings.add(const SettingsBiometricChanged(false));
      return;
    }
    final biometrics = sl<BiometricService>();
    if (!await biometrics.isAvailable()) {
      messenger.showSnackBar(
        SnackBar(content: AppLabel('biometricUnavailable'.tr)),
      );
      return;
    }
    final ok = await biometrics.authenticate('biometricReasonUnlock'.tr);
    if (ok) {
      settings.add(const SettingsBiometricChanged(true));
    } else {
      messenger.showSnackBar(SnackBar(content: AppLabel('biometricFailed'.tr)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          BlocBuilder<SettingsBloc, SettingsState>(
            buildWhen: (a, b) =>
                a.settings.biometricEnabled != b.settings.biometricEnabled,
            builder: (context, state) => SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: AppLabel('biometricUnlock'.tr),
              subtitle: AppLabel('biometricUnlockSubtitle'.tr),
              value: state.settings.biometricEnabled,
              onChanged: (v) => _toggleBiometric(context, v),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: AppLabel(user.pinSet ? 'changePin'.tr : 'setPinAction'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushPage(
              Pages.setPin(
                user.pinSet ? PinSetupMode.change : PinSetupMode.set,
              ),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.lock_reset),
            title: AppLabel('changePassword'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushPage(Pages.changePassword()),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.devices_other),
            title: AppLabel('devices'.tr),
            subtitle: AppLabel('devicesSubtitle'.tr),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushPage(Pages.devices()),
          ),
        ],
      ),
    );
  }
}
