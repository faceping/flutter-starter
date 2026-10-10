import 'package:facecheck/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the setup problem when FacePing is not set up', (tester) async {
    await tester.pumpWidget(const FaceCheckApp(setupProblem: 'That isn\'t a sandbox key.'));
    await tester.pump();
    expect(find.text('FaceCheck'), findsOneWidget);
    expect(find.text('Sandbox key problem'), findsOneWidget);
    expect(find.text('That isn\'t a sandbox key.'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'Enrol my face'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Verify'), findsOneWidget);
  });
}
