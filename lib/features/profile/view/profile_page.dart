import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/di.dart';
import '../../../app/navigation.dart';
import '../../../app/pages.dart';
import '../../../core/bloc/load_status.dart';
import '../../../core/l10n/l10n.dart';
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
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final user = state.user;
          if (user == null) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(l10n, state.error!),
                retryLabel: l10n.commonRetry,
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
                SectionHeader(title: l10n.personalInfo),
                _PersonalInfo(user: user),
                const SizedBox(height: 8),
                SectionHeader(title: l10n.settings),
                const _SettingsSection(),
                const SizedBox(height: 8),
                SectionHeader(title: l10n.security),
                _SecuritySection(user: user),
                const SizedBox(height: 24),
                AppButton(
                  label: l10n.logout,
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
    final l10n = context.l10n;
    final confirmed = await ConfirmationBottomSheet.show(
      context,
      title: l10n.logout,
      message: l10n.logoutConfirm,
      icon: Icons.logout,
      confirmLabel: l10n.logout,
      cancelLabel: l10n.commonCancel,
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
          child: Text(
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
              Text(
                user.displayName(context.languageCode),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
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
    final l10n = context.l10n;
    final (kycLabel, kycColor) = switch (user.kycStatus) {
      'VERIFIED' => (l10n.kycVerified, AppColors.success),
      'REJECTED' => (l10n.kycRejected, AppColors.error),
      _ => (l10n.kycPending, AppColors.warning),
    };
    final nameKm = user.fullNameKm;
    final email = user.email;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            DetailRow(label: l10n.fullNameEnLabel, value: user.fullNameEn),
            if (nameKm != null && nameKm.trim().isNotEmpty)
              DetailRow(label: l10n.fullNameKmLabel, value: nameKm),
            DetailRow(label: l10n.phoneLabel, value: user.phone),
            if (email != null && email.isNotEmpty)
              DetailRow(label: l10n.emailLabel, value: email),
            DetailRow(
              label: l10n.kycStatus,
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
    final l10n = context.l10n;
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
                Text(l10n.language),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(value: 'km', label: Text(l10n.languageKhmer)),
                    ButtonSegment(
                      value: 'en',
                      label: Text(l10n.languageEnglish),
                    ),
                  ],
                  selected: {language},
                  onSelectionChanged: (s) => context.read<SettingsBloc>().add(
                    SettingsLanguageChanged(s.first),
                  ),
                ),
                const SizedBox(height: 16),
                Text(l10n.theme),
                const SizedBox(height: 8),
                SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_outlined),
                      label: Text(l10n.themeLight),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_outlined),
                      label: Text(l10n.themeDark),
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_outlined),
                      label: Text(l10n.themeSystem),
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
    final l10n = context.l10n;
    final settings = context.read<SettingsBloc>();
    final messenger = ScaffoldMessenger.of(context);
    if (!enable) {
      settings.add(const SettingsBiometricChanged(false));
      return;
    }
    final biometrics = sl<BiometricService>();
    if (!await biometrics.isAvailable()) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.biometricUnavailable)),
      );
      return;
    }
    final ok = await biometrics.authenticate(l10n.biometricReasonUnlock);
    if (ok) {
      settings.add(const SettingsBiometricChanged(true));
    } else {
      messenger.showSnackBar(SnackBar(content: Text(l10n.biometricFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          BlocBuilder<SettingsBloc, SettingsState>(
            buildWhen: (a, b) =>
                a.settings.biometricEnabled != b.settings.biometricEnabled,
            builder: (context, state) => SwitchListTile(
              secondary: const Icon(Icons.fingerprint),
              title: Text(l10n.biometricUnlock),
              subtitle: Text(l10n.biometricUnlockSubtitle),
              value: state.settings.biometricEnabled,
              onChanged: (v) => _toggleBiometric(context, v),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.pin_outlined),
            title: Text(user.pinSet ? l10n.changePin : l10n.setPinAction),
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
            title: Text(l10n.changePassword),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushPage(Pages.changePassword()),
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.devices_other),
            title: Text(l10n.devices),
            subtitle: Text(l10n.devicesSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.pushPage(Pages.devices()),
          ),
        ],
      ),
    );
  }
}
