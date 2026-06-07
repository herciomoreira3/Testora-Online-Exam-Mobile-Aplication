import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'core/providers/app_preferences_provider.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'features/alerts/providers/alert_provider.dart';
import 'features/admin/presentation/admin_dashboard_screen.dart';
import 'features/admin/presentation/admin_reports_screen.dart';
import 'features/admin/providers/admin_provider.dart';
import 'features/auth/providers/auth_provider.dart';
import 'features/exam/presentation/list_exam_screen.dart';
import 'features/exam/providers/exam_provider.dart';
import 'features/history/presentation/history_screen.dart';
import 'features/professor/providers/professor_exam_provider.dart';
import 'shared/models/alert_model.dart';

const _oneSignalAppId = '51778ec8-c5ff-4661-85f9-cca8f1b5b105';
final Set<String> _oneSignalSyncedUsers = <String>{};
final Set<String> _unreadPushSyncedUsers = <String>{};
final Set<String> _unreadPushInFlightUsers = <String>{};
final Set<String> _pushedAlertIds = <String>{};
Future<void> _oneSignalSessionQueue = Future<void>.value();
int _oneSignalSessionEpoch = 0;
String? _activeOneSignalUid;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  await OneSignal.initialize(_oneSignalAppId);
  unawaited(OneSignal.Notifications.requestPermission(true));

  runApp(
    ProviderScope(
      child: EasyLocalization(
        supportedLocales: const [Locale('tet', 'TL'), Locale('en', 'US')],
        path: 'assets/lang',
        fallbackLocale: const Locale('tet', 'TL'),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final darkModeOverride = ref.watch(darkModeOverrideProvider);
    final darkMode = darkModeOverride ?? profileAsync.value?.darkMode ?? false;
    final authUser = ref.watch(authStateProvider).value;
    if (authUser != null) {
      unawaited(
        _syncOneSignalSession(ref, authUser.uid, pushUnreadAlerts: true),
      );
    }
    ref.listen(myAlertsProvider, (previous, next) {
      final uid = ref.read(authStateProvider).value?.uid;
      if (uid == null) return;
      final alerts = next.value ?? const [];
      for (final alert in alerts) {
        if (alert.isReadBy(uid)) continue;
        if (!_pushedAlertIds.add('${uid}_${alert.id}')) continue;
        unawaited(_pushAlertSafely(ref, uid, alert));
      }
    });
    ref.listen(authStateProvider, (previous, next) {
      final previousUid = previous?.value?.uid;
      final user = next.value;
      if (user == null) {
        _resetSessionScopedProviders(ref);
        _activeOneSignalUid = null;
        _oneSignalSyncedUsers.clear();
        _unreadPushSyncedUsers.clear();
        _unreadPushInFlightUsers.clear();
        _pushedAlertIds.clear();
        unawaited(_logoutOneSignalSession());
        return;
      }
      if (previousUid != null && previousUid != user.uid) {
        _resetSessionScopedProviders(ref);
        _oneSignalSyncedUsers.remove(previousUid);
        _unreadPushSyncedUsers.remove(previousUid);
        _unreadPushInFlightUsers.remove(previousUid);
        _pushedAlertIds.removeWhere((id) => id.startsWith('${previousUid}_'));
      }
      unawaited(_syncOneSignalSession(ref, user.uid, pushUnreadAlerts: true));
    });
    ref.listen(userProfileProvider, (previous, next) {
      final previousUser = previous?.value;
      final nextUser = next.value;
      if (nextUser == null) return;
      if (previousUser?.uid == nextUser.uid) return;
      ref.read(darkModeOverrideProvider.notifier).clear();
      ref.read(selectedSubjectOverrideProvider.notifier).clear();

      final language = nextUser.language;
      if (language.isEmpty) return;
      final targetLocale = language == 'en'
          ? const Locale('en', 'US')
          : const Locale('tet', 'TL');
      if (context.locale.languageCode != targetLocale.languageCode) {
        unawaited(context.setLocale(targetLocale));
      }
    });

    // Translation locale from EasyLocalization (used for app strings)
    final Locale translationLocale = context.locale;
    // Pick a Flutter-supported locale for Material/Cupertino delegates.
    // Flutter does not include Tetun; map Tetun to English for framework widgets.
    final Locale flutterLocale = (translationLocale.languageCode == 'tet')
        ? const Locale('en', 'US')
        : translationLocale;

    return MaterialApp.router(
      key: ValueKey(translationLocale.toLanguageTag()),
      localizationsDelegates: [
        ...context.localizationDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: context.supportedLocales,
      locale: flutterLocale,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;
        // If the exact locale is supported return it, otherwise fallback to English
        for (final supported in supportedLocales) {
          if (supported.languageCode == locale.languageCode) return supported;
        }
        return const Locale('en', 'US');
      },
      title: 'Testora',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

void _resetSessionScopedProviders(WidgetRef ref) {
  ref.read(darkModeOverrideProvider.notifier).clear();
  ref.read(selectedSubjectOverrideProvider.notifier).clear();
  ref.invalidate(userProfileProvider);
  ref.invalidate(allUsersProvider);
  ref.invalidate(subjectsProvider);
  ref.invalidate(teacherSubjectsProvider);
  ref.invalidate(studentSubjectsProvider);
  ref.invalidate(allExamsProvider);
  ref.invalidate(activeExamsProvider);
  ref.invalidate(publishedExamsProvider);
  ref.invalidate(studentDashboardResultsProvider);
  ref.invalidate(studentResultsProvider);
  ref.invalidate(adminResultsProvider);
  ref.invalidate(adminAllResultsProvider);
  ref.invalidate(myAlertsProvider);
}

Future<void> _queueOneSignalSession(Future<void> Function() action) {
  final next = _oneSignalSessionQueue.then((_) => action());
  _oneSignalSessionQueue = next.catchError((Object error, StackTrace stack) {
    debugPrint('OneSignal queued action failed: $error\n$stack');
  });
  return next;
}

Future<void> _logoutOneSignalSession() {
  return _queueOneSignalSession(() async {
    try {
      _oneSignalSessionEpoch++;
      await OneSignal.logout();
    } catch (error, stackTrace) {
      debugPrint('OneSignal logout failed: $error\n$stackTrace');
    }
  });
}

Future<void> _syncOneSignalSession(
  WidgetRef ref,
  String uid, {
  bool pushUnreadAlerts = false,
}) async {
  return _queueOneSignalSession(() async {
    try {
      if (ref.read(authStateProvider).value?.uid != uid) return;

      if (_activeOneSignalUid != null && _activeOneSignalUid != uid) {
        final previousUid = _activeOneSignalUid!;
        _oneSignalSessionEpoch++;
        await OneSignal.logout();
        _oneSignalSyncedUsers.remove(previousUid);
        _unreadPushSyncedUsers.remove(previousUid);
        _unreadPushInFlightUsers.remove(previousUid);
        _pushedAlertIds.removeWhere((id) => id.startsWith('${previousUid}_'));
      }
      _activeOneSignalUid = uid;

      if (_oneSignalSyncedUsers.add(uid)) {
        await OneSignal.Notifications.requestPermission(true);
        await OneSignal.User.pushSubscription.optIn();
        await OneSignal.login(uid);
        await _ensureOneSignalExternalId(uid);
        final epoch = ++_oneSignalSessionEpoch;
        unawaited(_persistOneSignalSubscription(ref, uid, epoch));
      }
      if (ref.read(authStateProvider).value?.uid != uid) return;

      final shouldPushUnread =
          pushUnreadAlerts &&
          !_unreadPushSyncedUsers.contains(uid) &&
          _unreadPushInFlightUsers.add(uid);
      if (!shouldPushUnread) return;
      try {
        final subscriptionId = await _currentOneSignalSubscriptionId(uid);
        await ref
            .read(alertRepositoryProvider)
            .pushUnreadAlerts(
              uid,
              onQueued: (alert) => _pushedAlertIds.add('${uid}_${alert.id}'),
              subscriptionId: subscriptionId,
            );
        _unreadPushSyncedUsers.add(uid);
      } finally {
        _unreadPushInFlightUsers.remove(uid);
      }
    } catch (error, stackTrace) {
      debugPrint('OneSignal session sync failed: $error\n$stackTrace');
    }
  });
}

Future<void> _ensureOneSignalExternalId(String uid) async {
  try {
    await OneSignal.User.addAlias('external_id', uid);
  } catch (error, stackTrace) {
    debugPrint('OneSignal external_id alias failed: $error\n$stackTrace');
  }

  for (final delay in const [
    Duration.zero,
    Duration(milliseconds: 300),
    Duration(milliseconds: 700),
    Duration(milliseconds: 1200),
    Duration(seconds: 2),
  ]) {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (_activeOneSignalUid != uid) return;
    try {
      final externalId = await OneSignal.User.getExternalId();
      if (externalId == uid) return;
    } catch (error, stackTrace) {
      debugPrint('OneSignal external_id read failed: $error\n$stackTrace');
      return;
    }
  }
}

Future<String?> _currentOneSignalSubscriptionId(String uid) async {
  for (final delay in const [
    Duration.zero,
    Duration(milliseconds: 350),
    Duration(milliseconds: 800),
    Duration(milliseconds: 1400),
  ]) {
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (_activeOneSignalUid != uid) return null;
    final subscriptionId = OneSignal.User.pushSubscription.id;
    if (subscriptionId != null && subscriptionId.isNotEmpty) {
      return subscriptionId;
    }
  }
  return null;
}

Future<void> _persistOneSignalSubscription(
  WidgetRef ref,
  String uid,
  int epoch,
) async {
  for (final delay in const [
    Duration(milliseconds: 700),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ]) {
    await Future<void>.delayed(delay);
    if (_activeOneSignalUid != uid || _oneSignalSessionEpoch != epoch) {
      return;
    }
    try {
      await ref
          .read(authRepositoryProvider)
          .updateOneSignalSubscription(
            uid: uid,
            subscriptionId: OneSignal.User.pushSubscription.id,
            token: OneSignal.User.pushSubscription.token,
            optedIn: OneSignal.User.pushSubscription.optedIn,
          );
    } catch (error, stackTrace) {
      debugPrint('OneSignal subscription persist failed: $error\n$stackTrace');
    }
    if ((OneSignal.User.pushSubscription.id ?? '').isNotEmpty) return;
  }
}

Future<void> _pushAlertSafely(
  WidgetRef ref,
  String uid,
  AlertModel alert,
) async {
  try {
    await ref.read(alertRepositoryProvider).pushSingleAlert(uid, alert);
  } catch (_) {
    // Firestore alert remains visible even if push delivery fails.
  }
}
