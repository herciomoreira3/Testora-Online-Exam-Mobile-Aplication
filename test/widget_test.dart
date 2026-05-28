import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:testora/shared/widgets/custom_button.dart';

void main() {
  testWidgets('CustomButton renders its label', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(text: 'Start Exam', onPressed: () {}),
        ),
      ),
    );

    expect(find.text('Start Exam'), findsOneWidget);
  });
}
