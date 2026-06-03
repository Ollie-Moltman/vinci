import 'package:flutter_test/flutter_test.dart';
import 'package:vinci/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const VinciApp());
    expect(find.text('Vinci'), findsAny);
  });
}