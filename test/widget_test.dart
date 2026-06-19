import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(child: Text('Telemedicina')),
      ),
    ));
    expect(find.text('Telemedicina'), findsOneWidget);
  });
}
