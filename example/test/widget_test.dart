import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_gsm_example/main.dart';

void main() {
  testWidgets('renders ModemListScreen app bar', (WidgetTester tester) async {
    await tester.pumpWidget(const FlutterGsmExampleApp());

    expect(find.text('flutter_gsm example'), findsOneWidget);
  });
}
