import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:localangel/presentation/pages/welcome_page.dart';

void main() {
  testWidgets('Welcome flow advances slides and reaches login', (tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: MaterialApp(home: WelcomePage()),
      ),
    );

    expect(find.text('התחל/י את המסע'), findsOneWidget);
    await tester.tap(find.text('התחל/י את המסע'));
    await tester.pumpAndSettle();

    expect(find.text('הבא'), findsOneWidget);
    await tester.tap(find.text('הבא'));
    await tester.pumpAndSettle();

    expect(find.text('הבא'), findsOneWidget);
    await tester.tap(find.text('הבא'));
    await tester.pumpAndSettle();

    expect(find.text('בואו נתחיל'), findsOneWidget);
    await tester.tap(find.text('בואו נתחיל'));
    await tester.pumpAndSettle();

    expect(find.text('התחברות'), findsOneWidget);
  });
}




