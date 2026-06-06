import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/themes/app_theme.dart';
import '../../../shared/models/alert_model.dart';
import '../../auth/providers/auth_provider.dart';
import '../providers/alert_provider.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(myAlertsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      body: alertsAsync.when(
        data: (alerts) {
          final uid = ref.read(authRepositoryProvider).currentUid;
          if (uid != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(alertRepositoryProvider).markAlertsRead(uid, alerts);
            });
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
            children: [
              Text(
                tr('alerts'),
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: AppTheme.primaryText(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                tr('alerts_hint'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedText(context),
                ),
              ),
              const SizedBox(height: 18),
              if (alerts.isEmpty)
                _EmptyAlerts(message: tr('no_alerts'))
              else
                ...alerts.map((alert) => _AlertCard(alert: alert)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            Center(child: Text('${tr('error_occurred')}: $error')),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert});

  final AlertModel alert;

  @override
  Widget build(BuildContext context) {
    final accent = _accentColor(alert.type);
    final title = _title();
    final message = _message();
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor(context)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x100F172A),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_icon(alert.type), color: accent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.primaryText(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _TypePill(type: alert.type, color: accent),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.primaryText(context),
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (alert.subjectId.isNotEmpty)
                      _MetaPill(
                        icon: Icons.menu_book_outlined,
                        label: alert.subject.isEmpty
                            ? tr('subject')
                            : alert.subject,
                      ),
                    _MetaPill(
                      icon: Icons.schedule_outlined,
                      label: DateFormat(
                        'dd/MM/yyyy HH:mm',
                      ).format(alert.scheduledAt),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentColor(String type) {
    return switch (type) {
      'exam_sent_for_publish' => const Color(0xFFF59E0B),
      'exam_published' => const Color(0xFF10B981),
      'exam_started' => AppTheme.primaryColor,
      'exam_reminder' => const Color(0xFF2563EB),
      _ => AppTheme.primaryColor,
    };
  }

  IconData _icon(String type) {
    return switch (type) {
      'exam_sent_for_publish' => Icons.outbox_outlined,
      'exam_published' => Icons.campaign_outlined,
      'exam_started' => Icons.play_circle_outline,
      'exam_reminder' => Icons.alarm_outlined,
      _ => Icons.notifications_active_outlined,
    };
  }

  String _title() {
    if (alert.titleKey.isNotEmpty) return tr(alert.titleKey);
    if (alert.type == 'exam_sent_for_publish') {
      return tr('alert_exam_sent_publish_title');
    }
    if (alert.type == 'exam_published') return tr('alert_exam_published_title');
    if (alert.type == 'exam_reminder') return tr('alert_exam_reminder_title');
    if (alert.type == 'exam_started') return tr('alert_exam_started_title');
    return alert.title;
  }

  String _message() {
    if (alert.messageKey.isNotEmpty) {
      return tr(alert.messageKey, args: alert.messageArgs);
    }
    if (alert.type == 'exam_sent_for_publish') {
      return tr(
        'alert_exam_sent_publish_message',
        args: [alert.examTitle, alert.subject],
      );
    }
    return alert.message;
  }
}

class _TypePill extends StatelessWidget {
  const _TypePill({required this.type, required this.color});

  final String type;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(type),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }

  String _label(String type) {
    return switch (type) {
      'exam_sent_for_publish' => tr('pending_publish'),
      'exam_published' => tr('published'),
      'exam_started' => tr('active'),
      'exam_reminder' => tr('notification_before_exam'),
      _ => tr('alerts'),
    };
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.subtleBackground(context),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppTheme.mutedText(context)),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedText(context),
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyAlerts extends StatelessWidget {
  const _EmptyAlerts({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTheme.cardBackground(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor(context)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.notifications_none_outlined,
            color: AppTheme.mutedText(context),
          ),
          const SizedBox(height: 10),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: AppTheme.mutedText(context)),
          ),
        ],
      ),
    );
  }
}
