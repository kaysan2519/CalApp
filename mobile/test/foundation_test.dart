import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal/main.dart';
import 'package:cal/core/offline/offline_queue.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('F00 Foundation Tests', () {
    testWidgets('CalApp renders dashboard and 4 bottom navigation tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: CalApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cal'), findsOneWidget);
      expect(find.text('Target Hari Ini'), findsOneWidget);
      expect(find.text('Hari Ini'), findsOneWidget);
      expect(find.text('Nutrisi'), findsOneWidget);
      expect(find.text('Latihan'), findsOneWidget);
      expect(find.text('Komunitas'), findsOneWidget);
    });

    test('TokenStorage saves, reads, and clears auth tokens correctly', () async {
      final storage = TokenStorage();
      await storage.saveTokens(accessToken: 'mock_access_123', refreshToken: 'mock_refresh_456');

      final access = await storage.getAccessToken();
      final refresh = await storage.getRefreshToken();

      expect(access, 'mock_access_123');
      expect(refresh, 'mock_refresh_456');

      await storage.clearTokens();
      final clearedAccess = await storage.getAccessToken();
      expect(clearedAccess, isNull);
    });

    test('OfflineQueue enqueues mutations with unique idempotency keys', () async {
      final storage = TokenStorage();
      final client = ApiClient(tokenStorage: storage);
      final queue = OfflineQueue(apiClient: client);

      final m1 = await queue.enqueue(
        actionType: 'MEAL_LOG',
        endpoint: '/nutrition/log',
        method: 'POST',
        payload: {'food_name': 'Nasi Putih', 'calories': 130},
      );

      final m2 = await queue.enqueue(
        actionType: 'MEAL_LOG',
        endpoint: '/nutrition/log',
        method: 'POST',
        payload: {'food_name': 'Dada Ayam', 'calories': 165},
      );

      expect(m1.idempotencyKey, isNotEmpty);
      expect(m2.idempotencyKey, isNotEmpty);
      expect(m1.idempotencyKey != m2.idempotencyKey, isTrue);

      final pending = await queue.getPendingMutations();
      expect(pending.length, 2);
      expect(pending[0].payload['food_name'], 'Nasi Putih');
      expect(pending[1].payload['food_name'], 'Dada Ayam');
    });
  });
}
