import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:minerproject/widgets/progress_card.dart';

void main() {
  testWidgets('ProgressCard displays title and value', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressCard(
            title: 'Overall Progress',
            value: '75%',
            icon: Icons.trending_up,
            color: Colors.blue,
          ),
        ),
      ),
    );
    expect(find.text('Overall Progress'), findsOneWidget);
    expect(find.text('75%'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
  });
}
