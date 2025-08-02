// lib/services/food_database.dart
import '../models/food_item.dart';

class FoodDatabaseService {
  // 预设食物数据库 - 修改为以g为单位，每g的卡路里
  static List<FoodItem> _predefinedFoods = [
    // Staple Food类 (每g卡路里)
    FoodItem(
      name: 'Rice',
      caloriesPerUnit: 1.3, // 130卡路里/100g = 1.3卡路里/g
      unit: 'g',
      category: 'Staple Food',
      protein: 0.027, // 2.7gProtein/100g = 0.027g/g
      carbs: 0.28,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Noodles',
      caloriesPerUnit: 2.8,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.11,
      carbs: 0.55,
      fat: 0.011,
    ),
    FoodItem(
      name: 'Bread',
      caloriesPerUnit: 3.12,
      unit: 'g',
      category: 'Staple Food',
      protein: 0.085,
      carbs: 0.58,
      fat: 0.051,
    ),

    // Protein类
    FoodItem(
      name: 'Chicken Breast',
      caloriesPerUnit: 1.65,
      unit: 'g',
      category: 'Protein',
      protein: 0.31,
      carbs: 0.0,
      fat: 0.036,
    ),
    FoodItem(
      name: 'Egg',
      caloriesPerUnit: 1.55,
      unit: 'g',
      category: 'Protein',
      protein: 0.13,
      carbs: 0.011,
      fat: 0.11,
    ),
    FoodItem(
      name: 'Beef',
      caloriesPerUnit: 2.5,
      unit: 'g',
      category: 'Protein',
      protein: 0.26,
      carbs: 0.0,
      fat: 0.17,
    ),
    FoodItem(
      name: 'Fish',
      caloriesPerUnit: 2.06,
      unit: 'g',
      category: 'Protein',
      protein: 0.22,
      carbs: 0.0,
      fat: 0.12,
    ),

    // Vegetables类
    FoodItem(
      name: 'Broccoli',
      caloriesPerUnit: 0.25,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.03,
      carbs: 0.05,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Carrot',
      caloriesPerUnit: 0.41,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.009,
      carbs: 0.10,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Tomato',
      caloriesPerUnit: 0.18,
      unit: 'g',
      category: 'Vegetables',
      protein: 0.009,
      carbs: 0.039,
      fat: 0.002,
    ),

    // Fruits类
    FoodItem(
      name: 'Apple',
      caloriesPerUnit: 0.52,
      unit: 'g',
      category: 'Fruits',
      protein: 0.003,
      carbs: 0.14,
      fat: 0.002,
    ),
    FoodItem(
      name: 'Banana',
      caloriesPerUnit: 0.89,
      unit: 'g',
      category: 'Fruits',
      protein: 0.011,
      carbs: 0.23,
      fat: 0.003,
    ),
    FoodItem(
      name: 'Orange',
      caloriesPerUnit: 0.47,
      unit: 'g',
      category: 'Fruits',
      protein: 0.009,
      carbs: 0.12,
      fat: 0.001,
    ),

    // Snacks类
    FoodItem(
      name: 'Potato Chips',
      caloriesPerUnit: 5.36,
      unit: 'g',
      category: 'Snacks',
      protein: 0.07,
      carbs: 0.53,
      fat: 0.32,
    ),
    FoodItem(
      name: 'Chocolate',
      caloriesPerUnit: 5.46,
      unit: 'g',
      category: 'Snacks',
      protein: 0.049,
      carbs: 0.61,
      fat: 0.31,
    ),

    // Beverages类 (以ml为单位)
    FoodItem(
      name: 'Milk',
      caloriesPerUnit: 0.42,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.034,
      carbs: 0.05,
      fat: 0.01,
    ),
    FoodItem(
      name: 'Cola',
      caloriesPerUnit: 0.42,
      unit: 'ml',
      category: 'Beverages',
      protein: 0.0,
      carbs: 0.106,
      fat: 0.0,
    ),
  ];

  // 获取所有预设食物
  static List<FoodItem> getAllFoods() {
    return List.from(_predefinedFoods);
  }

  // 根据分类获取食物
  static List<FoodItem> getFoodsByCategory(String category) {
    return _predefinedFoods.where((food) => food.category == category).toList();
  }

  // Search食物
  static List<FoodItem> searchFoods(String query) {
    if (query.isEmpty) {
      return getAllFoods();
    }

    return _predefinedFoods
        .where((food) =>
            food.name.toLowerCase().contains(query.toLowerCase()) ||
            food.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // 获取所有分类
  static List<String> getAllCategories() {
    return _predefinedFoods.map((food) => food.category).toSet().toList();
  }

  // 根据ID获取食物
  static FoodItem? getFoodById(int id) {
    try {
      return _predefinedFoods.firstWhere((food) => food.id == id);
    } catch (e) {
      return null;
    }
  }

  // 获取热门食物（前10个）
  static List<FoodItem> getPopularFoods() {
    return _predefinedFoods.take(10).toList();
  }

  // Add自定义食物
  static void addCustomFood(FoodItem food) {
    _predefinedFoods.add(food);
  }

  // 计算指定数量的卡路里
  static double calculateCalories(FoodItem food, double quantity) {
    return food.caloriesPerUnit * quantity;
  }

  // 获取营养信息摘要
  static Map<String, double> getNutritionSummary(
      FoodItem food, double quantity) {
    return {
      'calories': calculateCalories(food, quantity),
      'protein': (food.protein ?? 0) * quantity,
      'carbs': (food.carbs ?? 0) * quantity,
      'fat': (food.fat ?? 0) * quantity,
    };
  }

  // 获取推荐食用量（基于常见份量）
  static double getRecommendedServing(FoodItem food) {
    switch (food.category) {
      case 'Staple Food':
        return 150.0; // 150g
      case 'Protein':
        return 100.0; // 100g
      case 'Vegetables':
        return 200.0; // 200g
      case 'Fruits':
        return 150.0; // 150g
      case 'Snacks':
        return 30.0; // 30g
      case 'Beverages':
        return 250.0; // 250ml
      default:
        return 100.0;
    }
  }

  // 获取单位显示文本
  static String getUnitDisplayText(String unit) {
    switch (unit) {
      case 'g':
        return '克';
      case 'ml':
        return '毫升';
      default:
        return unit;
    }
  }
}

