import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers/app_preferences_provider.dart';
import '../../../core/themes/app_theme.dart';
import '../../../shared/models/subject_model.dart';
import '../../../shared/models/user_model.dart';
import '../../admin/providers/admin_provider.dart';
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
            Icon(Icons.school_outlined, color: theme.colorScheme.primary),
            const SizedBox(width: 10),
            Text(
              tr('app_name'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.primary,
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
                Center(child: _ProfileAvatar(user: user)),
                const SizedBox(height: 22),
                Text(
                  user.name,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: theme.colorScheme.primary,
                    fontSize: 26,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${_roleLabel(user.role)} - ${user.school}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 36),
                _SettingsCard(
                  title: tr('account_settings'),
                  children: [
                    _SettingsRow(
                      icon: Icons.language_rounded,
                      title: tr('language'),
                      subtitle: _languageSubtitle(context.locale),
                      trailing: _LanguageButton(
                        label: _languageLabel(context.locale),
                        onPressed: () =>
                            _showLanguagePicker(context, ref, user),
                      ),
                    ),
                    _SettingsRow(
                      icon: Icons.dark_mode_outlined,
                      title: tr('dark_mode'),
                      trailing: Switch(
                        value:
                            ref.watch(darkModeOverrideProvider) ??
                            user.darkMode,
                        onChanged: (value) async {
                          ref
                              .read(darkModeOverrideProvider.notifier)
                              .setValue(value);
                          await _updatePreference(ref, user, {
                            'darkMode': value,
                          }, refresh: false);
                        },
                      ),
                    ),
                  ],
                ),
                if (user.isTeacher || user.isStudent) ...[
                  const SizedBox(height: 24),
                  _SubjectPreferenceCard(user: user),
                ],
                const SizedBox(height: 24),
                _SettingsCard(
                  title: tr('account_verification'),
                  children: [
                    _SettingsRow(
                      icon: Icons.verified_user_outlined,
                      title: tr('active'),
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
                const SizedBox(height: 28),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.surface,
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
                          final success = await ref
                              .read(authControllerProvider.notifier)
                              .logout();
                          if (context.mounted && success) {
                            final router = GoRouter.of(context);
                            final navigator = Navigator.of(context);
                            while (navigator.canPop()) {
                              navigator.pop();
                            }
                            router.go('/login');
                          }
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
                  'Testora v1.0.0 - Academic Integrity Guaranteed',
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

  static Future<void> _updatePreference(
    WidgetRef ref,
    UserModel user,
    Map<String, dynamic> data, {
    bool refresh = true,
  }) async {
    await ref
        .read(authRepositoryProvider)
        .updateUserPreferences(user.uid, data);
    if (refresh) {
      ref.invalidate(userProfileProvider);
    }
  }

  static String _languageLabel(Locale locale) {
    return locale.languageCode == 'en' ? 'English' : 'Tetun';
  }

  static String _languageSubtitle(Locale locale) {
    return locale.languageCode == 'en'
        ? tr('language_active_en')
        : tr('language_active_tet');
  }

  static Future<void> _showLanguagePicker(
    BuildContext context,
    WidgetRef ref,
    UserModel user,
  ) async {
    final selected = context.locale.languageCode;
    final picked = await showModalBottomSheet<Locale>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  tr('choose_language'),
                  style: Theme.of(sheetContext).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _LanguageOptionTile(
                  title: 'Tetun',
                  subtitle: tr('language_tet_desc'),
                  locale: const Locale('tet', 'TL'),
                  selected: selected == 'tet',
                ),
                const SizedBox(height: 10),
                _LanguageOptionTile(
                  title: 'English',
                  subtitle: tr('language_en_desc'),
                  locale: const Locale('en', 'US'),
                  selected: selected == 'en',
                ),
              ],
            ),
          ),
        );
      },
    );
    if (picked == null) return;
    if (context.mounted) {
      await context.setLocale(picked);
    }
    await _updatePreference(ref, user, {
      'language': picked.languageCode,
    }, refresh: false);
  }
}

class _LanguageButton extends StatelessWidget {
  const _LanguageButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.tonalIcon(
      style: FilledButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      onPressed: onPressed,
      icon: const Icon(Icons.translate_rounded, size: 18),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label),
          const SizedBox(width: 4),
          const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
        ],
      ),
    );
  }
}

class _LanguageOptionTile extends StatelessWidget {
  const _LanguageOptionTile({
    required this.title,
    required this.subtitle,
    required this.locale,
    required this.selected,
  });

