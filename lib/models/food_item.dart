// lib/models/food_item.dart
import 'package:flutter/material.dart';

class FoodItem {
  final int? id;
  final String name;
  final double caloriesPerUnit; // 每单位卡路里
  final String unit; // 单位（如：100g, 1个, 1杯）
  final String category; // 食物分类
  final double? protein; // 蛋白质(g)
  final double? carbs; // 碳水化合物(g)
  final double? fat; // 脂肪(g)
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

  // 转换为Map（用于数据库存储）
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

  // 从Map创建FoodItem
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

  // 复制方法
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

// 食物记录模型（用户每次添加的食物记录）
class FoodRecord {
  final int? id;
  final int foodItemId; // 关联的食物ID
  final FoodItem? foodItem; // 食物详情
  final double quantity; // 数量
  final double totalCalories; // 总卡路里
  final String mealType; // 餐次：breakfast, lunch, dinner, snack
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

  // 获取格式化的日期（用于分组）
  DateTime get date =>
      DateTime(recordedAt.year, recordedAt.month, recordedAt.day);

  // 转换为Map
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

  // 从Map创建FoodRecord
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

  // 复制方法
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

// 每日卡路里数据模型（用于历史记录和图表）
class DailyCalorieData {
  final DateTime date;
  final double totalCalories;
  final int foodCount;
  final Map<String, double> mealBreakdown; // 各餐次卡路里分布
  final Map<String, int> mealCounts; // 各餐次食物数量

  DailyCalorieData({
    required this.date,
    required this.totalCalories,
    required this.foodCount,
    required this.mealBreakdown,
    required this.mealCounts,
  });

  // 从食物记录列表创建每日数据
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

  // 获取主要餐次（卡路里最多的餐次）
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

  // 获取平均每餐卡路里
  double get averageCaloriesPerMeal {
    final activeMeals =
        mealBreakdown.values.where((calories) => calories > 0).length;
    return activeMeals > 0 ? totalCalories / activeMeals : 0;
  }

  // 检查是否是活跃日（有食物记录）
  bool get isActiveDay => foodCount > 0;

  // 转换为Map（用于数据库或JSON）
  Map<String, dynamic> toMap() {
    return {
      'date': date.millisecondsSinceEpoch,
      'totalCalories': totalCalories,
      'foodCount': foodCount,
      'mealBreakdown': mealBreakdown,
      'mealCounts': mealCounts,
    };
  }

  // 从Map创建DailyCalorieData
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

// 营养统计数据模型
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

  // 获取蛋白质卡路里百分比
  double get proteinPercentage {
    if (totalCalories == 0) return 0;
    return (totalProtein * 4) / totalCalories * 100; // 蛋白质每克4卡路里
  }

  // 获取碳水化合物卡路里百分比
  double get carbsPercentage {
    if (totalCalories == 0) return 0;
    return (totalCarbs * 4) / totalCalories * 100; // 碳水每克4卡路里
  }

  // 获取脂肪卡路里百分比
  double get fatPercentage {
    if (totalCalories == 0) return 0;
    return (totalFat * 9) / totalCalories * 100; // 脂肪每克9卡路里
  }

  // 检查营养比例是否健康
  bool get isHealthyBalance {
    return proteinPercentage >= 10 &&
        proteinPercentage <= 35 &&
        carbsPercentage >= 45 &&
        carbsPercentage <= 65 &&
        fatPercentage >= 20 &&
        fatPercentage <= 35;
  }

  // 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'date': date.millisecondsSinceEpoch,
    };
  }

  // 从Map创建NutritionStats
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

// 目标达成统计模型
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

  // 达成率百分比
  double get achievementRate {
    return totalDays > 0 ? (achievedDays / totalDays) * 100 : 0;
  }

  // 平均与目标的差距
  double get averageGap {
    return averageCalories - targetCalories;
  }

  // 获取达成等级
  String get achievementLevel {
    if (achievementRate >= 90) return '优秀';
    if (achievementRate >= 70) return '良好';
    if (achievementRate >= 50) return '一般';
    return '需要努力';
  }

  // 获取达成等级颜色
  Color get achievementColor {
    if (achievementRate >= 90) return Colors.green;
    if (achievementRate >= 70) return Colors.blue;
    if (achievementRate >= 50) return Colors.orange;
    return Colors.red;
  }
}
