// lib/models/health_goal.dart
import 'package:flutter/material.dart';

enum HealthGoalType {
  weightLoss,
  weightGain,
  muscleGain,
  maintenance,
  healthyEating,
  energyBoost,
}

enum GoalDifficulty {
  easy, // 0.5 kg/week
  moderate, // 0.7 kg/week
  hard, // 1.0 kg/week
}

class HealthGoal {
  final int? id;
  final String name;
  final HealthGoalType type;
  final double targetValue; // Target weight, muscle mass, etc.
  final double currentValue; // Current progress
  final DateTime startDate;
  final DateTime targetDate;
  final GoalDifficulty difficulty;
  final Map<String, dynamic>
      customSettings; // Additional goal-specific settings
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthGoal({
    this.id,
    required this.name,
    required this.type,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.targetDate,
    required this.difficulty,
    this.customSettings = const {},
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculate progress percentage
  double get progressPercentage {
    if (type == HealthGoalType.weightLoss) {
      final totalLoss = currentValue - targetValue;
      final currentLoss =
          currentValue - (customSettings['startWeight'] ?? currentValue);
      return totalLoss != 0 ? (currentLoss / totalLoss * 100).clamp(0, 100) : 0;
    } else if (type == HealthGoalType.weightGain ||
        type == HealthGoalType.muscleGain) {
      final totalGain = targetValue - currentValue;
      final currentGain =
          (customSettings['currentWeight'] ?? currentValue) - currentValue;
      return totalGain != 0 ? (currentGain / totalGain * 100).clamp(0, 100) : 0;
    }
    return 0;
  }

  // Calculate remaining days
  int get remainingDays {
    final now = DateTime.now();
    final remaining = targetDate.difference(now).inDays;
    return remaining > 0 ? remaining : 0;
  }

  // Calculate total duration in days
  int get totalDays {
    return targetDate.difference(startDate).inDays;
  }

  // Get recommended daily calorie adjustment
  double get recommendedCalorieAdjustment {
    switch (type) {
      case HealthGoalType.weightLoss:
        switch (difficulty) {
          case GoalDifficulty.easy:
            return -250; // 0.25kg per week ≈ 250 cal deficit
          case GoalDifficulty.moderate:
            return -400; // 0.4kg per week ≈ 400 cal deficit
          case GoalDifficulty.hard:
            return -550; // 0.55kg per week ≈ 550 cal deficit
        }
      case HealthGoalType.weightGain:
      case HealthGoalType.muscleGain:
        switch (difficulty) {
          case GoalDifficulty.easy:
            return 250;
          case GoalDifficulty.moderate:
            return 400;
          case GoalDifficulty.hard:
            return 550;
        }
      case HealthGoalType.maintenance:
      case HealthGoalType.healthyEating:
      case HealthGoalType.energyBoost:
        return 0;
    }
  }

  // Get goal description
  String get description {
    switch (type) {
      case HealthGoalType.weightLoss:
        return 'Lose ${(currentValue - targetValue).abs().toStringAsFixed(1)} kg in ${totalDays} days';
      case HealthGoalType.weightGain:
        return 'Gain ${(targetValue - currentValue).abs().toStringAsFixed(1)} kg in ${totalDays} days';
      case HealthGoalType.muscleGain:
        return 'Build muscle and gain ${(targetValue - currentValue).abs().toStringAsFixed(1)} kg in ${totalDays} days';
      case HealthGoalType.maintenance:
        return 'Maintain current weight and develop healthy eating habits';
      case HealthGoalType.healthyEating:
        return 'Develop balanced nutrition habits for better health';
      case HealthGoalType.energyBoost:
        return 'Optimize nutrition for sustained energy throughout the day';
    }
  }

  // Get goal color
  Color get color {
    switch (type) {
      case HealthGoalType.weightLoss:
        return Colors.red;
      case HealthGoalType.weightGain:
        return Colors.green;
      case HealthGoalType.muscleGain:
        return Colors.blue;
      case HealthGoalType.maintenance:
        return Colors.orange;
      case HealthGoalType.healthyEating:
        return Colors.purple;
      case HealthGoalType.energyBoost:
        return Colors.amber;
    }
  }

  // Get goal icon
  IconData get icon {
    switch (type) {
      case HealthGoalType.weightLoss:
        return Icons.trending_down;
      case HealthGoalType.weightGain:
        return Icons.trending_up;
      case HealthGoalType.muscleGain:
        return Icons.fitness_center;
      case HealthGoalType.maintenance:
        return Icons.balance;
      case HealthGoalType.healthyEating:
        return Icons.restaurant_menu;
      case HealthGoalType.energyBoost:
        return Icons.bolt;
    }
  }

  // Check if goal is achievable
  bool get isRealistic {
    final weeksAvailable = remainingDays / 7;
    final targetChangePerWeek =
        (targetValue - currentValue).abs() / weeksAvailable;

    // Generally, losing/gaining more than 1kg per week is not recommended
    return targetChangePerWeek <= 1.0;
  }

  // Get personalized nutrition recommendations
  List<String> get nutritionRecommendations {
    switch (type) {
      case HealthGoalType.weightLoss:
        return [
          'Focus on protein-rich foods to maintain muscle mass',
          'Include plenty of vegetables for fiber and nutrients',
          'Choose whole grains over refined carbohydrates',
          'Stay hydrated and limit sugary drinks',
          'Control portion sizes and eat slowly',
        ];
      case HealthGoalType.weightGain:
        return [
          'Increase healthy calorie intake with nuts and seeds',
          'Add protein shakes or smoothies between meals',
          'Choose nutrient-dense, calorie-rich foods',
          'Eat frequent, smaller meals throughout the day',
          'Include healthy fats like avocado and olive oil',
        ];
      case HealthGoalType.muscleGain:
        return [
          'Consume 1.6-2.2g protein per kg body weight',
          'Time protein intake around workouts',
          'Include complex carbohydrates for energy',
          'Stay hydrated, especially during workouts',
          'Consider creatine supplementation if appropriate',
        ];
      case HealthGoalType.maintenance:
        return [
          'Focus on balanced meals with all food groups',
          'Practice mindful eating and portion control',
          'Stay consistent with meal timing',
          'Allow flexibility for occasional treats',
          'Monitor weight regularly but don\'t obsess',
        ];
      case HealthGoalType.healthyEating:
        return [
          'Eat a variety of colorful fruits and vegetables',
          'Choose lean proteins and whole grains',
          'Limit processed foods and added sugars',
          'Cook more meals at home',
          'Read nutrition labels and ingredients',
        ];
      case HealthGoalType.energyBoost:
        return [
          'Eat regular, balanced meals to maintain blood sugar',
          'Include complex carbohydrates for sustained energy',
          'Stay hydrated throughout the day',
          'Limit caffeine and avoid energy crashes',
          'Include iron-rich foods to prevent fatigue',
        ];
    }
  }

  // Copy with method
  HealthGoal copyWith({
    int? id,
    String? name,
    HealthGoalType? type,
    double? targetValue,
    double? currentValue,
    DateTime? startDate,
    DateTime? targetDate,
    GoalDifficulty? difficulty,
    Map<String, dynamic>? customSettings,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      startDate: startDate ?? this.startDate,
      targetDate: targetDate ?? this.targetDate,
      difficulty: difficulty ?? this.difficulty,
      customSettings: customSettings ?? this.customSettings,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.index,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'startDate': startDate.millisecondsSinceEpoch,
      'targetDate': targetDate.millisecondsSinceEpoch,
      'difficulty': difficulty.index,
      'customSettings': customSettings,
      'isActive': isActive ? 1 : 0,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create from Map
  factory HealthGoal.fromMap(Map<String, dynamic> map) {
    return HealthGoal(
      id: map['id'],
      name: map['name'],
      type: HealthGoalType.values[map['type']],
      targetValue: map['targetValue'].toDouble(),
      currentValue: map['currentValue'].toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate']),
      difficulty: GoalDifficulty.values[map['difficulty']],
      customSettings: Map<String, dynamic>.from(map['customSettings'] ?? {}),
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}

// Progress tracking model
class GoalProgress {
  final int? id;
  final int goalId;
  final double value; // Current weight, measurement, etc.
  final double caloriesConsumed;
  final String notes;
  final DateTime recordDate;
  final DateTime createdAt;

  GoalProgress({
    this.id,
    required this.goalId,
    required this.value,
    required this.caloriesConsumed,
    this.notes = '',
    required this.recordDate,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goalId': goalId,
      'value': value,
      'caloriesConsumed': caloriesConsumed,
      'notes': notes,
      'recordDate': recordDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory GoalProgress.fromMap(Map<String, dynamic> map) {
    return GoalProgress(
      id: map['id'],
      goalId: map['goalId'],
      value: map['value'].toDouble(),
      caloriesConsumed: map['caloriesConsumed'].toDouble(),
      notes: map['notes'] ?? '',
      recordDate: DateTime.fromMillisecondsSinceEpoch(map['recordDate']),
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
