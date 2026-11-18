import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/bloc/load_status.dart';
import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../auth/domain/entities/auth_entities.dart';
import '../bloc/devices_bloc.dart';

/// Signed-in devices with the option to revoke the other ones.
class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.devices)),
      body: BlocConsumer<DevicesBloc, DevicesState>(
        listenWhen: (a, b) =>
            (b.revokedId != null && a.revokedId != b.revokedId) ||
            (b.error != null && b.devices.isNotEmpty && a.error != b.error),
        listener: (context, state) {
          final message = state.error != null
              ? localizedError(l10n, state.error!)
              : l10n.deviceRevoked;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(message)));
        },
        builder: (context, state) {
          if (state.devices.isEmpty) {
            if (state.status.isFailure) {
              return AppErrorWidget(
                message: localizedError(l10n, state.error!),
                retryLabel: l10n.commonRetry,
                onRetry: () =>
                    context.read<DevicesBloc>().add(const DevicesRequested()),
              );
            }
            if (state.status.isLoading || state.status == LoadStatus.initial) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: LoadingWidget.list(count: 3),
              );
            }
            return EmptyStateWidget(
              icon: Icons.devices_other,
              title: l10n.noDevices,
            );
          }
          return RefreshIndicator(
            onRefresh: () async {
              final bloc = context.read<DevicesBloc>()
                ..add(const DevicesRequested());
              await bloc.stream.firstWhere((s) => !s.status.isLoading);
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: state.devices.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, i) => _DeviceTile(
                device: state.devices[i],
                revoking: state.revokingId == state.devices[i].id,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DeviceTile extends StatelessWidget {
  const _DeviceTile({required this.device, required this.revoking});

  final DeviceSession device;
  final bool revoking;

  IconData get _icon => switch (device.platform.toLowerCase()) {
        'ios' || 'android' => Icons.smartphone,
        'web' => Icons.language,
        _ => Icons.computer,
      };

  Future<void> _revoke(BuildContext context) async {
    final l10n = context.l10n;
    final bloc = context.read<DevicesBloc>();
    final confirmed = await ConfirmationBottomSheet.show(
      context,
      title: l10n.revoke,
      message: l10n.revokeDeviceConfirm(device.deviceName),
      icon: Icons.phonelink_erase,
      confirmLabel: l10n.revoke,
      cancelLabel: l10n.commonCancel,
      destructive: true,
    );
    if (confirmed) bloc.add(DeviceRevokeRequested(device.id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final lastSeen = device.lastSeenAt;
    return Card(
      child: ListTile(
        leading: Icon(_icon, color: theme.colorScheme.primary),
        title: Text(device.deviceName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (lastSeen != null)
              Text(l10n.lastSeen(
                DateFormatter.dateTime(lastSeen, context.languageCode),
              )),
            if (device.current || device.trusted) ...[
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                children: [
                  if (device.current)
                    AppBadge(label: l10n.thisDevice, color: AppColors.royalBlue),
                  if (device.trusted)
                    AppBadge(label: l10n.trusted, color: AppColors.success),
                ],
              ),
            ],
          ],
        ),
        trailing: device.current
            ? null
            : revoking
                ? const SizedBox.square(
                    dimension: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () => _revoke(context),
                    child: Text(l10n.revoke),
                  ),
      ),
    );
  }
}
