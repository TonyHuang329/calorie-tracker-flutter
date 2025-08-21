// lib/models/food_recommendation.dart
import 'food_item.dart';
import '../services/food_database.dart';

class FoodRecommendation {
  final FoodItem food;
  final double recommendedQuantity;
  final String reason;
  final double score; // Score 0-1
  final String category; // Recommendation category
  final List<String> tags; // Recommendation tags

  FoodRecommendation({
    required this.food,
    required this.recommendedQuantity,
    required this.reason,
    required this.score,
    required this.category,
    this.tags = const [],
  });

  // Calculate calories for recommended food
  double get estimatedCalories =>
      FoodDatabaseService.calculateCalories(food, recommendedQuantity);

  // Get recommendation strength level
  String get strengthLevel {
    if (score >= 0.8) return 'Strongly Recommended';
    if (score >= 0.6) return 'Recommended';
    if (score >= 0.4) return 'Consider';
    return 'Optional';
  }

  // Get recommendation icon
  String get iconEmoji {
    switch (category) {
      case 'calorie_match':
        return '🎯';
      case 'nutrition_balance':
        return '⚖️';
      case 'user_preference':
        return '❤️';
      case 'time_based':
        return '⏰';
      case 'health_goal':
        return '🏆';
      default:
        return '🍽️';
    }
  }

  @override
  String toString() {
    return 'FoodRecommendation(${food.name}, score: ${score.toStringAsFixed(2)}, reason: $reason)';
  }
}
