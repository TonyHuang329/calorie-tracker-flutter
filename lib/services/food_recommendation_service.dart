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

  // 获取个性化推荐 - 主要入口方法
  Future<List<FoodRecommendation>> getPersonalizedRecommendations(
    UserProfile user,
    String mealType,
  ) async {
    print('开始生成推荐: 用户=${user.name}, 餐次=$mealType');

    // 获取基础数据
    final todayRecords = await DatabaseService.getTodayFoodRecords();
    final userHistory = await DatabaseService.getRecentFoodRecords();
    final todayCalories =
        todayRecords.fold(0.0, (sum, record) => sum + record.totalCalories);
    final targetCalories = user.calculateTDEE();
    final remainingCalories = targetCalories - todayCalories;

    print('今日已摄入: ${todayCalories.round()} / ${targetCalories.round()} kcal');
    print('剩余卡路里: ${remainingCalories.round()} kcal');

    List<FoodRecommendation> recommendations = [];

    // 1. 基于卡路里的推荐 (最重要)
    recommendations
        .addAll(_getCalorieBasedRecommendations(remainingCalories, mealType));

    // 2. 基于用户偏好的推荐
    recommendations
        .addAll(_getPreferenceBasedRecommendations(userHistory, mealType));

    // 3. 基于时间的推荐
    recommendations.addAll(_getTimeBasedRecommendations(mealType));

    // 去重、排序和筛选
    recommendations = _processRecommendations(recommendations);

    print('生成了 ${recommendations.length} 个推荐');

    return recommendations.take(6).toList();
  }

  // 1. 基于卡路里的推荐 - 核心逻辑
  List<FoodRecommendation> _getCalorieBasedRecommendations(
      double remainingCalories, String mealType) {
    final allFoods = FoodDatabaseService.getAllFoods();
    List<FoodRecommendation> recommendations = [];

    // 根据餐次Confirm理想卡路里范围
    double idealCalories =
        _getIdealCaloriesForMeal(remainingCalories, mealType);
    print('$mealType 理想卡路里: ${idealCalories.round()} kcal');

    for (var food in allFoods) {
      final recommendedQuantity =
          FoodDatabaseService.getRecommendedServing(food);
      final foodCalories =
          FoodDatabaseService.calculateCalories(food, recommendedQuantity);

      // 计算卡路里匹配度
      final calorieDeviation = (foodCalories - idealCalories).abs();
      final maxDeviation = idealCalories * 0.4; // 允许40%的偏差

      if (calorieDeviation <= maxDeviation) {
        final score = 1.0 - (calorieDeviation / maxDeviation);

        recommendations.add(FoodRecommendation(
          food: food,
          recommendedQuantity: recommendedQuantity,
          reason: '卡路里适中 (${foodCalories.round()} kcal)',
          score: score * 0.9, // 基础权重0.9
          category: 'calorie_match',
          tags: ['卡路里匹配'],
        ));
      }
    }

    print('卡路里推荐: ${recommendations.length} 个');
    return recommendations;
  }

  // 2. 基于用户偏好的推荐
  List<FoodRecommendation> _getPreferenceBasedRecommendations(
    List<FoodRecord> userHistory,
    String mealType,
  ) {
    List<FoodRecommendation> recommendations = [];

    if (userHistory.isEmpty) {
      print('没有History Records，跳过偏好推荐');
      return recommendations;
    }

    // 分析用户偏好
    Map<String, int> categoryPreference = {};
    Map<String, int> foodPreference = {};

    for (var record in userHistory) {
      final category = record.foodItem?.category ?? '';
      final foodName = record.foodItem?.name ?? '';

      categoryPreference[category] = (categoryPreference[category] ?? 0) + 1;
      foodPreference[foodName] = (foodPreference[foodName] ?? 0) + 1;
    }

    // 找出喜欢的类别 (吃过2次以上的)
    final preferredCategories = categoryPreference.entries
        .where((entry) => entry.value >= 2)
        .map((entry) => entry.key)
        .toList();

    print('用户偏好类别: $preferredCategories');

    final allFoods = FoodDatabaseService.getAllFoods();

    for (var food in allFoods) {
      if (preferredCategories.contains(food.category)) {
        final foodFrequency = foodPreference[food.name] ?? 0;

        // 推荐吃过但不太频繁的食物 (1-3次)
        if (foodFrequency >= 1 && foodFrequency <= 3) {
          final score = 0.6 + (foodFrequency * 0.1);

          recommendations.add(FoodRecommendation(
            food: food,
            recommendedQuantity:
                FoodDatabaseService.getRecommendedServing(food),
            reason: '你之前喜欢这类食物',
            score: score,
            category: 'user_preference',
            tags: ['个人偏好', '${food.category}'],
          ));
        }
      }
    }

    print('偏好推荐: ${recommendations.length} 个');
    return recommendations;
  }

  // 3. 基于时间的推荐
  List<FoodRecommendation> _getTimeBasedRecommendations(String mealType) {
    List<FoodRecommendation> recommendations = [];
    final allFoods = FoodDatabaseService.getAllFoods();
    final currentHour = DateTime.now().hour;

    print('当前时间: ${currentHour}点, 餐次: $mealType');

    for (var food in allFoods) {
      double score = 0.0;
      String reason = '';
      List<String> tags = [];

      // 根据餐次推荐不同类型的食物
      switch (mealType) {
        case 'breakfast':
          if (food.category == 'Protein' || food.category == 'Staple Food') {
            score = 0.7;
            reason = 'Breakfast营养搭配';
            tags = ['Breakfast推荐', '营养均衡'];
          } else if (food.category == 'Fruits') {
            score = 0.5;
            reason = 'BreakfastFruits';
            tags = ['Breakfast推荐', '维生素'];
          }
          break;

        case 'lunch':
          if (food.category == 'Protein' || food.category == 'Vegetables') {
            score = 0.6;
            reason = 'Lunch均衡营养';
            tags = ['Lunch推荐', '营养搭配'];
          } else if (food.category == 'Staple Food') {
            score = 0.5;
            reason = 'LunchStaple Food';
            tags = ['Lunch推荐', '能量补充'];
          }
          break;

        case 'dinner':
          if (food.category == 'Vegetables') {
            score = 0.7;
            reason = 'Dinner清淡健康';
            tags = ['Dinner推荐', '清淡饮食'];
          } else if (food.category == 'Protein' && currentHour < 19) {
            score = 0.5;
            reason = '适量Protein';
            tags = ['Dinner推荐', '适量摄入'];
          }
          break;

        case 'snack':
          if (food.category == 'Fruits') {
            score = 0.6;
            reason = '健康Snacks';
            tags = ['Snacks推荐', '天然食品'];
          } else if (food.name.contains('坚果') || food.name.contains('酸奶')) {
            score = 0.5;
            reason = '营养Snacks';
            tags = ['Snacks推荐', '营养补充'];
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

    print('时间推荐: ${recommendations.length} 个');
    return recommendations;
  }

  // 辅助方法 - 计算餐次理想卡路里
  double _getIdealCaloriesForMeal(double remainingCalories, String mealType) {
    // 如果剩余卡路里很少，就按比例分配
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

    // 按标准比例分配
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

  // 处理推荐结果 - 去重、排序、筛选
  List<FoodRecommendation> _processRecommendations(
      List<FoodRecommendation> recommendations) {
    // 1. 去重 (同一个食物只保留分数最高的)
    Map<String, FoodRecommendation> uniqueRecommendations = {};

    for (var rec in recommendations) {
      final key = rec.food.name;
      if (!uniqueRecommendations.containsKey(key) ||
          uniqueRecommendations[key]!.score < rec.score) {
        uniqueRecommendations[key] = rec;
      }
    }

    // 2. 按分数排序
    final result = uniqueRecommendations.values.toList();
    result.sort((a, b) => b.score.compareTo(a.score));

    // 3. 过滤掉分数太低的 (小于0.3)
    return result.where((rec) => rec.score >= 0.3).toList();
  }

  // 快速推荐 - 用于首页显示
  Future<List<String>> getQuickRecommendations(UserProfile user) async {
    final hour = DateTime.now().hour;
    final mealType = _getMealTypeFromHour(hour);

    print('快速推荐: 当前时间 ${hour}点, 推断餐次: $mealType');

    final recommendations =
        await getPersonalizedRecommendations(user, mealType);
    final result = recommendations.take(3).map((r) => r.food.name).toList();

    print('快速推荐结果: $result');
    return result;
  }

  // 根据时间推断餐次
  String _getMealTypeFromHour(int hour) {
    if (hour >= 6 && hour < 10) return 'breakfast';
    if (hour >= 11 && hour < 14) return 'lunch';
    if (hour >= 17 && hour < 20) return 'dinner';
    return 'snack';
  }
}

