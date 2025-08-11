// lib/services/food_recommendation_service.dart
import '../models/food_item.dart';
import '../models/food_recommendation.dart';
import '../models/user_profile.dart';
import 'database_service.dart';
import 'food_database.dart';

class FoodRecommendationService {
  static FoodRecommendationService? _instance;
  static FoodRecommendationService get instance =>
      _instance ??= FoodRecommendationService._();
  FoodRecommendationService._();

  /// Get personalized recommendations - main entry method
  Future<List<FoodRecommendation>> getPersonalizedRecommendations(
    UserProfile user,
    String mealType,
  ) async {
    print(
        'Starting recommendation generation: user=${user.name}, meal=$mealType');

    // Get basic data
    final todayRecords = await DatabaseService.getTodayFoodRecords();
    final userHistory = await DatabaseService.getRecentFoodRecords();
    final todayCalories =
        todayRecords.fold(0.0, (sum, record) => sum + record.totalCalories);
    final targetCalories = user.calculateTDEE();
    final remainingCalories = targetCalories - todayCalories;

    print(
        'Today\'s intake: ${todayCalories.round()} / ${targetCalories.round()} kcal');
    print('Remaining calories: ${remainingCalories.round()} kcal');

    List<FoodRecommendation> recommendations = [];

    // 1. Calorie-based recommendations (most important)
    recommendations
        .addAll(_getCalorieBasedRecommendations(remainingCalories, mealType));

    // 2. User preference-based recommendations
    recommendations
        .addAll(_getPreferenceBasedRecommendations(userHistory, mealType));

    // 3. Time-based recommendations
    recommendations.addAll(_getTimeBasedRecommendations(mealType));

    // Deduplicate, sort and filter
    recommendations = _processRecommendations(recommendations);

    print('Generated ${recommendations.length} recommendations');

    return recommendations.take(6).toList();
  }

  /// 1. Calorie-based recommendations - core logic
  List<FoodRecommendation> _getCalorieBasedRecommendations(
      double remainingCalories, String mealType) {
    final allFoods = FoodDatabaseService.getAllFoods();
    List<FoodRecommendation> recommendations = [];

    // Determine ideal calorie range based on meal type
    double idealCalories =
        _getIdealCaloriesForMeal(remainingCalories, mealType);
    print('$mealType ideal calories: ${idealCalories.round()} kcal');

    for (var food in allFoods) {
      final recommendedQuantity =
          FoodDatabaseService.getRecommendedServing(food);
      final foodCalories =
          FoodDatabaseService.calculateCalories(food, recommendedQuantity);

      // Calculate calorie match
      final calorieDeviation = (foodCalories - idealCalories).abs();
      final maxDeviation = idealCalories * 0.4; // Allow 40% deviation

      if (calorieDeviation <= maxDeviation) {
        final score = 1.0 - (calorieDeviation / maxDeviation);

        recommendations.add(FoodRecommendation(
          food: food,
          recommendedQuantity: recommendedQuantity,
          reason: 'Moderate calories (${foodCalories.round()} kcal)',
          score: score * 0.9, // Base weight 0.9
          category: 'calorie_match',
          tags: ['Calorie Match'],
        ));
      }
    }

    print('Calorie recommendations: ${recommendations.length} items');
    return recommendations;
  }

