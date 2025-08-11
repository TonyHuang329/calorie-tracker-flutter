// lib/services/health_goal_service.dart
import '../models/health_goal.dart';
import '../models/user_profile.dart';
import 'database_service.dart';

class HealthGoalService {
  static HealthGoalService? _instance;
  static HealthGoalService get instance => _instance ??= HealthGoalService._();
  HealthGoalService._();

  // ===== Health Goal CRUD Operations (delegated to DatabaseService) =====

  // Create a new health goal
  Future<int> createHealthGoal(HealthGoal goal) async {
    return await DatabaseService.createHealthGoal(goal);
  }

  // Get all health goals
  Future<List<HealthGoal>> getAllHealthGoals() async {
    return await DatabaseService.getAllHealthGoals();
  }

  // Get active health goals
  Future<List<HealthGoal>> getActiveHealthGoals() async {
    return await DatabaseService.getActiveHealthGoals();
  }

  // Get health goal by ID
  Future<HealthGoal?> getHealthGoalById(int id) async {
    return await DatabaseService.getHealthGoalById(id);
  }

  // Update health goal
  Future<int> updateHealthGoal(HealthGoal goal) async {
    return await DatabaseService.updateHealthGoal(goal);
  }

  // Delete health goal
  Future<int> deleteHealthGoal(int id) async {
    return await DatabaseService.deleteHealthGoal(id);
  }

  // Deactivate health goal (soft delete)
  Future<int> deactivateHealthGoal(int id) async {
    return await DatabaseService.deactivateHealthGoal(id);
  }

  // ===== Progress Tracking =====

  // Add progress entry
  Future<int> addProgressEntry(GoalProgress progress) async {
    final result = await DatabaseService.addGoalProgress(progress);

    // Update the goal's current value
    await DatabaseService.updateGoalCurrentValue(
        progress.goalId, progress.value);

    return result;
  }

  // Get progress entries for a goal
  Future<List<GoalProgress>> getGoalProgress(int goalId,
      {int? limitDays}) async {
    return await DatabaseService.getGoalProgress(goalId, limitDays: limitDays);
  }

  // Get latest progress for a goal
  Future<GoalProgress?> getLatestProgress(int goalId) async {
    return await DatabaseService.getLatestGoalProgress(goalId);
  }

  // Get goal progress analytics
  Future<Map<String, dynamic>> getGoalProgressAnalytics(int goalId) async {
    return await DatabaseService.getGoalProgressAnalytics(goalId);
  }

  // ===== Smart Recommendations =====

  // Get personalized goal recommendations based on user profile
  List<Map<String, dynamic>> getGoalRecommendations(UserProfile user) {
    final recommendations = <Map<String, dynamic>>[];
    final currentBMI = _calculateBMI(user.weight, user.height);

    // BMI-based recommendations
    if (currentBMI < 18.5) {
      recommendations.add({
        'type': HealthGoalType.weightGain,
        'title': 'Healthy Weight Gain',
        'description':
            'Your BMI indicates you might benefit from gaining weight in a healthy way',
        'priority': 'high',
        'targetWeight':
            _calculateHealthyWeight(user.height, 21), // Target BMI 21
        'reason': 'Current BMI: ${currentBMI.toStringAsFixed(1)} (Underweight)',
      });
    } else if (currentBMI > 25) {
      recommendations.add({
        'type': HealthGoalType.weightLoss,
        'title': 'Gradual Weight Loss',
        'description': 'A gradual approach to reach a healthier weight range',
        'priority': 'high',
        'targetWeight':
            _calculateHealthyWeight(user.height, 22), // Target BMI 22
        'reason': 'Current BMI: ${currentBMI.toStringAsFixed(1)} (Overweight)',
      });
    } else {
      recommendations.add({
        'type': HealthGoalType.maintenance,
        'title': 'Weight Maintenance',
        'description':
            'Maintain your healthy weight while building good habits',
        'priority': 'medium',
        'targetWeight': user.weight,
        'reason':
            'Current BMI: ${currentBMI.toStringAsFixed(1)} (Healthy range)',
      });
    }

    // Age-based recommendations
    if (user.age >= 30) {
      recommendations.add({
        'type': HealthGoalType.muscleGain,
        'title': 'Muscle Preservation',
        'description': 'Maintain muscle mass and strength as you age',
        'priority': 'medium',
        'targetWeight': user.weight + 2,
        'reason': 'Age ${user.age}: Muscle mass naturally declines after 30',
      });
    }

    if (user.age >= 50) {
      recommendations.add({
        'type': HealthGoalType.energyBoost,
        'title': 'Energy & Vitality',
        'description': 'Optimize nutrition for sustained energy and health',
        'priority': 'high',
        'targetWeight': user.weight,
        'reason': 'Age ${user.age}: Focus on energy and overall health',
      });
    }

    // Activity level recommendations
    if (user.activityLevel == 'sedentary') {
      recommendations.add({
        'type': HealthGoalType.energyBoost,
        'title': 'Energy Enhancement',
        'description': 'Improve energy levels through better nutrition',
        'priority': 'medium',
        'targetWeight': user.weight,
        'reason':
            'Sedentary lifestyle may benefit from energy-focused nutrition',
      });
    } else if (user.activityLevel == 'very_active') {
      recommendations.add({
        'type': HealthGoalType.muscleGain,
        'title': 'Performance Optimization',
        'description': 'Support your active lifestyle with muscle building',
        'priority': 'medium',
        'targetWeight': user.weight + 3,
        'reason': 'High activity level supports muscle building goals',
      });
    }

    // General health recommendation
    recommendations.add({
      'type': HealthGoalType.healthyEating,
      'title': 'Balanced Nutrition',
      'description': 'Develop long-term healthy eating patterns',
      'priority': 'low',
      'targetWeight': user.weight,
      'reason': 'Good nutrition habits benefit everyone',
    });

    // Sort by priority and limit results
    recommendations.sort((a, b) {
      final priorityOrder = {'high': 3, 'medium': 2, 'low': 1};
      return (priorityOrder[b['priority']] ?? 0) -
          (priorityOrder[a['priority']] ?? 0);
    });

    return recommendations.take(4).toList();
  }

