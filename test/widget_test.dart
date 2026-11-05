import 'package:flutter_test/flutter_test.dart';
import 'package:kinsenas/main.dart';

void main() {
  testWidgets('App starts with KinsenasApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const KinsenasApp());
    expect(find.byType(KinsenasApp), findsOneWidget);
  });
}
