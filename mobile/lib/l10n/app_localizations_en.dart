// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cal';

  @override
  String get tabToday => 'Today';

  @override
  String get tabNutrition => 'Nutrition';

  @override
  String get tabWorkouts => 'Workouts';

  @override
  String get tabCommunity => 'Community';

  @override
  String get tabProfile => 'Profile';

  @override
  String get loginTitle => 'Sign In to Cal';

  @override
  String get registerTitle => 'Create an Account';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get nameLabel => 'Full Name';

  @override
  String get ageLabel => 'Age';

  @override
  String get ageGateError =>
      'You must be at least 18 years old to use this app.';

  @override
  String get calorieRemaining => 'Remaining';

  @override
  String get calorieConsumed => 'Consumed';

  @override
  String get calorieTarget => 'Target';

  @override
  String get protein => 'Protein';

  @override
  String get carbs => 'Carbs';

  @override
  String get fat => 'Fat';

  @override
  String get water => 'Water';

  @override
  String get breakfast => 'Breakfast';

  @override
  String get lunch => 'Lunch';

  @override
  String get dinner => 'Dinner';

  @override
  String get snack => 'Snack';

  @override
  String get addFood => 'Log Food';

  @override
  String get scanBarcode => 'Scan Barcode';

  @override
  String get photoFood => 'Food Photo (AI)';

  @override
  String get textFood => 'Log with Text';

  @override
  String get aiCoach => 'AI Coach';

  @override
  String get recipes => 'Healthy Recipes';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get emptyStateNoData => 'No data recorded yet.';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred. Please try again.';

  @override
  String get retry => 'Retry';

  @override
  String get offlinePendingSync => 'Saved offline. Will sync when back online.';
}