  /// 2. User preference-based recommendations
  List<FoodRecommendation> _getPreferenceBasedRecommendations(
    List<FoodRecord> userHistory,
    String mealType,
  ) {
    List<FoodRecommendation> recommendations = [];

    if (userHistory.isEmpty) {
      print('No history records, skipping preference recommendations');
      return recommendations;
    }

    // Analyze user preferences
    Map<String, int> categoryPreference = {};
    Map<String, int> foodPreference = {};

    for (var record in userHistory) {
      final category = record.foodItem?.category ?? '';
      final foodName = record.foodItem?.name ?? '';

      categoryPreference[category] = (categoryPreference[category] ?? 0) + 1;
      foodPreference[foodName] = (foodPreference[foodName] ?? 0) + 1;
    }

    // Find preferred categories (eaten 2+ times)
    final preferredCategories = categoryPreference.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList();

    print('User preferred categories: $preferredCategories');

    final allFoods = FoodDatabaseService.getAllFoods();

    for (var food in allFoods) {
      if (preferredCategories.contains(food.category)) {
        final foodFrequency = foodPreference[food.name] ?? 0;

        // Recommend foods eaten before but not too frequently (1-3 times)
        if (foodFrequency >= 1 && foodFrequency <= 3) {
          final score = 0.6 + (foodFrequency * 0.1);

          recommendations.add(FoodRecommendation(
            food: food,
            recommendedQuantity:
                FoodDatabaseService.getRecommendedServing(food),
            reason: 'You liked this type of food before',
            score: score,
            category: 'user_preference',
            tags: ['Personal Preference', '${food.category}'],
          ));
        }
      }
    }

    print('Preference recommendations: ${recommendations.length} items');
    return recommendations;
  }

  /// 3. Time-based recommendations
  List<FoodRecommendation> _getTimeBasedRecommendations(String mealType) {
    List<FoodRecommendation> recommendations = [];
    final allFoods = FoodDatabaseService.getAllFoods();
    final currentHour = DateTime.now().hour;

    print('Current time: ${currentHour}h, meal type: $mealType');

    for (var food in allFoods) {
      double score = 0.0;
      String reason = '';
      List<String> tags = [];

      // Recommend different food types based on meal type
      switch (mealType) {
        case 'breakfast':
          if (food.category == 'Protein' || food.category == 'Staple Food') {
            score = 0.7;
            reason = 'Breakfast nutrition balance';
            tags = ['Breakfast Recommendation', 'Balanced Nutrition'];
          } else if (food.category == 'Fruits') {
            score = 0.5;
            reason = 'Breakfast fruits';
            tags = ['Breakfast Recommendation', 'Vitamins'];
          }
          break;

        case 'lunch':
          if (food.category == 'Protein' || food.category == 'Vegetables') {
            score = 0.6;
            reason = 'Lunch balanced nutrition';
            tags = ['Lunch Recommendation', 'Nutritional Balance'];
          } else if (food.category == 'Staple Food') {
            score = 0.5;
            reason = 'Lunch staple food';
            tags = ['Lunch Recommendation', 'Energy Supply'];
          }
          break;

        case 'dinner':
          if (food.category == 'Vegetables') {
            score = 0.7;
            reason = 'Dinner light and healthy';
            tags = ['Dinner Recommendation', 'Light Diet'];
          } else if (food.category == 'Protein' && currentHour < 19) {
            score = 0.5;
            reason = 'Moderate protein';
            tags = ['Dinner Recommendation', 'Moderate Intake'];
          }
          break;

        case 'snack':
          if (food.category == 'Fruits') {
            score = 0.6;
            reason = 'Healthy snacks';
            tags = ['Snack Recommendation', 'Natural Food'];
          } else if (food.name.contains('nuts') ||
              food.name.contains('yogurt')) {
            score = 0.5;
            reason = 'Nutritious snacks';
            tags = ['Snack Recommendation', 'Nutritional Supplement'];
          }
          break;
      }

      if (score > 0) {
        recommendations.add(FoodRecommendation(
          food: food,
          recommendedQuantity: FoodDatabaseService.getRecommendedServing(food),
          reason: reason,
          score: score,
          category: 'time_based',
          tags: tags,
        ));
      }
    }

    print('Time recommendations: ${recommendations.length} items');
    return recommendations;
  }

  /// Helper method - calculate ideal calories for meal
  double _getIdealCaloriesForMeal(double remainingCalories, String mealType) {
    // If very few calories remaining, allocate proportionally
    if (remainingCalories <= 0) {
      switch (mealType) {
        case 'breakfast':
          return 400;
        case 'lunch':
          return 600;
        case 'dinner':
          return 500;
        case 'snack':
          return 150;
        default:
          return 300;
      }
    }

    // Allocate by standard proportions
    switch (mealType) {
      case 'breakfast':
        return remainingCalories * 0.25; // 25%
      case 'lunch':
        return remainingCalories * 0.35; // 35%
      case 'dinner':
        return remainingCalories * 0.30; // 30%
      case 'snack':
        return remainingCalories * 0.10; // 10%
      default:
        return remainingCalories * 0.25;
    }
  }

