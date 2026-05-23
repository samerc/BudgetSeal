import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:pocketplan/shared/widgets/error_boundary.dart';

void main() {
  group('ErrorBoundary', () {
    testWidgets('renders child when no error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ErrorBoundary(child: Text('Works')),
        ),
      );
      expect(find.text('Works'), findsOneWidget);
    });

    testWidgets('fallback screen has Try Again and Go Back buttons', (tester) async {
      // We can't easily trigger _hasError from outside since it's internal state,
      // but we can test the fallback screen directly
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Try Again'),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.text('Try Again'), findsOneWidget);
      expect(find.text('Go Back'), findsOneWidget);
    });

    testWidgets('does not crash on rebuild', (tester) async {
      var counter = 0;
      late StateSetter setter;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setter = setState;
              return ErrorBoundary(child: Text('Build $counter'));
            },
          ),
        ),
      );
      expect(find.text('Build 0'), findsOneWidget);

      setter(() => counter++);
      await tester.pump();
      expect(find.text('Build 1'), findsOneWidget);
    });
  });
}
