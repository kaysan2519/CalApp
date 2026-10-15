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

    testWidgets('RegisterScreen multi-step wizard navigates through steps', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Step 1: Name — should show title and name field
      expect(find.text('Siapa namamu?'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nama Lengkap'), findsOneWidget);
      expect(find.text('1/8'), findsOneWidget);

      // Try to proceed without entering name → validation error
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();
      expect(find.text('Nama wajib diisi'), findsOneWidget);

      // Enter a valid name and proceed
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Lengkap'),
        'Budi Santoso',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();

      // Step 2: Email & Password
      expect(find.text('Email & Kata Sandi'), findsOneWidget);
      expect(find.text('2/8'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Email'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Kata Sandi'), findsOneWidget);
    });

    testWidgets('RegisterScreen enforces age-gate >= 18 years on step 3', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      // Step 1: Fill name
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nama Lengkap'),
        'Budi',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();

      // Step 2: Fill email & password
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Email'),
        'budi@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Kata Sandi'),
        'password123',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();

      // Step 3: Age — should be visible
      expect(find.text('Berapa usiamu?'), findsOneWidget);
      expect(find.text('3/8'), findsOneWidget);

      // Enter age under 18
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usia (tahun)'),
        '17',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();

      // Should show age gate error
      expect(find.text('Kamu harus berusia minimal 18 tahun'), findsOneWidget);

      // Enter valid age
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Usia (tahun)'),
        '25',
      );
      await tester.tap(find.widgetWithText(FilledButton, 'Lanjut'));
      await tester.pumpAndSettle();

      // Should advance to Step 4: Gender
      expect(find.text('Jenis Kelamin'), findsOneWidget);
      expect(find.text('4/8'), findsOneWidget);
    });

    testWidgets('RegisterScreen shows "Sudah punya akun?" link on step 1', (tester) async {
      await tester.pumpWidget(createTestWidget(const RegisterScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Sudah punya akun? '), findsOneWidget);
      expect(find.widgetWithText(TextButton, 'Masuk'), findsOneWidget);
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
