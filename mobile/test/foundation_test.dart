import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal/main.dart';
import 'package:cal/core/offline/offline_queue.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';
import 'test_support.dart';

const _secureStorageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
final _secureStorageValues = <String, String>{};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    _secureStorageValues.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, (call) async {
      final arguments = Map<Object?, Object?>.from(call.arguments as Map);
      final key = arguments['key'] as String;
      switch (call.method) {
        case 'write':
          _secureStorageValues[key] = arguments['value'] as String;
          return null;
        case 'read':
          return _secureStorageValues[key];
        case 'delete':
          _secureStorageValues.remove(key);
          return null;
        default:
          throw MissingPluginException('Unsupported secure storage method: ${call.method}');
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_secureStorageChannel, null);
  });

  group('F00 Foundation Tests', () {
    testWidgets('CalApp routes a signed-out user to the welcome screen', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: loggedOutAppOverrides(),
          child: const CalApp(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Progress yang terasa milikmu.'), findsOneWidget);
      expect(find.text('Buat akun'), findsOneWidget);
      expect(find.text('Saya sudah punya akun'), findsOneWidget);
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
