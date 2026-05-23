import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketplan/shared/widgets/tappable.dart';

void main() {
  group('Tappable', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: Tappable(child: Text('Hello')))),
      );
      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Tappable(
              onTap: () => tapped = true,
              child: const Text('Tap me'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Tap me'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Tappable(
              onLongPress: () => longPressed = true,
              child: const Text('Hold me'),
            ),
          ),
        ),
      );
      await tester.longPress(find.text('Hold me'));
      await tester.pumpAndSettle();
      expect(longPressed, isTrue);
    });

    testWidgets('renders child directly when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Tappable(child: Text('Disabled'))),
        ),
      );
      // Should render without GestureDetector/InkWell wrapper
      expect(find.text('Disabled'), findsOneWidget);
    });
  });
}
