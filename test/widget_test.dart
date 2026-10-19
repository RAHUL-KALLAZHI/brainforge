import 'package:brainforge/app/app.dart';
import 'package:brainforge/app/router.dart';
import 'package:brainforge/core/di/injection.dart';
import 'package:flutter_test/flutter_test.dart';
import 'helpers/test_helper.dart';

void main() {
  setUp(() async {
    await initTestDependencies();
  });

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('BrainForge smoke test: App launches and renders Home shell',
      (WidgetTester tester) async {
    final testRouter = createRouter();
    await tester.pumpWidget(BrainForgeApp(router: testRouter));
    await tester.pumpAndSettle();

    expect(find.text('BrainForge'), findsWidgets);
    expect(find.text("Today's Workout"), findsOneWidget);
  });
}
