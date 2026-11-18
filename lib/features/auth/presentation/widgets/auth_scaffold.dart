import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/widgets/brand_logo.dart';
import '../../../settings/presentation/bloc/settings_bloc.dart';

/// Shared layout for the unauthenticated screens.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.showLogo = true,
    this.showBack = false,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool showLogo;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: showBack,
        actions: const [LanguageToggle(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (showLogo) ...[
                    const Center(child: BrandLogo(size: 64)),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    title,
                    textAlign: showLogo ? TextAlign.center : TextAlign.start,
                    style: theme.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      textAlign: showLogo ? TextAlign.center : TextAlign.start,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Compact km/en switch shown on auth screens.
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final isKm = context.languageCode == 'km';
    return TextButton.icon(
      onPressed: () => context
          .read<SettingsBloc>()
          .add(SettingsLanguageChanged(isKm ? 'en' : 'km')),
      icon: const Icon(Icons.translate, size: 18),
      label: Text(isKm ? context.l10n.languageEnglish : context.l10n.languageKhmer),
    );
  }
}
