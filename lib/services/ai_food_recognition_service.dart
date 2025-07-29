// lib/services/ai_food_recognition_service.dart
import 'dart:io';
import 'dart:math';
// import 'package:image/image.dart' as img;  // 暂时注释掉，先用模拟数据
// import 'package:tflite_flutter/tflite_flutter.dart'; // 暂时注释掉

// AI识别状态枚举
enum AIRecognitionStatus {
  idle, // 空闲
  initializing, // 初始化中
  processing, // 处理中
  completed, // 完成
  error, // 错误
}

class AIFoodRecognitionService {
  static AIFoodRecognitionService? _instance;
  List<String>? _labels;
  bool _isInitialized = false;

  AIFoodRecognitionService._();

  static AIFoodRecognitionService get instance {
    _instance ??= AIFoodRecognitionService._();
    return _instance!;
  }

  // 初始化AI模型
  Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // 模拟初始化延迟
      await Future.delayed(const Duration(milliseconds: 1500));

      // 加载标签
      _labels = _getDefaultLabels();

      _isInitialized = true;
      print('AI食物识别模型初始化成功 (模拟模式)');
      return true;
    } catch (e) {
      print('AI模型初始化失败: $e');
      return false;
    }
  }

  // 识别食物 (目前是模拟版本)
  Future<FoodRecognitionResult> recognizeFood(File imageFile) async {
    if (!_isInitialized) {
      throw Exception('AI模型未初始化');
    }

    try {
      // 模拟处理时间
      await Future.delayed(const Duration(milliseconds: 2000));

      // 生成模拟识别结果
      final results = _generateMockResults();

      return _processResults(results);
    } catch (e) {
      print('食物识别失败: $e');
      return FoodRecognitionResult.error('识别失败: ${e.toString()}');
    }
  }

  // 生成模拟识别结果
  List<double> _generateMockResults() {
    final random = Random();
    final results = List<double>.filled(_labels!.length, 0.0);

    // 随机选择3-5个食物给较高的置信度
    final topCount = 3 + random.nextInt(3);
    final topIndices = <int>{};

    while (topIndices.length < topCount) {
      topIndices.add(random.nextInt(_labels!.length));
    }

    // 给选中的食物分配较高的置信度
    final topIndicesList = topIndices.toList();
    for (int i = 0; i < topIndicesList.length; i++) {
      final index = topIndicesList[i];
      if (i == 0) {
        // 最高置信度 (0.6-0.9)
        results[index] = 0.6 + random.nextDouble() * 0.3;
      } else if (i == 1) {
        // 第二高 (0.3-0.6)
        results[index] = 0.3 + random.nextDouble() * 0.3;
      } else {
        // 其他 (0.1-0.4)
        results[index] = 0.1 + random.nextDouble() * 0.3;
      }
    }

    // 给其他食物分配低置信度
    for (int i = 0; i < results.length; i++) {
      if (results[i] == 0.0) {
        results[i] = random.nextDouble() * 0.2;
      }
    }

    return results;
  }

  // 处理识别结果
  FoodRecognitionResult _processResults(List<double> outputs) {
    List<FoodPrediction> predictions = [];

    for (int i = 0; i < outputs.length; i++) {
      predictions.add(FoodPrediction(
        label: _labels![i],
        confidence: outputs[i],
        index: i,
      ));
    }

    // 按置信度排序
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));

    // 取前5个结果
    final topPredictions = predictions.take(5).toList();

    return FoodRecognitionResult.success(topPredictions);
  }

  // 根据识别结果获取营养信息
  Map<String, dynamic>? getFoodNutritionInfo(String foodLabel) {
    final nutritionMap = {
      'apple': {'calories': 0.52, 'unit': 'g', 'category': '水果'},
      'banana': {'calories': 0.89, 'unit': 'g', 'category': '水果'},
      'orange': {'calories': 0.47, 'unit': 'g', 'category': '水果'},
      'grape': {'calories': 0.67, 'unit': 'g', 'category': '水果'},
      'strawberry': {'calories': 0.32, 'unit': 'g', 'category': '水果'},
      'watermelon': {'calories': 0.30, 'unit': 'g', 'category': '水果'},
      'rice': {'calories': 1.3, 'unit': 'g', 'category': '主食'},
      'bread': {'calories': 3.12, 'unit': 'g', 'category': '主食'},
      'noodle': {'calories': 2.8, 'unit': 'g', 'category': '主食'},
      'pasta': {'calories': 1.31, 'unit': 'g', 'category': '主食'},
      'potato': {'calories': 0.77, 'unit': 'g', 'category': '主食'},
      'pizza': {'calories': 2.66, 'unit': 'g', 'category': '主食'},
      'chicken': {'calories': 1.65, 'unit': 'g', 'category': '蛋白质'},
      'beef': {'calories': 2.5, 'unit': 'g', 'category': '蛋白质'},
      'pork': {'calories': 2.42, 'unit': 'g', 'category': '蛋白质'},
      'fish': {'calories': 2.06, 'unit': 'g', 'category': '蛋白质'},
      'egg': {'calories': 1.55, 'unit': 'g', 'category': '蛋白质'},
      'shrimp': {'calories': 0.99, 'unit': 'g', 'category': '蛋白质'},
      'broccoli': {'calories': 0.25, 'unit': 'g', 'category': '蔬菜'},
      'carrot': {'calories': 0.41, 'unit': 'g', 'category': '蔬菜'},
      'tomato': {'calories': 0.18, 'unit': 'g', 'category': '蔬菜'},
      'lettuce': {'calories': 0.15, 'unit': 'g', 'category': '蔬菜'},
      'onion': {'calories': 0.40, 'unit': 'g', 'category': '蔬菜'},
      'pepper': {'calories': 0.20, 'unit': 'g', 'category': '蔬菜'},
      'burger': {'calories': 2.95, 'unit': 'g', 'category': '快餐'},
      'sandwich': {'calories': 2.5, 'unit': 'g', 'category': '快餐'},
      'salad': {'calories': 0.2, 'unit': 'g', 'category': '蔬菜'},
      'soup': {'calories': 0.4, 'unit': 'ml', 'category': '汤类'},
      'cake': {'calories': 3.47, 'unit': 'g', 'category': '甜品'},
      'cookie': {'calories': 5.02, 'unit': 'g', 'category': '甜品'},
      'chocolate': {'calories': 5.46, 'unit': 'g', 'category': '甜品'},
      'ice_cream': {'calories': 2.07, 'unit': 'g', 'category': '甜品'},
      'milk': {'calories': 0.42, 'unit': 'ml', 'category': '饮品'},
      'coffee': {'calories': 0.02, 'unit': 'ml', 'category': '饮品'},
      'tea': {'calories': 0.01, 'unit': 'ml', 'category': '饮品'},
      'juice': {'calories': 0.45, 'unit': 'ml', 'category': '饮品'},
    };

    return nutritionMap[foodLabel.toLowerCase()];
  }

  // 获取默认标签
  List<String> _getDefaultLabels() {
    return [
      'apple',
      'banana',
      'orange',
      'grape',
      'strawberry',
      'watermelon',
      'rice',
      'bread',
      'noodle',
      'pasta',
      'potato',
      'pizza',
      'chicken',
      'beef',
      'pork',
      'fish',
      'egg',
      'shrimp',
      'broccoli',
      'carrot',
      'tomato',
      'lettuce',
      'onion',
      'pepper',
      'burger',
      'sandwich',
      'salad',
      'soup',
      'cake',
      'cookie',
      'chocolate',
      'ice_cream',
      'milk',
      'coffee',
      'tea',
      'juice',
    ];
  }

  // 释放资源
  void dispose() {
    _isInitialized = false;
  }
}