  // Calculate recommended timeline for a goal
  Map<String, dynamic> calculateRecommendedTimeline(
    HealthGoalType type,
    double currentWeight,
    double targetWeight,
    GoalDifficulty difficulty,
  ) {
    final weightChange = (targetWeight - currentWeight).abs();
    double weeklyRate;

    // Determine safe weekly weight change rate based on difficulty
    switch (difficulty) {
      case GoalDifficulty.easy:
        weeklyRate = 0.25; // 0.25 kg per week
        break;
      case GoalDifficulty.moderate:
        weeklyRate = 0.5; // 0.5 kg per week
        break;
      case GoalDifficulty.hard:
        weeklyRate = 0.75; // 0.75 kg per week
        break;
    }

    // For maintenance and non-weight goals, use different timeline
    if (type == HealthGoalType.maintenance ||
        type == HealthGoalType.healthyEating ||
        type == HealthGoalType.energyBoost) {
      final weeks = difficulty == GoalDifficulty.easy
          ? 12
          : difficulty == GoalDifficulty.moderate
              ? 8
              : 6;
      return {
        'weeks': weeks,
        'days': weeks * 7,
        'weeklyRate': 0.0,
        'isRealistic': true,
        'difficultyDescription': _getDifficultyDescription(difficulty),
        'estimatedCompletion': DateTime.now().add(Duration(days: weeks * 7)),
      };
    }

    final recommendedWeeks =
        weightChange > 0 ? (weightChange / weeklyRate).ceil() : 4;
    final recommendedDays = recommendedWeeks * 7;

    // Check if timeline is realistic (max 1kg per week is generally safe)
    final isRealistic = weeklyRate <= 1.0 && recommendedWeeks >= 4;

    return {
      'weeks': recommendedWeeks,
      'days': recommendedDays,
      'weeklyRate': weeklyRate,
      'isRealistic': isRealistic,
      'difficultyDescription': _getDifficultyDescription(difficulty),
      'estimatedCompletion':
          DateTime.now().add(Duration(days: recommendedDays)),
      'safetyWarning': !isRealistic
          ? 'This timeline may be too aggressive for safe weight change'
          : null,
    };
  }

  // Get adjusted daily calorie target based on active goals
  Future<double> getAdjustedCalorieTarget(UserProfile user) async {
    final baseTDEE = user.calculateTDEE();
    return await DatabaseService.getAdjustedCalorieTarget(baseTDEE);
  }

  // Get daily nutrition targets based on goals
  Future<Map<String, double>> getDailyNutritionTargets(UserProfile user) async {
    final activeGoals = await getActiveHealthGoals();
    final adjustedCalories = await getAdjustedCalorieTarget(user);

    if (activeGoals.isEmpty) {
      return _getStandardNutritionTargets(adjustedCalories, user.weight);
    }

    final primaryGoal = activeGoals.first;
    return _getGoalSpecificNutritionTargets(
        primaryGoal, adjustedCalories, user.weight);
  }

