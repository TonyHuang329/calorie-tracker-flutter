// lib/models/food_recognition_result.dart
import 'food_item.dart';

/// 食物识别结果类
class FoodRecognitionResult {
  final bool success;
  final FoodItem? detectedFood;
  final double confidence;
  final String message;

  FoodRecognitionResult({
    required this.success,
    this.detectedFood,
    required this.confidence,
    required this.message,
  });

  /// 创建成功结果
  factory FoodRecognitionResult.success({
    required FoodItem? detectedFood,
    required double confidence,
    required String message,
  }) {
    return FoodRecognitionResult(
      success: true,
      detectedFood: detectedFood,
      confidence: confidence,
      message: message,
    );
  }

  /// 创建失败结果
  factory FoodRecognitionResult.failure({
    required String message,
  }) {
    return FoodRecognitionResult(
      success: false,
      detectedFood: null,
      confidence: 0.0,
      message: message,
    );
  }

  /// 获取置信度百分比字符串
  String get confidencePercentage {
    return '${(confidence * 100).toStringAsFixed(1)}%';
  }

  /// 获取格式化的结果描述
  String get description {
    if (success && detectedFood != null) {
      return 'Detected ${detectedFood!.name} with ${confidencePercentage} confidence';
    } else {
      return message;
    }
  }

  /// 转换为 Map
  Map<String, dynamic> toMap() {
    return {
      'success': success,
      'detectedFood': detectedFood?.toMap(),
      'confidence': confidence,
      'message': message,
    };
  }

  /// 从 Map 创建
  factory FoodRecognitionResult.fromMap(Map<String, dynamic> map) {
    return FoodRecognitionResult(
      success: map['success'] ?? false,
      detectedFood: map['detectedFood'] != null
          ? FoodItem.fromMap(map['detectedFood'])
          : null,
      confidence: (map['confidence'] ?? 0.0).toDouble(),
      message: map['message'] ?? '',
    );
  }

  @override
  String toString() {
    return 'FoodRecognitionResult(success: $success, food: ${detectedFood?.name}, confidence: ${confidencePercentage}, message: $message)';
  }
}