// 食物识别结果类
class FoodRecognitionResult {
  final bool isSuccess;
  final List<FoodPrediction> predictions;
  final String? errorMessage;

  FoodRecognitionResult._({
    required this.isSuccess,
    this.predictions = const [],
    this.errorMessage,
  });

  factory FoodRecognitionResult.success(List<FoodPrediction> predictions) {
    return FoodRecognitionResult._(
      isSuccess: true,
      predictions: predictions,
    );
  }

  factory FoodRecognitionResult.error(String message) {
    return FoodRecognitionResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }

  // 获取最可能的食物
  FoodPrediction? get topPrediction {
    return predictions.isNotEmpty ? predictions.first : null;
  }

  // 获取置信度超过阈值的预测
  List<FoodPrediction> getConfidentPredictions({double threshold = 0.5}) {
    return predictions.where((p) => p.confidence >= threshold).toList();
  }
}

// 单个食物预测结果
class FoodPrediction {
  final String label;
  final double confidence;
  final int index;

  FoodPrediction({
    required this.label,
    required this.confidence,
    required this.index,
  });

  // 获取置信度百分比
  double get confidencePercentage => confidence * 100;

  // 获取格式化的标签名
  String get displayName {
    // 将英文标签转换为中文显示名
    const labelMap = {
      'apple': '苹果',
      'banana': '香蕉',
      'orange': '橙子',
      'grape': '葡萄',
      'strawberry': '草莓',
      'watermelon': '西瓜',
      'rice': '米饭',
      'bread': '面包',
      'noodle': '面条',
      'pasta': '意大利面',
      'potato': '土豆',
      'pizza': '披萨',
      'chicken': '鸡肉',
      'beef': '牛肉',
      'pork': '猪肉',
      'fish': '鱼肉',
      'egg': '鸡蛋',
      'shrimp': '虾',
      'broccoli': '西兰花',
      'carrot': '胡萝卜',
      'tomato': '番茄',
      'lettuce': '生菜',
      'onion': '洋葱',
      'pepper': '辣椒',
      'burger': '汉堡',
      'sandwich': '三明治',
      'salad': '沙拉',
      'soup': '汤',
      'cake': '蛋糕',
      'cookie': '饼干',
      'chocolate': '巧克力',
      'ice_cream': '冰淇淋',
      'milk': '牛奶',
      'coffee': '咖啡',
      'tea': '茶',
      'juice': '果汁',
    };

    return labelMap[label.toLowerCase()] ?? label;
  }

  @override
  String toString() {
    return '$displayName (${confidencePercentage.toStringAsFixed(1)}%)';
  }
}