  // ===== Goal Management Utilities =====

  // Check if a goal can be completed
  Future<bool> canCompleteGoal(int goalId) async {
    final goal = await getHealthGoalById(goalId);
    if (goal == null) return false;

    // For weight-related goals, check if target is reached
    if (goal.type == HealthGoalType.weightLoss ||
        goal.type == HealthGoalType.weightGain ||
        goal.type == HealthGoalType.muscleGain) {
      final latestProgress = await getLatestProgress(goalId);
      if (latestProgress != null) {
        final targetReached = goal.type == HealthGoalType.weightLoss
            ? latestProgress.value <= goal.targetValue
            : latestProgress.value >= goal.targetValue;
        return targetReached;
      }
    }

    // For time-based goals, check if enough time has passed
    final daysPassed = DateTime.now().difference(goal.startDate).inDays;
    final minDaysForCompletion = goal.totalDays * 0.8; // 80% of timeline

    return daysPassed >= minDaysForCompletion;
  }

  // Mark goal as completed
  Future<bool> completeGoal(int goalId) async {
    final canComplete = await canCompleteGoal(goalId);
    if (!canComplete) return false;

    await deactivateHealthGoal(goalId);
    return true;
  }

  // Get goal completion suggestions
  Future<List<String>> getGoalCompletionSuggestions(int goalId) async {
    final goal = await getHealthGoalById(goalId);
    if (goal == null) return [];

    final analytics = await getGoalProgressAnalytics(goalId);
    final suggestions = <String>[];

    // Consistency suggestions
    final consistency = analytics['consistencyScore'] as double? ?? 0.0;
    if (consistency < 0.7) {
      suggestions
          .add('Try to log your progress more regularly for better tracking');
    }

    // Progress trend suggestions
    final trend = analytics['trend'] as String? ?? 'stable';
    switch (trend) {
      case 'declining':
        suggestions.add(
            'Your progress has been declining. Consider adjusting your approach');
        break;
      case 'stable':
        suggestions.add(
            'Your progress is stable. Consider increasing intensity if appropriate');
        break;
      case 'improving':
        suggestions.add('Great job! Your progress is improving consistently');
        break;
    }

    // Goal-specific suggestions
    switch (goal.type) {
      case HealthGoalType.weightLoss:
        suggestions.addAll([
          'Focus on creating a moderate calorie deficit',
          'Include both cardio and strength training',
          'Stay hydrated and get adequate sleep',
        ]);
        break;
      case HealthGoalType.weightGain:
        suggestions.addAll([
          'Eat frequent, nutrient-dense meals',
          'Include healthy fats and complex carbs',
          'Consider strength training to build muscle',
        ]);
        break;
      case HealthGoalType.muscleGain:
        suggestions.addAll([
          'Ensure adequate protein intake (1.6-2.2g per kg)',
          'Progressive resistance training is key',
          'Allow adequate rest between workouts',
        ]);
        break;
      default:
        suggestions.add('Stay consistent with your healthy habits');
    }

    return suggestions.take(3).toList();
  }

  // ===== Helper Methods =====

  double _calculateBMI(double weight, double height) {
    final heightInMeters = height / 100;
    return weight / (heightInMeters * heightInMeters);
  }

  double _calculateHealthyWeight(double height, double targetBMI) {
    final heightInMeters = height / 100;
    return targetBMI * (heightInMeters * heightInMeters);
  }

  String _getDifficultyDescription(GoalDifficulty difficulty) {
    switch (difficulty) {
      case GoalDifficulty.easy:
        return 'Gentle pace - sustainable and comfortable approach';
      case GoalDifficulty.moderate:
        return 'Balanced approach - steady progress with manageable changes';
      case GoalDifficulty.hard:
        return 'Intensive approach - requires strong commitment and discipline';
    }
  }

  Map<String, double> _getStandardNutritionTargets(
      double calories, double weight) {
    return {
      'calories': calories,
      'protein': weight * 1.2, // 1.2g per kg body weight
      'carbs': calories * 0.5 / 4, // 50% from carbs
      'fat': calories * 0.3 / 9, // 30% from fat
      'fiber': 25.0, // 25g daily
      'water': weight * 35, // 35ml per kg body weight
    };
  }

