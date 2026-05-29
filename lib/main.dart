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
import 'features/auth/providers/auth_provider.dart';
import 'shared/models/alert_model.dart';

const _oneSignalAppId = '51778ec8-c5ff-4661-85f9-cca8f1b5b105';
final Set<String> _oneSignalSyncedUsers = <String>{};
final Set<String> _unreadPushSyncedUsers = <String>{};
final Set<String> _pushedAlertIds = <String>{};
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
      unawaited(_syncOneSignalSession(ref, authUser.uid));
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
      final user = next.value;
      if (user == null) {
        _activeOneSignalUid = null;
        _oneSignalSyncedUsers.clear();
        _unreadPushSyncedUsers.clear();
        _pushedAlertIds.clear();
        unawaited(OneSignal.logout());
        return;
      }
      unawaited(_syncOneSignalSession(ref, user.uid));
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

Future<void> _syncOneSignalSession(WidgetRef ref, String uid) async {
  try {
    if (_activeOneSignalUid != null && _activeOneSignalUid != uid) {
      await OneSignal.logout();
      _oneSignalSyncedUsers.remove(uid);
      _unreadPushSyncedUsers.remove(uid);
    }
    _activeOneSignalUid = uid;

    if (_oneSignalSyncedUsers.add(uid)) {
      await OneSignal.Notifications.requestPermission(true);
      await OneSignal.User.pushSubscription.optIn();
      await OneSignal.login(uid);
      await _persistOneSignalSubscription(ref, uid);
    }
    if (!_unreadPushSyncedUsers.add(uid)) return;
    await ref.read(alertRepositoryProvider).pushUnreadAlerts(uid);
  } catch (error, stackTrace) {
    debugPrint('OneSignal session sync failed: $error\n$stackTrace');
  }
}

Future<void> _persistOneSignalSubscription(WidgetRef ref, String uid) async {
  for (final delay in const [
    Duration(milliseconds: 700),
    Duration(seconds: 2),
    Duration(seconds: 5),
  ]) {
    await Future<void>.delayed(delay);
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