  /// Process recommendation results - deduplicate, sort, filter
  List<FoodRecommendation> _processRecommendations(
      List<FoodRecommendation> recommendations) {
    // 1. Deduplicate (keep only highest score for same food)
    Map<String, FoodRecommendation> uniqueRecommendations = {};

    for (var rec in recommendations) {
      final key = rec.food.name;
      if (!uniqueRecommendations.containsKey(key) ||
          uniqueRecommendations[key]!.score < rec.score) {
        uniqueRecommendations[key] = rec;
      }
    }

    // 2. Sort by score
    final result = uniqueRecommendations.values.toList();
    result.sort((a, b) => b.score.compareTo(a.score));

    // 3. Filter out scores too low (< 0.3)
    return result.where((rec) => rec.score >= 0.3).toList();
  }

  /// Quick recommendations - for homepage display
  Future<List<String>> getQuickRecommendations(UserProfile user) async {
    final hour = DateTime.now().hour;
    final mealType = _getMealTypeFromHour(hour);

    print(
        'Quick recommendations: current time ${hour}h, inferred meal: $mealType');

    final recommendations =
        await getPersonalizedRecommendations(user, mealType);
    final result = recommendations.take(3).map((r) => r.food.name).toList();

    print('Quick recommendation results: $result');
    return result;
  }

  /// Infer meal type from hour
  String _getMealTypeFromHour(int hour) {
    if (hour >= 6 && hour < 10) return 'breakfast';
    if (hour >= 11 && hour < 14) return 'lunch';
    if (hour >= 17 && hour < 20) return 'dinner';
    return 'snack';
  }

