// test/widget_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiledger_app/presentation/screens/splash_screen.dart';
import 'package:mobiledger_app/presentation/screens/language_screen.dart';

void main() {
  group('Widget Tests - UI Rendering', () {
    testWidgets('Splash screen displays correctly', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: SplashScreen(),
      ));
      
      // Just pump once without waiting for timer
      await tester.pump();
      
      // Check for main elements
      expect(find.text('ML'), findsOneWidget);
      expect(find.text('MobiLedger'), findsOneWidget);
      expect(find.textContaining('Track. Learn. Grow'), findsOneWidget);
    });

    testWidgets('Language screen displays English and Kinyarwanda options', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: LanguageScreen(),
      ));
      
      await tester.pump();
      
      expect(find.text('ENGLISH'), findsOneWidget);
      expect(find.text('KINYARWANDA'), findsOneWidget);
      expect(find.text('MobiLedger'), findsOneWidget);
    });

    testWidgets('Language screen shows selection prompt', (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: LanguageScreen(),
      ));
      
      await tester.pump();
      
      // Look for the text with partial match
      expect(find.textContaining('Choose a language'), findsOneWidget);
    });
  });
}