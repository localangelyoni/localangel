import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/pages/onboarding_flow.dart';
import 'presentation/pages/verification_waiting_page.dart';
import 'presentation/pages/home/home_page.dart';
import 'presentation/pages/create_ping_page.dart';
import 'presentation/pages/community_alerts_page.dart';
import 'presentation/pages/my_chats_page.dart';
import 'presentation/pages/chat_detail_page.dart';
import 'presentation/pages/settings_page.dart';
import 'presentation/pages/my_support_requests_page.dart';
import 'presentation/pages/awards/awards_page.dart';
import 'presentation/pages/leaderboard/leaderboard_page.dart';
import 'presentation/pages/terms_of_use_page.dart';
import 'presentation/pages/privacy_policy_page.dart';
import 'presentation/pages/accessibility_settings_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:localangel/firebase_options.dart';
// import kept via AppLocalizations.localizationsDelegates
import 'package:localangel/application/locale/locale_cubit.dart';
import 'package:localangel/l10n/app_localizations.dart';
import 'auth/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
    // Continue anyway - some features might not work but app should still run
  }
  runApp(const ProviderScope(child: MainApp()));
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final LocaleCubit _localeCubit = LocaleCubit();

  @override
  void initState() {
    super.initState();
    _localeCubit.init();
    _localeCubit.addListener(_onLocaleChanged);
  }

  void _onLocaleChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _localeCubit.removeListener(_onLocaleChanged);
    _localeCubit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Enforce Hebrew-only and RTL throughout the app
    const locale = Locale('he');
    const textDirection = TextDirection.rtl;
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorSchemeSeed: const Color(0xFF7C3AED),
        fontFamily: 'Roboto',
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            foregroundColor: Colors.white,
            backgroundColor: const Color(0xFF1F1F23),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(56),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            side: const BorderSide(color: Color(0xFF1F1F23), width: 1.2),
          ),
        ),
      ),
      home: Directionality(
        textDirection: textDirection,
        child: const _AuthGate(),
      ),
      routes: {
        '/verification': (_) => Directionality(
          textDirection: textDirection,
          child: const VerificationWaitingPage(),
        ),
        '/dashboard': (_) => Directionality(
          textDirection: textDirection,
          child: const HomePage(),
        ),
        '/create_ping': (_) => Directionality(
          textDirection: textDirection,
          child: const CreatePingPage(),
        ),
        // placeholder for community alerts route
        '/community_alerts': (_) => Directionality(
          textDirection: textDirection,
          child: const CommunityAlertsPage(),
        ),
        '/my_chats': (_) => Directionality(
          textDirection: textDirection,
          child: const MyChatsPage(),
        ),
        '/chat_detail': (ctx) {
          final args = ModalRoute.of(ctx)?.settings.arguments;
          return Directionality(
            textDirection: textDirection,
            child: ChatDetailPage(chatId: args is String ? args : null),
          );
        },
        '/settings': (_) => Directionality(
          textDirection: textDirection,
          child: const SettingsPage(),
        ),
        '/my_support_requests': (_) => Directionality(
          textDirection: textDirection,
          child: const MySupportRequestsPage(),
        ),
        '/awards': (_) => Directionality(
          textDirection: textDirection,
          child: const AwardsPage(),
        ),
        '/leaderboard': (_) => Directionality(
          textDirection: textDirection,
          child: const LeaderboardPage(),
        ),
        '/terms_of_use': (_) => Directionality(
          textDirection: textDirection,
          child: const TermsOfUsePage(),
        ),
        '/privacy_policy': (_) => Directionality(
          textDirection: textDirection,
          child: const PrivacyPolicyPage(),
        ),
        '/accessibility_settings': (_) => Directionality(
          textDirection: textDirection,
          child: const AccessibilitySettingsPage(),
        ),
      },
    );
  }
}

class _AuthGate extends ConsumerWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen directly to Firebase Auth stream - this is the single source of truth
    final authState = ref.watch(authUserStreamProvider);

    return authState.when(
      data: (user) {
        // User is null = unauthenticated
        if (user == null) {
          return const OnboardingFlow();
        }

        // User is authenticated - go to home
        return const HomePage();
      },
      loading: () {
        // Show a simple loading screen while checking auth state
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
      error: (error, stack) {
        // Fallback UI in case of errors
        debugPrint('AuthGate error: $error');
        return Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'שגיאה בטעינת האפליקציה',
                  style: TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  '$error',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    // Try to reload
                    ref.invalidate(authUserStreamProvider);
                  },
                  child: const Text('נסה שוב'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