  final String title;
  final String subtitle;
  final Locale locale;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: selected
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.45)
          : theme.colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(16),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: CircleAvatar(
          backgroundColor: selected
              ? theme.colorScheme.primary
              : theme.colorScheme.surface,
          foregroundColor: selected
              ? theme.colorScheme.onPrimary
              : theme.colorScheme.primary,
          child: Text(title[0]),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
        subtitle: Text(subtitle),
        trailing: selected
            ? Icon(Icons.check_circle_rounded, color: theme.colorScheme.primary)
            : const Icon(Icons.radio_button_unchecked_rounded),
        onTap: () => Navigator.pop(context, locale),
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 128,
      height: 128,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(8, 10),
          ),
        ],
      ),
      child: CircleAvatar(
        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.08),
        foregroundImage: user.photoUrl.isNotEmpty
            ? NetworkImage(user.photoUrl)
            : null,
        child: user.photoUrl.isEmpty
            ? Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                style: const TextStyle(
                  fontSize: 46,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.primaryColor,
                ),
              )
            : null,
      ),
    );
  }
}

class _SubjectPreferenceCard extends ConsumerStatefulWidget {
  const _SubjectPreferenceCard({required this.user});

  final UserModel user;

  @override
  ConsumerState<_SubjectPreferenceCard> createState() =>
      _SubjectPreferenceCardState();
}

class _SubjectPreferenceCardState extends ConsumerState<_SubjectPreferenceCard> {
  String? _scheduledSelectedId;

  void _syncDefaultSubjectAfterBuild(String selectedId) {
    if (_scheduledSelectedId == selectedId) return;
    _scheduledSelectedId = selectedId;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || _scheduledSelectedId != selectedId) return;

      ref.read(selectedSubjectOverrideProvider.notifier).setValue(selectedId);
      await ProfileScreen._updatePreference(ref, widget.user, {
        'selectedSubjectId': selectedId,
      }, refresh: false);

      if (mounted && _scheduledSelectedId == selectedId) {
        _scheduledSelectedId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final subjectsAsync = widget.user.isTeacher
        ? ref.watch(teacherSubjectsProvider(widget.user.uid))
        : ref.watch(studentSubjectsProvider(widget.user.uid));

    return subjectsAsync.when(
      data: (subjects) {
        if (subjects.isEmpty) {
          return _SettingsCard(
            title: tr('active_subject'),
            children: [
              _SettingsRow(
                icon: Icons.menu_book_outlined,
                title: tr('no_subjects'),
                subtitle: tr('selected_subject_desc'),
                trailing: const SizedBox.shrink(),
              ),
            ],
          );
        }

        final profileSelectedIsValid = subjects.any(
          (subject) => subject.id == widget.user.selectedSubjectId,
        );
        final overrideSelectedId = ref.watch(selectedSubjectOverrideProvider);
        final activeSelectedId =
            overrideSelectedId ?? widget.user.selectedSubjectId;
        final activeSelectedIsValid = subjects.any(
          (subject) => subject.id == activeSelectedId,
        );
        final selectedId = activeSelectedIsValid
            ? activeSelectedId
            : profileSelectedIsValid
            ? widget.user.selectedSubjectId
            : subjects.first.id;
        if (!profileSelectedIsValid && overrideSelectedId != selectedId) {
          _syncDefaultSubjectAfterBuild(selectedId);
        }

        return _SettingsCard(
          title: tr('active_subject'),
          children: [
            _SubjectDropdown(
              subjects: subjects,
              selectedId: selectedId,
              onChanged: (value) {
                if (value == null) return;
                ref
                    .read(selectedSubjectOverrideProvider.notifier)
                    .setValue(value);
                ProfileScreen._updatePreference(ref, widget.user, {
                  'selectedSubjectId': value,
                }, refresh: false);
              },
            ),
          ],
        );
      },
      loading: () => _SettingsCard(
        title: tr('active_subject'),
        children: const [
          Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 14),
              child: CircularProgressIndicator(),
            ),
          ),
        ],
      ),
      error: (_, __) => _SettingsCard(
        title: tr('active_subject'),
        children: [
          _SettingsRow(
            icon: Icons.error_outline_rounded,
            title: tr('error_occurred'),
            trailing: const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _SubjectDropdown extends StatelessWidget {
  const _SubjectDropdown({
    required this.subjects,
    required this.selectedId,
    required this.onChanged,
  });

  final List<SubjectModel> subjects;
  final String selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: DropdownButtonFormField<String>(
        initialValue: selectedId,
        decoration: InputDecoration(
          labelText: tr('choose_subject'),
          helperText: tr('selected_subject_desc'),
          prefixIcon: const Icon(Icons.menu_book_outlined),
        ),
        items: subjects
            .map(
              (subject) => DropdownMenuItem<String>(
                value: subject.id,
                child: Text(subject.name),
              ),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(8, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: theme.textTheme.bodyMedium),
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
