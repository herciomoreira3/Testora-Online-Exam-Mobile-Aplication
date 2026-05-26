import 'package:easy_localization/easy_localization.dart';

class Formatters {
  static String formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes > 0) {
      return '$minutes ${tr('minutes')} $remainingSeconds ${tr('seconds')}';
    }
    return '$remainingSeconds ${tr('seconds')}';
  }
}
