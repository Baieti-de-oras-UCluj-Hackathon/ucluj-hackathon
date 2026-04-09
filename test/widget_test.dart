import 'package:flutter_test/flutter_test.dart';
import 'package:umbraro/app/app.dart';

void main() {
  testWidgets('App builds without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const UmbraRoApp());
  });
}
