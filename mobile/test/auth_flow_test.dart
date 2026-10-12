import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cal/features/auth/domain/auth_models.dart';
import 'package:cal/features/auth/presentation/auth_state_notifier.dart';
import 'package:cal/features/auth/presentation/login_screen.dart';
import 'package:cal/features/auth/presentation/register_screen.dart';
import 'package:cal/features/profile/presentation/profile_screen.dart';
import 'package:cal/features/auth/data/auth_repository.dart';
import 'package:cal/core/network/api_client.dart';
import 'package:cal/core/storage/token_storage.dart';

class MockAuthStateNotifier extends AuthStateNotifier {
  MockAuthStateNotifier(super.repository, User initialUser) {
    state = AsyncValue.data(initialUser);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget(Widget child, [List<Override> overrides = const []]) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('Phase 3 - Auth & Profile UI Tests', () {
    testWidgets('LoginScreen renders email and password fields and submit button', (tester) async {
      await tester.pumpWidget(createTestWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Masuk ke Cal'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.widgetWithText(ElevatedButton, 'Masuk'), findsOneWidget);
      expect(find.text('Daftar Sekarang'), findsOneWidget);
    });

    testWidgets('RegisterScreen enforces age-gate >= 18 years strictly', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Buat Akun & Target Nutrisi'), findsOneWidget);

      final ageField = find.widgetWithText(TextFormField, 'Usia (Tahun)');
      expect(ageField, findsOneWidget);

      // Enter age under 18
      await tester.enterText(ageField, '17');
      await tester.pumpAndSettle();

      // Submit registration
      final submitButton = find.widgetWithText(ElevatedButton, 'Daftar & Hitung Target');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify Age Gate Error message is triggered
      expect(
        find.text('Usia minimal harus 18 tahun untuk menggunakan aplikasi.'),
        findsOneWidget,
      );

      // Now enter valid age 25
      await tester.enterText(ageField, '25');
      await tester.pumpAndSettle();

      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // The age error should disappear
      expect(
        find.text('Usia minimal harus 18 tahun untuk menggunakan aplikasi.'),
        findsNothing,
      );
    });

    testWidgets('ProfileScreen renders user profile settings and privacy options', (tester) async {
      final testUser = User(
        id: 'usr_123',
        email: 'budi@example.com',
        name: 'Budi Santoso',
        age: 25,
        gender: 'male',
        heightCm: 175,
        weightKg: 70,
        activityLevel: 'moderate',
        goal: 'lose',
        timezone: 'Asia/Jakarta',
        nutritionTargets: NutritionTargets(
          targetCalories: 2150,
          targetProteinG: 140,
          targetCarbsG: 220,
          targetFatG: 65,
          targetWaterMl: 2500,
          isManual: false,
        ),
      );

      final tokenStorage = TokenStorage();
      final apiClient = ApiClient(tokenStorage: tokenStorage);
      final authRepo = AuthRepository(apiClient: apiClient, tokenStorage: tokenStorage);

      await tester.pumpWidget(
        createTestWidget(
          const ProfileScreen(),
          [
            authStateProvider.overrideWith((ref) => MockAuthStateNotifier(authRepo, testUser)),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Profil & Pengaturan'), findsOneWidget);
      expect(find.text('Budi Santoso'), findsOneWidget);
      expect(find.text('Target Nutrisi Harian'), findsOneWidget);
      expect(find.text('Ekspor Data Pribadi (JSON)'), findsOneWidget);
      expect(find.text('Hapus Akun Permanen'), findsOneWidget);
    });
  });
}
