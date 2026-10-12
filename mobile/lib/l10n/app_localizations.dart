import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In id, this message translates to:
  /// **'Cal'**
  String get appTitle;

  /// No description provided for @tabToday.
  ///
  /// In id, this message translates to:
  /// **'Hari Ini'**
  String get tabToday;

  /// No description provided for @tabNutrition.
  ///
  /// In id, this message translates to:
  /// **'Nutrisi'**
  String get tabNutrition;

  /// No description provided for @tabWorkouts.
  ///
  /// In id, this message translates to:
  /// **'Latihan'**
  String get tabWorkouts;

  /// No description provided for @tabCommunity.
  ///
  /// In id, this message translates to:
  /// **'Komunitas'**
  String get tabCommunity;

  /// No description provided for @tabProfile.
  ///
  /// In id, this message translates to:
  /// **'Profil'**
  String get tabProfile;

  /// No description provided for @loginTitle.
  ///
  /// In id, this message translates to:
  /// **'Masuk ke Cal'**
  String get loginTitle;

  /// No description provided for @registerTitle.
  ///
  /// In id, this message translates to:
  /// **'Daftar Akun Baru'**
  String get registerTitle;

  /// No description provided for @emailLabel.
  ///
  /// In id, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// No description provided for @passwordLabel.
  ///
  /// In id, this message translates to:
  /// **'Kata Sandi'**
  String get passwordLabel;

  /// No description provided for @nameLabel.
  ///
  /// In id, this message translates to:
  /// **'Nama Lengkap'**
  String get nameLabel;

  /// No description provided for @ageLabel.
  ///
  /// In id, this message translates to:
  /// **'Usia'**
  String get ageLabel;

  /// No description provided for @ageGateError.
  ///
  /// In id, this message translates to:
  /// **'Usia minimal harus 18 tahun untuk menggunakan aplikasi.'**
  String get ageGateError;

  /// No description provided for @calorieRemaining.
  ///
  /// In id, this message translates to:
  /// **'Sisa Kalori'**
  String get calorieRemaining;

  /// No description provided for @calorieConsumed.
  ///
  /// In id, this message translates to:
  /// **'Dikonsumsi'**
  String get calorieConsumed;

  /// No description provided for @calorieTarget.
  ///
  /// In id, this message translates to:
  /// **'Target'**
  String get calorieTarget;

  /// No description provided for @protein.
  ///
  /// In id, this message translates to:
  /// **'Protein'**
  String get protein;

  /// No description provided for @carbs.
  ///
  /// In id, this message translates to:
  /// **'Karbohidrat'**
  String get carbs;

  /// No description provided for @fat.
  ///
  /// In id, this message translates to:
  /// **'Lemak'**
  String get fat;

  /// No description provided for @water.
  ///
  /// In id, this message translates to:
  /// **'Air'**
  String get water;

  /// No description provided for @breakfast.
  ///
  /// In id, this message translates to:
  /// **'Sarapan'**
  String get breakfast;

  /// No description provided for @lunch.
  ///
  /// In id, this message translates to:
  /// **'Makan Siang'**
  String get lunch;

  /// No description provided for @dinner.
  ///
  /// In id, this message translates to:
  /// **'Makan Malam'**
  String get dinner;

  /// No description provided for @snack.
  ///
  /// In id, this message translates to:
  /// **'Camilan'**
  String get snack;

  /// No description provided for @addFood.
  ///
  /// In id, this message translates to:
  /// **'Catat Makanan'**
  String get addFood;

  /// No description provided for @scanBarcode.
  ///
  /// In id, this message translates to:
  /// **'Pindai Barcode'**
  String get scanBarcode;

  /// No description provided for @photoFood.
  ///
  /// In id, this message translates to:
  /// **'Foto Makanan (AI)'**
  String get photoFood;

  /// No description provided for @textFood.
  ///
  /// In id, this message translates to:
  /// **'Catat via Teks Bebas'**
  String get textFood;

  /// No description provided for @aiCoach.
  ///
  /// In id, this message translates to:
  /// **'AI Coach'**
  String get aiCoach;

  /// No description provided for @recipes.
  ///
  /// In id, this message translates to:
  /// **'Resep Sehat'**
  String get recipes;

  /// No description provided for @save.
  ///
  /// In id, this message translates to:
  /// **'Simpan'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In id, this message translates to:
  /// **'Batal'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In id, this message translates to:
  /// **'Hapus'**
  String get delete;

  /// No description provided for @edit.
  ///
  /// In id, this message translates to:
  /// **'Ubah'**
  String get edit;

  /// No description provided for @emptyStateNoData.
  ///
  /// In id, this message translates to:
  /// **'Belum ada data tercatat.'**
  String get emptyStateNoData;

  /// No description provided for @loading.
  ///
  /// In id, this message translates to:
  /// **'Memuat...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In id, this message translates to:
  /// **'Terjadi kesalahan. Silakan coba lagi.'**
  String get errorOccurred;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba Lagi'**
  String get retry;

  /// No description provided for @offlinePendingSync.
  ///
  /// In id, this message translates to:
  /// **'Tersimpan offline. Akan disinkronkan saat terhubung kembali.'**
  String get offlinePendingSync;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
