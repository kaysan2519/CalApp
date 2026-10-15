import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal/main.dart';
import 'test_support.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: loggedOutAppOverrides(),
        child: const CalApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Progress yang terasa milikmu.'), findsOneWidget);
    expect(find.text('Buat akun'), findsOneWidget);
  });
}
