// lib/models/food_item.dart
import 'package:flutter/material.dart';

class FoodItem {
  final int? id;
  final String name;
  final double caloriesPerUnit; // Calories per unit
  final String unit; // Unit (e.g., 100g, 1 piece, 1 cup)
  final String category; // Food category
  final double? protein; // Protein(g)
  final double? carbs; // Carbohydrates(g)
  final double? fat; // Fat(g)
  final DateTime createdAt;

  FoodItem({
    this.id,
    required this.name,
    required this.caloriesPerUnit,
    required this.unit,
    required this.category,
    this.protein,
    this.carbs,
    this.fat,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Convert to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'caloriesPerUnit': caloriesPerUnit,
      'unit': unit,
      'category': category,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  // Create FoodItem from Map
  factory FoodItem.fromMap(Map<String, dynamic> map) {
    return FoodItem(
      id: map['id'],
      name: map['name'],
      caloriesPerUnit: map['caloriesPerUnit'],
      unit: map['unit'],
      category: map['category'],
      protein: map['protein'],
      carbs: map['carbs'],
      fat: map['fat'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }

  // Copy method
  FoodItem copyWith({
    int? id,
    String? name,
    double? caloriesPerUnit,
    String? unit,
    String? category,
    double? protein,
    double? carbs,
    double? fat,
    DateTime? createdAt,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      caloriesPerUnit: caloriesPerUnit ?? this.caloriesPerUnit,
      unit: unit ?? this.unit,
      category: category ?? this.category,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

// Food record model (user's food record for each entry)
class FoodRecord {
  final int? id;
  final int foodItemId; // Associated food ID
  final FoodItem? foodItem; // Food details
  final double quantity; // Quantity
  final double totalCalories; // Total calories
  final String mealType; // Meal type: breakfast, lunch, dinner, snack
  final DateTime recordedAt;

  FoodRecord({
    this.id,
    required this.foodItemId,
    this.foodItem,
    required this.quantity,
    required this.totalCalories,
    required this.mealType,
    DateTime? recordedAt,
  }) : recordedAt = recordedAt ?? DateTime.now();

  // Get formatted date (for grouping)
  DateTime get date =>
      DateTime(recordedAt.year, recordedAt.month, recordedAt.day);

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'foodItemId': foodItemId,
      'quantity': quantity,
      'totalCalories': totalCalories,
      'mealType': mealType,
      'recordedAt': recordedAt.millisecondsSinceEpoch,
    };
  }

  // Create FoodRecord from Map
  factory FoodRecord.fromMap(Map<String, dynamic> map, {FoodItem? foodItem}) {
    return FoodRecord(
      id: map['id'],
      foodItemId: map['foodItemId'],
      foodItem: foodItem,
      quantity: map['quantity'],
      totalCalories: map['totalCalories'],
      mealType: map['mealType'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt']),
    );
  }

  // Copy method
  FoodRecord copyWith({
    int? id,
    int? foodItemId,
    FoodItem? foodItem,
    double? quantity,
    double? totalCalories,
    String? mealType,
    DateTime? recordedAt,
  }) {
    return FoodRecord(
      id: id ?? this.id,
      foodItemId: foodItemId ?? this.foodItemId,
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      totalCalories: totalCalories ?? this.totalCalories,
      mealType: mealType ?? this.mealType,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }
}

// Daily calorie data model (for history records and charts)
class DailyCalorieData {
  final DateTime date;
  final double totalCalories;
  final int foodCount;
  final Map<String, double> mealBreakdown; // Calorie distribution by meal
  final Map<String, int> mealCounts; // Food count by meal

  DailyCalorieData({
    required this.date,
    required this.totalCalories,
    required this.foodCount,
    required this.mealBreakdown,
    required this.mealCounts,
  });

  // Create daily data from food records list
  factory DailyCalorieData.fromFoodRecords(
      DateTime date, List<FoodRecord> records) {
    double totalCalories = 0;
    Map<String, double> mealBreakdown = {
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'snack': 0,
    };
    Map<String, int> mealCounts = {
      'breakfast': 0,
      'lunch': 0,
      'dinner': 0,
      'snack': 0,
    };

    for (var record in records) {
      totalCalories += record.totalCalories;
      mealBreakdown[record.mealType] =
          (mealBreakdown[record.mealType] ?? 0) + record.totalCalories;
      mealCounts[record.mealType] = (mealCounts[record.mealType] ?? 0) + 1;
    }

    return DailyCalorieData(
      date: date,
      totalCalories: totalCalories,
      foodCount: records.length,
      mealBreakdown: mealBreakdown,
      mealCounts: mealCounts,
    );
  }

  // Get primary meal (meal with most calories)
  String get primaryMeal {
    String primary = 'breakfast';
    double maxCalories = 0;

    mealBreakdown.forEach((meal, calories) {
      if (calories > maxCalories) {
        maxCalories = calories;
        primary = meal;
      }
    });

    return primary;
  }

  // Get average calories per meal
  double get averageCaloriesPerMeal {
    final activeMeals =
        mealBreakdown.values.where((calories) => calories > 0).length;
    return activeMeals > 0 ? totalCalories / activeMeals : 0;
  }

  // Check if it's an active day (has food records)
  bool get isActiveDay => foodCount > 0;

  // Convert to Map (for database or JSON)
  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'totalCalories': totalCalories,
      'foodCount': foodCount,
      'mealBreakdown': mealBreakdown,
      'mealCounts': mealCounts,
    };
  }

  // Create DailyCalorieData from Map
  factory DailyCalorieData.fromMap(Map<String, dynamic> map) {
    return DailyCalorieData(
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
      totalCalories: map['totalCalories'].toDouble(),
      foodCount: map['foodCount'],
      mealBreakdown: Map<String, double>.from(map['mealBreakdown']),
      mealCounts: Map<String, int>.from(map['mealCounts']),
    );
  }
}

// Nutrition statistics data model
class NutritionStats {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final DateTime date;

  NutritionStats({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.date,
  });

  // Get protein calorie percentage
  double get proteinPercentage {
    if (totalCalories == 0) return 0;
    return (totalProtein * 4) /
        totalCalories *
        100; // Protein 4 calories per gram
  }

  // Get carbohydrate calorie percentage
  double get carbsPercentage {
    if (totalCalories == 0) return 0;
    return (totalCarbs * 4) / totalCalories * 100; // Carbs 4 calories per gram
  }

  // Get fat calorie percentage
  double get fatPercentage {
    if (totalCalories == 0) return 0;
    return (totalFat * 9) / totalCalories * 100; // Fat 9 calories per gram
  }

  // Check if nutrition ratio is healthy
  bool get isHealthyBalance {
    return proteinPercentage >= 10 &&
        proteinPercentage <= 35 &&
        carbsPercentage >= 45 &&
        carbsPercentage <= 65 &&
        fatPercentage >= 20 &&
        fatPercentage <= 35;
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'date': date.millisecondsSinceEpoch,
    };
  }

  // Create NutritionStats from Map
  factory NutritionStats.fromMap(Map<String, dynamic> map) {
    return NutritionStats(
      totalCalories: map['totalCalories'].toDouble(),
      totalProtein: map['totalProtein'].toDouble(),
      totalCarbs: map['totalCarbs'].toDouble(),
      totalFat: map['totalFat'].toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date']),
    );
  }
}

// Goal achievement statistics model
class GoalAchievementStats {
  final int totalDays;
  final int achievedDays;
  final double averageCalories;
  final double bestDayCalories;
  final double worstDayCalories;
  final double targetCalories;

  GoalAchievementStats({
    required this.totalDays,
    required this.achievedDays,
    required this.averageCalories,
    required this.bestDayCalories,
    required this.worstDayCalories,
    required this.targetCalories,
  });

  // Achievement rate percentage
  double get achievementRate {
    return totalDays > 0 ? (achievedDays / totalDays) * 100 : 0;
  }

  // Average gap from target
  double get averageGap {
    return averageCalories - targetCalories;
  }

  // Get achievement level
  String get achievementLevel {
    if (achievementRate >= 90) return 'Excellent';
    if (achievementRate >= 70) return 'Good';
    if (achievementRate >= 50) return 'Average';
    return 'Needs Improvement';
  }

  // Get achievement level color
  Color get achievementColor {
    if (achievementRate >= 90) return Colors.green;
    if (achievementRate >= 70) return Colors.blue;
    if (achievementRate >= 50) return Colors.orange;
    return Colors.red;
  }
}
