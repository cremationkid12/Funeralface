import 'package:flutter_test/flutter_test.dart';

import 'package:funeralface_mobile/main.dart';

void main() {
  testWidgets('App boots and shows title', (WidgetTester tester) async {
    await tester.pumpWidget(const FuneralfaceApp());

    expect(find.text('Funeralface'), findsWidgets);
    expect(find.textContaining('API client base URL: http://localhost:3000'), findsOneWidget);
  });
}