  /// Get nutritional recommendations based on current intake
  Future<List<FoodRecommendation>> getNutritionalRecommendations(
    UserProfile user,
    Map<String, double> currentNutrition,
  ) async {
    List<FoodRecommendation> recommendations = [];
    final allFoods = FoodDatabaseService.getAllFoods();

    // Calculate nutritional needs
    final targetCalories = user.calculateTDEE();
    final targetProtein = user.weight * 1.2; // 1.2g protein per kg body weight
    final targetCarbs = targetCalories * 0.5 / 4; // 50% calories from carbs
    final targetFat = targetCalories * 0.3 / 9; // 30% calories from fat

    // Calculate deficiencies
    final proteinDeficit = targetProtein - (currentNutrition['protein'] ?? 0);
    final carbsDeficit = targetCarbs - (currentNutrition['carbs'] ?? 0);
    final fatDeficit = targetFat - (currentNutrition['fat'] ?? 0);

    for (var food in allFoods) {
      double score = 0.0;
      List<String> reasons = [];

      final nutrition = FoodDatabaseService.getNutritionSummary(
        food,
        FoodDatabaseService.getRecommendedServing(food),
      );

      // Score based on nutritional gaps
      if (proteinDeficit > 5 && (nutrition['protein'] ?? 0) > 10) {
        score += 0.4;
        reasons.add('High protein content');
      }

      if (carbsDeficit > 10 && (nutrition['carbs'] ?? 0) > 20) {
        score += 0.3;
        reasons.add('Good carbohydrate source');
      }

      if (fatDeficit > 5 && (nutrition['fat'] ?? 0) > 5) {
        score += 0.2;
        reasons.add('Healthy fats');
      }

      // Bonus for balanced foods
      if ((nutrition['protein'] ?? 0) > 5 &&
          (nutrition['carbs'] ?? 0) > 10 &&
          (nutrition['fat'] ?? 0) > 2) {
        score += 0.1;
        reasons.add('Balanced nutrition');
      }

      if (score > 0.3) {
        recommendations.add(FoodRecommendation(
          food: food,
          recommendedQuantity: FoodDatabaseService.getRecommendedServing(food),
          reason: reasons.join(', '),
          score: score,
          category: 'nutritional_balance',
          tags: ['Nutrition', 'Health'],
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(5).toList();
  }

  /// Get recommendations for specific health goals
  Future<List<FoodRecommendation>> getHealthGoalRecommendations(
    String healthGoal,
  ) async {
    List<FoodRecommendation> recommendations = [];
    final allFoods = FoodDatabaseService.getAllFoods();

    for (var food in allFoods) {
      double score = 0.0;
      String reason = '';
      List<String> tags = ['Health Goal'];

      switch (healthGoal.toLowerCase()) {
        case 'weight_loss':
          // Prefer low-calorie, high-fiber foods
          if (food.category == 'Vegetables' || food.category == 'Fruits') {
            score = 0.8;
            reason = 'Low calorie, high fiber for weight loss';
            tags.add('Weight Loss');
          } else if (food.category == 'Protein' && food.caloriesPerUnit < 2.0) {
            score = 0.6;
            reason = 'Lean protein supports weight loss';
            tags.add('Lean Protein');
          }
          break;

        case 'muscle_gain':
          // Prefer high-protein foods
          if (food.category == 'Protein') {
            score = 0.9;
            reason = 'High protein supports muscle growth';
            tags.add('Muscle Building');
          } else if (food.category == 'Staple Food') {
            score = 0.5;
            reason = 'Carbs provide energy for workouts';
            tags.add('Energy');
          }
          break;

        case 'heart_health':
          // Prefer foods with healthy fats and low sodium
          if (food.category == 'Fruits' || food.category == 'Vegetables') {
            score = 0.7;
            reason = 'Rich in antioxidants and fiber';
            tags.add('Heart Healthy');
          } else if (food.name == 'Fish') {
            score = 0.8;
            reason = 'Omega-3 fatty acids support heart health';
            tags.add('Omega-3');
          }
          break;

        case 'energy_boost':
          // Prefer complex carbs and moderate protein
          if (food.category == 'Staple Food') {
            score = 0.7;
            reason = 'Complex carbs provide sustained energy';
            tags.add('Energy Boost');
          } else if (food.category == 'Fruits') {
            score = 0.6;
            reason = 'Natural sugars for quick energy';
            tags.add('Natural Energy');
          }
          break;
      }

      if (score > 0) {
        recommendations.add(FoodRecommendation(
          food: food,
          recommendedQuantity: FoodDatabaseService.getRecommendedServing(food),
          reason: reason,
          score: score,
          category: 'health_goal',
          tags: tags,
        ));
      }
    }

    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(8).toList();
  }

  /// Get seasonal food recommendations
  List<FoodRecommendation> getSeasonalRecommendations() {
    List<FoodRecommendation> recommendations = [];
    final allFoods = FoodDatabaseService.getAllFoods();
    final month = DateTime.now().month;

    // Define seasonal preferences
    String season = '';
    List<String> seasonalCategories = [];
    String seasonalReason = '';

    if (month >= 3 && month <= 5) {
      season = 'Spring';
      seasonalCategories = ['Vegetables', 'Fruits'];
      seasonalReason = 'Fresh spring produce';
    } else if (month >= 6 && month <= 8) {
      season = 'Summer';
      seasonalCategories = ['Fruits', 'Beverages'];
      seasonalReason = 'Hydrating summer foods';
    } else if (month >= 9 && month <= 11) {
      season = 'Autumn';
      seasonalCategories = ['Staple Food', 'Protein'];
      seasonalReason = 'Hearty autumn nutrition';
    } else {
      season = 'Winter';
      seasonalCategories = ['Protein', 'Staple Food'];
      seasonalReason = 'Warming winter foods';
    }

    for (var food in allFoods) {
      if (seasonalCategories.contains(food.category)) {
        recommendations.add(FoodRecommendation(
          food: food,
          recommendedQuantity: FoodDatabaseService.getRecommendedServing(food),
          reason: seasonalReason,
          score: 0.6,
          category: 'seasonal',
          tags: [season, 'Seasonal'],
        ));
      }
    }

    return recommendations.take(4).toList();
  }
}
