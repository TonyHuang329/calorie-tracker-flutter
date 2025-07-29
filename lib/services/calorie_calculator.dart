import '../models/user_profile.dart';

class CalorieCalculatorService {
  /// 根据用户资料计算每日卡路里需求
  static double calculateDailyCalorieNeeds(UserProfile user) {
    return user.calculateTDEE();
  }

  /// 计算BMR - 基础代谢率
  static double calculateBMR({
    required double weight,
    required double height,
    required int age,
    required String gender,
  }) {
    if (gender.toLowerCase() == 'male') {
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  /// 根据活动水平计算TDEE
  static double calculateTDEE({
    required double bmr,
    required String activityLevel,
  }) {
    double multiplier = getActivityMultiplier(activityLevel);
    return bmr * multiplier;
  }

  /// 获取活动水平对应的倍数
  static double getActivityMultiplier(String activityLevel) {
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
        return 1.9; // 极度活动
      default:
        return 1.2;
    }
  }

  /// 获取活动水平的中文描述
  static String getActivityLevelDescription(String activityLevel) {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return '久坐 (很少或没有运动)';
      case 'light':
        return '轻度活动 (每周轻度运动1-3天)';
      case 'moderate':
        return '中度活动 (每周中度运动3-5天)';
      case 'active':
        return '高度活动 (每周剧烈运动6-7天)';
      case 'very_active':
        return '极度活动 (非常剧烈的运动，体力工作)';
      default:
        return '未知活动水平';
    }
  }

  /// 计算当前摄入与目标的百分比
  static double calculateIntakePercentage({
    required double currentIntake,
    required double targetIntake,
  }) {
    if (targetIntake == 0) return 0;
    return (currentIntake / targetIntake) * 100;
  }

  /// 计算剩余可摄入卡路里
  static double calculateRemainingCalories({
    required double targetIntake,
    required double currentIntake,
  }) {
    return targetIntake - currentIntake;
  }

  /// 验证输入数据的合理性
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
      errors['weight'] = '体重应在30-300kg之间';
    }

    // 身高验证 (100-250cm)
    if (height < 100 || height > 250) {
      errors['height'] = '身高应在100-250cm之间';
    }

    // 年龄验证 (10-120岁)
    if (age < 10 || age > 120) {
      errors['age'] = '年龄应在10-120岁之间';
    }

    // 性别验证
    if (!['male', 'female'].contains(gender.toLowerCase())) {
      errors['gender'] = '性别必须是male或female';
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
      errors['activityLevel'] = '活动水平无效';
    }

    return errors;
  }
}
