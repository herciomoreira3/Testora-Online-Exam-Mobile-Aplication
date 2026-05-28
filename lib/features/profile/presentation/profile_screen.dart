import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final authState = ref.watch(authControllerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        titleSpacing: 20,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Row(
          children: [
            const Icon(Icons.school_outlined, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            Text(
              tr('app_name'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.primaryColor,
                fontSize: 30,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: userProfileAsync.when(
          data: (user) {
            if (user == null) {
              return Center(child: Text(tr('error_occurred')));
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 32, 20, 28),
              children: [
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 128,
                        height: 128,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Color(0x33CBD5E1),
                              blurRadius: 24,
                              offset: Offset(8, 10),
                            ),
                            BoxShadow(
                              color: Colors.white,
                              blurRadius: 16,
                              offset: Offset(-6, -6),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: AppTheme.primaryColor.withValues(
                            alpha: 0.08,
                          ),
                          child: Text(
                            user.name.isNotEmpty
                                ? user.name[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              fontSize: 46,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -4,
                        bottom: 12,
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                          child: const Icon(
                            Icons.edit_outlined,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_roleLabel(user.role)} • ${user.school}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: const Color(0xFF444653),
                  ),
                ),
                const SizedBox(height: 36),
                _SettingsCard(
                  title: tr('account_settings'),
                  children: [
                    _SettingsRow(
                      icon: Icons.language_rounded,
                      title: tr('language'),
                      trailing: SegmentedButton<Locale>(
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          visualDensity: VisualDensity.compact,
                          backgroundColor: WidgetStateProperty.resolveWith((
                            states,
                          ) {
                            if (states.contains(WidgetState.selected)) {
                              return Colors.white;
                            }
                            return const Color(0xFFF1F5F9);
                          }),
                        ),
                        segments: const [
                          ButtonSegment(
                            value: Locale('en', 'US'),
                            label: Text('English'),
                          ),
                          ButtonSegment(
                            value: Locale('tet', 'TL'),
                            label: Text('Tetun'),
                          ),
                        ],
                        selected: {context.locale},
                        onSelectionChanged: (selection) {
                          context.setLocale(selection.first);
                        },
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.light_mode_outlined,
                      title: tr('dark_mode'),
                      trailing: Switch(value: false, onChanged: (_) {}),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsCard(
                  title: tr('notifications_security'),
                  children: [
                    _SettingsRow(
                      icon: Icons.notifications_none_rounded,
                      title: tr('exam_notifications'),
                      subtitle: tr('exam_notifications_desc'),
                      trailing: Switch(value: true, onChanged: (_) {}),
                    ),
                    _SettingsRow(
                      icon: Icons.lock_outline_rounded,
                      title: tr('change_password'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                    _SettingsRow(
                      icon: Icons.verified_user_outlined,
                      title: tr('account_verification'),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          tr('active'),
                          style: const TextStyle(
                            color: Color(0xFF005236),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _SettingsCard(
                  title: tr('help'),
                  children: [
                    _SettingsRow(
                      icon: Icons.help_outline_rounded,
                      title: tr('help_center'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                    _SettingsRow(
                      icon: Icons.description_outlined,
                      title: tr('terms_conditions'),
                      trailing: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.errorColor,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  onPressed: authState.isLoading
                      ? null
                      : () async {
                          await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (context.mounted) context.go('/login');
                        },
                  icon: authState.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.logout_rounded),
                  label: Text(
                    tr('logout_app'),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Testora v1.0.0 • Academic Integrity Guaranteed',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text(tr('error_occurred'))),
        ),
      ),
    );
  }

  String _roleLabel(String role) {
    if (role == 'admin') return tr('admin');
    if (role == 'teacher') return tr('teacher');
    return tr('student');
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1FCBD5E1),
            blurRadius: 24,
            offset: Offset(8, 12),
          ),
          BoxShadow(
            color: Colors.white,
            blurRadius: 16,
            offset: Offset(-6, -6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF757684),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.trailing,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x1FCBD5E1),
                  blurRadius: 10,
                  offset: Offset(4, 5),
                ),
              ],
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF191C1E),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: const TextStyle(color: Color(0xFF757684)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          trailing,
        ],
      ),
    );
  }
}
