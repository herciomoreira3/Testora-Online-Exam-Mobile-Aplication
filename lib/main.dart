import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'firebase_options.dart';
import 'core/routes/app_router.dart';
import 'core/themes/app_theme.dart';
import 'features/auth/providers/auth_provider.dart';

const _oneSignalAppId = '51778ec8-c5ff-4661-85f9-cca8f1b5b105';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
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
    ref.listen(authStateProvider, (previous, next) {
      final user = next.value;
      if (user == null) {
        unawaited(OneSignal.logout());
        return;
      }
      unawaited(OneSignal.login(user.uid));
    });

    // Translation locale from EasyLocalization (used for app strings)
    final Locale translationLocale = context.locale;
    // Pick a Flutter-supported locale for Material/Cupertino delegates.
    // Flutter does not include Tetun; map Tetun to English for framework widgets.
    final Locale flutterLocale = (translationLocale.languageCode == 'tet')
        ? const Locale('en', 'US')
        : translationLocale;

    return MaterialApp.router(
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
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
