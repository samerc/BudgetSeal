import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:budgetseal/shared/widgets/faded_edges.dart';

void main() {
  group('FadedEdges', () {
    testWidgets('renders child when no fades set', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadedEdges(
              topFade: 0,
              bottomFade: 0,
              child: Text('Content'),
            ),
          ),
        ),
      );
      expect(find.text('Content'), findsOneWidget);
      // No ShaderMask when all fades are 0
      expect(find.byType(ShaderMask), findsNothing);
    });

    testWidgets('applies ShaderMask when bottomFade > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadedEdges(
              bottomFade: 24,
              child: SizedBox(height: 200, child: Text('Content')),
            ),
          ),
        ),
      );
      expect(find.text('Content'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('applies ShaderMask when topFade > 0', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadedEdges(
              topFade: 16,
              bottomFade: 0,
              child: SizedBox(height: 200, child: Text('Content')),
            ),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsOneWidget);
    });

    testWidgets('applies ShaderMask for horizontal fades', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FadedEdges(
              startFade: 12,
              endFade: 12,
              child: SizedBox(width: 300, child: Text('Horizontal')),
            ),
          ),
        ),
      );
      expect(find.byType(ShaderMask), findsOneWidget);
    });
  });
}
