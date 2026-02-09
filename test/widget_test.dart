import 'package:flutter_test/flutter_test.dart';

import 'package:vakt/app.dart';

void main() {
  testWidgets('App renders VAKT text', (WidgetTester tester) async {
    await tester.pumpWidget(const VaktApp());
    expect(find.text('VAKT'), findsOneWidget);
  });
}