  Map<String, double> _getGoalSpecificNutritionTargets(
    HealthGoal goal,
    double calories,
    double weight,
  ) {
    final base = _getStandardNutritionTargets(calories, weight);

    switch (goal.type) {
      case HealthGoalType.weightLoss:
        return {
          ...base,
          'protein': weight * 1.4, // Higher protein to preserve muscle
          'fiber': 30.0, // Higher fiber for satiety
          'carbs': calories * 0.45 / 4, // Slightly lower carbs
        };

      case HealthGoalType.weightGain:
      case HealthGoalType.muscleGain:
        return {
          ...base,
          'protein': weight * 1.8, // Higher protein for muscle building
          'carbs': calories * 0.55 / 4, // More carbs for energy
          'fat': calories * 0.35 / 9, // Slightly more healthy fats
        };

      case HealthGoalType.energyBoost:
        return {
          ...base,
          'carbs': calories * 0.55 / 4, // More complex carbs for energy
          'water': weight * 40, // Extra hydration for energy
          'fiber': 28.0, // Good fiber for sustained energy
        };

      case HealthGoalType.healthyEating:
        return {
          ...base,
          'fiber': 35.0, // High fiber for digestive health
          'protein': weight * 1.3, // Adequate protein
          'water': weight * 38, // Good hydration
        };

      default:
        return base;
    }
  }

  // ===== Integration with Food Tracking =====

  // Analyze today's food intake against goal requirements
  Future<Map<String, dynamic>> analyzeTodayIntakeForGoals(
      UserProfile user) async {
    final todayRecords = await DatabaseService.getTodayFoodRecords();
    final activeGoals = await getActiveHealthGoals();
    final todayNutrition =
        await DatabaseService.getNutritionStatistics(DateTime.now());
    final nutritionTargets = await getDailyNutritionTargets(user);

    final analysis = <String, dynamic>{
      'calorieStatus': 'on_track',
      'proteinStatus': 'on_track',
      'goalAlignment': 'good',
      'suggestions': <String>[],
      'achievements': <String>[],
    };

    // Calorie analysis
    final calorieRatio =
        todayNutrition.totalCalories / nutritionTargets['calories']!;
    if (calorieRatio < 0.8) {
      analysis['calorieStatus'] = 'under';
      final suggestions = analysis['suggestions'] as List<String>;
      suggestions.add('You may need more calories to meet your goal');
    } else if (calorieRatio > 1.2) {
      analysis['calorieStatus'] = 'over';
      final suggestions = analysis['suggestions'] as List<String>;
      suggestions.add('Consider reducing portion sizes to stay on track');
    }

    // Protein analysis
    final proteinRatio =
        todayNutrition.totalProtein / nutritionTargets['protein']!;
    if (proteinRatio < 0.8) {
      analysis['proteinStatus'] = 'under';
      final suggestions = analysis['suggestions'] as List<String>;
      suggestions.add('Add more protein-rich foods to support your goal');
    } else if (proteinRatio >= 1.0) {
      final achievements = analysis['achievements'] as List<String>;
      achievements.add('Great protein intake today!');
    }

    // Goal-specific analysis
    if (activeGoals.isNotEmpty) {
      final primaryGoal = activeGoals.first;
      final achievements = analysis['achievements'] as List<String>;
      switch (primaryGoal.type) {
        case HealthGoalType.weightLoss:
          if (calorieRatio <= 1.0) {
            achievements.add('Staying within calorie deficit!');
          }
          break;
        case HealthGoalType.muscleGain:
          if (proteinRatio >= 1.0 && calorieRatio >= 1.0) {
            achievements.add('Perfect nutrition for muscle building!');
          }
          break;
        default:
          break;
      }
    }

    return analysis;
  }

  // Get food recommendations based on active goals
  Future<List<String>> getFoodRecommendationsForGoals() async {
    final activeGoals = await getActiveHealthGoals();
    if (activeGoals.isEmpty) return [];

    final primaryGoal = activeGoals.first;

    switch (primaryGoal.type) {
      case HealthGoalType.weightLoss:
        return [
          'Grilled chicken breast - high protein, low calories',
          'Leafy greens - high fiber, very low calories',
          'Greek yogurt - protein-rich and satisfying',
        ];
      case HealthGoalType.weightGain:
        return [
          'Nuts and seeds - healthy fats and calories',
          'Avocado - nutrient-dense healthy fats',
          'Whole grain pasta - complex carbs for energy',
        ];
      case HealthGoalType.muscleGain:
        return [
          'Lean beef - high protein and iron',
          'Eggs - complete protein source',
          'Quinoa - protein-rich grain',
        ];
      case HealthGoalType.energyBoost:
        return [
          'Oatmeal - sustained energy from complex carbs',
          'Bananas - quick energy and potassium',
          'Salmon - omega-3s for brain energy',
        ];
      default:
        return [
          'Variety of colorful vegetables',
          'Lean protein sources',
          'Whole grains',
        ];
    }
  }
}
