import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neznakomets/app/router.dart';
import 'package:neznakomets/app/theme.dart';
import 'package:neznakomets/features/onboarding/onboarding_screen.dart';
import 'package:neznakomets/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  final prefs = await SharedPreferences.getInstance();
  final onboardingComplete =
      prefs.getBool(OnboardingScreen.onboardingCompleteKey) ?? false;
  final initialLocation = onboardingComplete ? '/' : '/onboarding';

  runApp(
    ProviderScope(
      overrides: [
        appInitialLocationProvider.overrideWith((ref) => initialLocation),
      ],
      child: const NeznakometsApp(),
    ),
  );
}

class NeznakometsApp extends ConsumerWidget {
  const NeznakometsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    return MaterialApp.router(
      title: 'Незнакомец',
      debugShowCheckedModeBanner: false,
      theme: NeznakometsTheme.dark,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
