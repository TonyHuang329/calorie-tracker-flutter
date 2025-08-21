import '../models/user_profile.dart';

class CalorieCalculatorService {
  /// Calculate daily calorie needs based on user profile
  static double calculateDailyCalorieNeeds(UserProfile user) {
    return user.calculateTDEE();
  }

  /// Calculate BMR - Basal Metabolic Rate
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  /// Calculate TDEE based on activity level
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier = getActivityMultiplier(activityLevel);
    return bmr * multiplier;
  }

  /// Get activity level multiplier
  static double getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // Sedentary
      case 'light':
        return 1.375; // Light activity
      case 'moderate':
        return 1.55; // Moderate activity
      case 'active':
        return 1.725; // High activity
      case 'very_active':
        return 1.9; // Very high activity
      default:
        return 1.2;
    }
  }

  /// Get activity level description
  static String getActivityLevelDescription(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 'Sedentary (little/no exercise)';
      case 'light':
        return 'Light Activity (light exercise 1-3 days/week)';
      case 'moderate':
        return 'Moderate Activity (moderate exercise 3-5 days/week)';
      case 'active':
        return 'High Activity (hard exercise 6-7 days/week)';
      case 'very_active':
        return 'Very High Activity (very hard exercise, physical job)';
      default:
        return 'Unknown activity level';
    }
  }

  /// Calculate intake percentage relative to target
  static double calculateIntakePercentage({
    required double currentIntake,
    required double targetIntake,
  }) {
    if (targetIntake == 0) return 0;
    return (currentIntake / targetIntake) * 100;
  }

  /// Calculate remaining calories to consume
  static double calculateRemainingCalories({
    required double targetIntake,
    required double currentIntake,
  }) {
    return targetIntake - currentIntake;
  }

  /// Validate input data reasonableness
  static Map<String, String?> validateUserInput({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
  }) {
    Map<String, String?> errors = {};

    // Weight validation (30-300kg)
    if (weight < 30 || weight > 300) {
      errors['weight'] = 'Weight should be between 30-300kg';
    }

    // Height validation (100-250cm)
    if (height < 100 || height > 250) {
      errors['height'] = 'Height should be between 100-250cm';
    }

    // Age validation (10-120 years)
    if (age < 10 || age > 120) {
      errors['age'] = 'Age should be between 10-120 years';
    }

    // Gender validation
    if (!['male', 'female'].contains(gender.toLowerCase())) {
      errors['gender'] = 'Gender must be male or female';
    }

    // Activity level validation
    List<String> validActivityLevels = [
      'sedentary',
      'light',
      'moderate',
      'active',
      'very_active'
    ];
    if (!validActivityLevels.contains(activityLevel.toLowerCase())) {
      errors['activityLevel'] = 'Invalid activity level';
    }

    return errors;
  }
}
