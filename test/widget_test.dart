import 'package:flutter_test/flutter_test.dart';
import 'package:web_creative_clicks_connect/main.dart';

void main() {
  testWidgets('App renders Web Creative Clicks app bar', (WidgetTester tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MyApp());
      await tester.pump();
      expect(find.text('Web Creative Clicks'), findsWidgets);
      expect(find.byType(NewsHomePage), findsOneWidget);
    });
  });
}
