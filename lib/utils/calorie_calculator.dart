// lib/utils/calorie_calculator.dart
// 简单的卡路里计算工具类

class CalorieCalculator {
  /// 使用 Mifflin-St Jeor 公式计算基础代谢率 (BMR)
  static double calculateBMR({
    required double weight, // 体重 (kg)
    required double height, // 身高 (cm)
    required int age, // 年龄
    required String gender, // 性别: 'male' 或 'female'
  }) {
    if (gender.toLowerCase() == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  /// 计算总日常能量消耗 (TDEE)
  static double calculateTDEE({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
  }) {
    final bmr = calculateBMR(
      weight: weight,
      height: height,
      age: age,
      gender: gender,
    );

    final multiplier = _getActivityMultiplier(activityLevel);
    return bmr * multiplier;
  }

  /// 获取活动水平乘数
  static double _getActivityMultiplier(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // 久坐
      case 'light':
        return 1.375; // 轻度活动
      case 'moderate':
        return 1.55; // 中度活动
      case 'active':
        return 1.725; // 高度活动
      case 'very_active':
        return 1.9; // 非常活跃
      default:
        return 1.55; // 默认中度活动
    }
  }

  /// 计算卡路里进度百分比
  static double calculateProgress({
    required double targetIntake,
    required double currentIntake,
  }) {
    if (targetIntake == 0) return 0;
    return (currentIntake / targetIntake) * 100;
  }

  /// 计算剩余卡路里
  static double calculateRemainingCalories({
    required double targetIntake,
    required double currentIntake,
  }) {
    return targetIntake - currentIntake;
  }

  /// 验证输入数据
  static Map<String, String?> validateUserInput({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
  }) {
    Map<String, String?> errors = {};

    // 体重验证 (30-300kg)
    if (weight < 30 || weight > 300) {
      errors['weight'] = 'Weight should be between 30-300kg';
    }

    // 身高验证 (100-250cm)
    if (height < 100 || height > 250) {
      errors['height'] = 'Height should be between 100-250cm';
    }

    // 年龄验证 (10-120岁)
    if (age < 10 || age > 120) {
      errors['age'] = 'Age should be between 10-120 years';
    }

    // 性别验证
    if (!['male', 'female'].contains(gender.toLowerCase())) {
      errors['gender'] = 'Gender must be male or female';
    }

    // 活动水平验证
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
