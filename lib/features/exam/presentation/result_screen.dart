import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../shared/models/result_model.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../core/themes/app_theme.dart';

class ResultScreen extends StatelessWidget {
  final ResultModel result;

  const ResultScreen({super.key, required this.result});

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes ${tr('minutes')} $remainingSeconds ${tr('seconds')}';
    }
    return '$remainingSeconds ${tr('seconds')}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPassed = result.percentage >= 60.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('exam_result_title')),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Celebratory Header card
              Card(
                elevation: 4,
                shadowColor:
                    (isPassed ? AppTheme.successColor : AppTheme.errorColor)
                        .withValues(alpha: 0.15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 36.0,
                    horizontal: 20.0,
                  ),
                  child: Column(
                    children: [
                      // Status Icon
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color:
                              (isPassed
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor)
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPassed
                              ? Icons.emoji_events_rounded
                              : Icons.info_outline_rounded,
                          size: 72,
                          color: isPassed
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        isPassed ? 'Parabéns!' : 'Koko Fali!',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 28,
                          color: isPassed
                              ? AppTheme.successColor
                              : AppTheme.errorColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        result.examTitle,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 28),

                      // Score circle badge
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            height: 140,
                            width: 140,
                            child: CircularProgressIndicator(
                              value: result.percentage / 100.0,
                              strokeWidth: 10,
                              backgroundColor: const Color(0xFFE2E8F0),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isPassed
                                    ? AppTheme.successColor
                                    : AppTheme.errorColor,
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                '${result.percentage.toStringAsFixed(0)}%',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontSize: 32,
                                  color: isPassed
                                      ? AppTheme.successColor
                                      : AppTheme.errorColor,
                                ),
                              ),
                              Text(
                                '${tr('score')}: ${result.score}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Detail card listing facts
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        context,
                        icon: Icons.timer_outlined,
                        label: 'Tempu uza:',
                        value: _formatDuration(result.timeTaken),
                      ),
                      const Divider(height: 24),
                      _buildDetailRow(
                        context,
                        icon: Icons.calendar_month_outlined,
                        label: 'Data entrega:',
                        value: DateFormat(
                          'dd/MM/yyyy HH:mm',
                        ).format(result.submittedAt),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Back home action button
              CustomButton(
                text: 'Fila fali ba Varanda',
                onPressed: () => context.go('/home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
            fontSize: 15,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
