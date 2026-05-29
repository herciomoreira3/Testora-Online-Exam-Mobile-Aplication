import 'package:flutter_riverpod/flutter_riverpod.dart';

class DarkModeOverrideNotifier extends Notifier<bool?> {
  @override
  bool? build() => null;

  void setValue(bool value) {
    state = value;
  }

  void clear() {
    state = null;
  }
}

final darkModeOverrideProvider =
    NotifierProvider<DarkModeOverrideNotifier, bool?>(() {
      return DarkModeOverrideNotifier();
    });

class SelectedSubjectOverrideNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setValue(String value) {
    state = value;
  }

  void clear() {
    state = null;
  }
}

final selectedSubjectOverrideProvider =
    NotifierProvider<SelectedSubjectOverrideNotifier, String?>(() {
      return SelectedSubjectOverrideNotifier();
    });
