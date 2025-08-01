// lib/models/food_recommendation.dart
import 'food_item.dart';
import '../services/food_database.dart';

class FoodRecommendation {
  final FoodItem food;
  final double recommendedQuantity;
  final String reason;
  final double score; // 0-1 评分
  final String category; // 推荐类别
  final List<String> tags; // 推荐标签

  FoodRecommendation({
    required this.food,
    required this.recommendedQuantity,
    required this.reason,
    required this.score,
    required this.category,
    this.tags = const [],
  });

  // 计算推荐食物的卡路里
  double get estimatedCalories =>
      FoodDatabaseService.calculateCalories(food, recommendedQuantity);

  // 获取推荐强度等级
  String get strengthLevel {
    if (score >= 0.8) return '强烈推荐';
    if (score >= 0.6) return '推荐';
    if (score >= 0.4) return '可以考虑';
    return '一般';
  }

  // 获取推荐图标
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
