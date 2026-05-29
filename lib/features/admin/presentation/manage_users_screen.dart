import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/user_model.dart';
import '../providers/admin_provider.dart';

enum _UserRoleFilter { all, admin, teacher, student, pending }

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  static const List<String> _roles = ['student', 'teacher', 'admin'];
  final _searchController = TextEditingController();
  _UserRoleFilter _filter = _UserRoleFilter.all;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return tr('admin');
      case 'teacher':
        return tr('teacher');
      case 'student':
        return tr('student');
      default:
        return tr('new_user');
    }
  }

  String _filterLabel(_UserRoleFilter filter) {
    switch (filter) {
      case _UserRoleFilter.admin:
        return tr('admin');
      case _UserRoleFilter.teacher:
        return tr('teacher');
      case _UserRoleFilter.student:
        return tr('student');
      case _UserRoleFilter.pending:
        return tr('new_user');
      case _UserRoleFilter.all:
        return tr('all');
    }
  }

  IconData _filterIcon(_UserRoleFilter filter) {
    switch (filter) {
      case _UserRoleFilter.admin:
        return Icons.admin_panel_settings_outlined;
      case _UserRoleFilter.teacher:
        return Icons.school_outlined;
      case _UserRoleFilter.student:
        return Icons.person_outline_rounded;
      case _UserRoleFilter.pending:
        return Icons.person_add_alt_1_outlined;
      case _UserRoleFilter.all:
        return Icons.people_alt_outlined;
    }
  }

  List<UserModel> _applyFilter(List<UserModel> users) {
    return users.where((user) {
      final needle = _query.trim().toLowerCase();
      final matchesSearch =
          needle.isEmpty ||
          user.name.toLowerCase().contains(needle) ||
          user.email.toLowerCase().contains(needle) ||
          user.school.toLowerCase().contains(needle);
      if (!matchesSearch) return false;

      switch (_filter) {
        case _UserRoleFilter.admin:
          return user.role == 'admin';
        case _UserRoleFilter.teacher:
          return user.role == 'teacher';
        case _UserRoleFilter.student:
          return user.role == 'student';
        case _UserRoleFilter.pending:
          return user.role.isEmpty;
        case _UserRoleFilter.all:
          return true;
      }
    }).toList();
  }

  int _countFor(List<UserModel> users, _UserRoleFilter filter) {
    return users.where((user) {
      switch (filter) {
        case _UserRoleFilter.admin:
          return user.role == 'admin';
        case _UserRoleFilter.teacher:
          return user.role == 'teacher';
        case _UserRoleFilter.student:
          return user.role == 'student';
        case _UserRoleFilter.pending:
          return user.role.isEmpty;
        case _UserRoleFilter.all:
          return true;
      }
    }).length;
  }

  Future<void> _changeRole(UserModel user, String newRole) async {
    if (newRole == user.role) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('change_role')),
        content: Text('${tr('change_role')}: ${user.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(tr('no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(tr('yes')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(adminRepositoryProvider).updateUserRole(user.uid, newRole);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${tr('save')} OK'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(allUsersProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: usersAsync.when(
        data: (users) {
          if (users.isEmpty) {
            return Center(child: Text(tr('no_users')));
          }

          final filteredUsers = _applyFilter(users);

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            children: [
              Text(
                tr('manage_users'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('manage_users_filter_hint'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(context),
                ),
              ),
              const SizedBox(height: 16),
              _UserSearchField(
                controller: _searchController,
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 14),
              _RoleFilterBar(
                selected: _filter,
                countFor: (filter) => _countFor(users, filter),
                labelFor: _filterLabel,
                iconFor: _filterIcon,
                onSelected: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 18),
              if (filteredUsers.isEmpty)
                _EmptyFilteredUsers(label: _filterLabel(_filter))
              else
                ...filteredUsers.map(
                  (user) => _UserCard(
                    user: user,
                    roleLabel: _roleLabel(user.role),
                    roleItems: _roles
                        .map(
                          (role) => DropdownMenuItem<String>(
                            value: role,
                            child: Text(_roleLabel(role)),
                          ),
                        )
                        .toList(),
                    onRoleChanged: (newRole) {
                      if (newRole != null) _changeRole(user, newRole);
                    },
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(tr('error_occurred'))),
      ),
    );
  }
}

class _RoleFilterBar extends StatelessWidget {
  const _RoleFilterBar({
    required this.selected,
    required this.countFor,
    required this.labelFor,
    required this.iconFor,
    required this.onSelected,
  });

  final _UserRoleFilter selected;
  final int Function(_UserRoleFilter filter) countFor;
  final String Function(_UserRoleFilter filter) labelFor;
  final IconData Function(_UserRoleFilter filter) iconFor;
  final ValueChanged<_UserRoleFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _UserRoleFilter.values.map((filter) {
          final isSelected = filter == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              avatar: Icon(
                iconFor(filter),
                size: 18,
                color: isSelected ? Colors.white : AppTheme.mutedText(context),
              ),
              label: Text('${labelFor(filter)} (${countFor(filter)})'),
              selectedColor: Theme.of(context).colorScheme.primary,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : AppTheme.primaryText(context),
                fontWeight: FontWeight.w700,
              ),
              side: BorderSide(color: AppTheme.borderColor(context)),
              onSelected: (_) => onSelected(filter),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _UserSearchField extends StatelessWidget {
  const _UserSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: tr('search_users'),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: tr('delete'),
                icon: const Icon(Icons.close),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.roleLabel,
    required this.roleItems,
    required this.onRoleChanged,
  });

  final UserModel user;
  final String roleLabel;
  final List<DropdownMenuItem<String>> roleItems;
  final ValueChanged<String?> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    final roleValue = user.role.isEmpty ? null : user.role;
    final isPending = user.role.isEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPending
              ? const Color(0xFFF59E0B)
              : AppTheme.borderColor(context),
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isPending
                ? const Color(0xFFFFF7ED)
                : const Color(0xFFEFF6FF),
            foregroundColor: isPending
                ? const Color(0xFFEA580C)
                : const Color(0xFF00288E),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 4),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppTheme.mutedText(context)),
                ),
                const SizedBox(height: 6),
                Text(
                  roleLabel,
                  style: TextStyle(
                    color: isPending
                        ? const Color(0xFFEA580C)
                        : AppTheme.mutedText(context),
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          DropdownButton<String>(
            value: roleValue,
            hint: Text(tr('set_role')),
            items: roleItems,
            onChanged: onRoleChanged,
          ),
        ],
      ),
    );
  }
}

class _EmptyFilteredUsers extends StatelessWidget {
  const _EmptyFilteredUsers({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Text('${tr('no_users')} - $label'),
    );
  }
}
