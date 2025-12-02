import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localangel/presentation/pages/onboarding_flow.dart';
import 'package:localangel/l10n/app_localizations.dart';

void main() {
  testWidgets('Onboarding flow shows welcome step initially', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('he'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: OnboardingFlow(),
        ),
      ),
    );

    // Should start at welcome step
    expect(find.text('התחל/י את המסע'), findsOneWidget);
    
    // Tap to start journey
    await tester.tap(find.text('התחל/י את המסע'));
    await tester.pumpAndSettle();

    // Should now be on slides step (verify by checking for slide content)
    expect(find.text('הבא'), findsOneWidget);
  });

  testWidgets('Onboarding flow back button works correctly', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('he'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: OnboardingFlow(),
        ),
      ),
    );

    // Start journey
    await tester.tap(find.text('התחל/י את המסע'));
    await tester.pumpAndSettle();

    // Should be on slides now
    expect(find.text('הבא'), findsOneWidget);

    // Tap back button
    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    // Should be back at welcome step
    expect(find.text('התחל/י את המסע'), findsOneWidget);
  });
}

