import 'package:flutter_test/flutter_test.dart';

import 'package:pronunciation_app/main.dart';

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const PronunciationApp());
    await tester.pump(const Duration(milliseconds: 100));
  });
}