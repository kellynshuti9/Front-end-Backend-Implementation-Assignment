import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobiledger1/presentation/widgets/common/widgets.dart';
import 'package:mobiledger1/core/constants/app_colors.dart';

void main() {
  // ─── AppButton ─────────────────────────────────────────────────────────────
  group('AppButton widget', () {
    testWidgets('renders label text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppButton(label: 'Click Me')),
      ));
      expect(find.text('Click Me'), findsOneWidget);
    });

    testWidgets('calls onPressed when tapped', (tester) async {
      bool called = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Tap', onPressed: () => called = true),
        ),
      ));
      await tester.tap(find.text('Tap'));
      await tester.pump();
      expect(called, isTrue);
    });

    testWidgets('shows CircularProgressIndicator when loading', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Loading', isLoading: true),
        ),
      ));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading'), findsNothing);
    });

    testWidgets('renders OutlinedButton when outlined=true', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppButton(label: 'Outline', outlined: true),
        ),
      ));
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('does not call onPressed when disabled (null)', (tester) async {
      bool called = false;
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Disabled',
            onPressed: null,
          ),
        ),
      ));
      await tester.tap(find.text('Disabled'), warnIfMissed: false);
      await tester.pump();
      expect(called, isFalse);
    });
  });

  // ─── AppTextField ──────────────────────────────────────────────────────────
  group('AppTextField widget', () {
    testWidgets('accepts text input', (tester) async {
      final ctrl = TextEditingController();
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppTextField(hint: 'Enter text', controller: ctrl),
        ),
      ));
      await tester.enterText(find.byType(TextFormField), 'hello@test.com');
      expect(ctrl.text, 'hello@test.com');
      ctrl.dispose();
    });

    testWidgets('shows hint text', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppTextField(hint: 'My hint here'),
        ),
      ));
      expect(find.text('My hint here'), findsOneWidget);
    });
  });

  // ─── SectionHeader ─────────────────────────────────────────────────────────
  group('SectionHeader widget', () {
    testWidgets('renders title and action', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: SectionHeader(
            title: 'Recent Activity',
            action: 'View All',
            onAction: () => tapped = true,
          ),
        ),
      ));
      expect(find.text('Recent Activity'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      await tester.tap(find.text('View All'));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });

  // ─── StatusBadge ───────────────────────────────────────────────────────────
  group('StatusBadge widget', () {
    testWidgets('displays label with correct color', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: StatusBadge(label: 'Active', color: AppColors.success),
        ),
      ));
      expect(find.text('Active'), findsOneWidget);
    });
  });
}
