import 'package:flutter_test/flutter_test.dart';
import 'package:plant_care_app/app.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantCareApp());
    expect(find.byType(PlantCareApp), findsOneWidget);
  });
}
