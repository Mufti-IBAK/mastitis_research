import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:project_mastitis/widgets/cmt_score_selector.dart';

void main() {
  testWidgets('CmtScoreSelector renders all 5 CMT scores + Not done', (WidgetTester tester) async {
    String? selectedScore;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CmtScoreSelector(
            value: selectedScore,
            onChanged: (score) {
              selectedScore = score;
            },
          ),
        ),
      ),
    );

    expect(find.text('N'), findsOneWidget);
    expect(find.text('T'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('ND'), findsOneWidget);
  });
}
