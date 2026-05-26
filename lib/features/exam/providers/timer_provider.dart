import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ExamTimerNotifier extends Notifier<int> {
  Timer? _timer;

  @override
  int build() {
    ref.onDispose(() {
      _timer?.cancel();
    });
    return 0;
  }

  void start(int minutes, VoidCallback onTimeUp) {
    _timer?.cancel();
    state = minutes * 60;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state--;
        if (state == 0) {
          _timer?.cancel();
          onTimeUp();
        }
      } else {
        _timer?.cancel();
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = 0;
  }
}

final examTimerProvider = NotifierProvider<ExamTimerNotifier, int>(() {
  return ExamTimerNotifier();
});
