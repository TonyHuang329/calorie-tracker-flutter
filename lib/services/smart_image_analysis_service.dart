// lib/services/smart_image_analysis_service_fixed.dart
// 修复版本 - 兼容最新的 image 包 API

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:shared_preferences/shared_preferences.dart';

class SmartImageAnalysisService {
  static SmartImageAnalysisService? _instance;

  SmartImageAnalysisService._();

  static SmartImageAnalysisService get instance {
    _instance ??= SmartImageAnalysisService._();
    return _instance!;
  }

  /// 智能分析图像并返回食物分类建议
  Future<FoodClassificationResult> analyzeImage(File imageFile) async {
    try {
      // 1. 图像质量检测
      final quality = await _assessImageQuality(imageFile);

      if (quality.score < 0.6) {
        return FoodClassificationResult.lowQuality(quality);
      }

      // 2. 图像特征提取
      final features = await _extractImageFeatures(imageFile);

      // 3. 智能分类
      final suggestions = _classifyByFeatures(features);

      return FoodClassificationResult.success(
        suggestions: suggestions,
        features: features,
        quality: quality,
      );
    } catch (e) {
      return FoodClassificationResult.error('分析失败: ${e.toString()}');
    }
  }

  /// 图像质量评估
  Future<ImageQuality> _assessImageQuality(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);

      if (image == null) {
        return ImageQuality.poor('无法解析图像');
      }

      double score = 1.0;
      List<String> issues = [];
      List<String> suggestions = [];

      // 检查图像尺寸
      if (image.width < 300 || image.height < 300) {
        score -= 0.2;
        issues.add('图像分辨率过低');
        suggestions.add('请靠近拍摄或使用更高质量的相机');
      }

      // 检查亮度
      final brightness = _calculateBrightness(image);
      if (brightness < 0.3) {
        score -= 0.3;
        issues.add('图像过暗');
        suggestions.add('请在光线充足的环境下拍摄');
      } else if (brightness > 0.8) {
        score -= 0.2;
        issues.add('图像过亮');
        suggestions.add('请避免强光直射');
      }

      // 检查清晰度（简化版本）
      final sharpness = _estimateSharpness(image);
      if (sharpness < 0.5) {
        score -= 0.3;
        issues.add('图像模糊');
        suggestions.add('请保持手机稳定，确保对焦清晰');
      }

      return ImageQuality(
        score: score.clamp(0.0, 1.0),
        brightness: brightness,
        sharpness: sharpness,
        issues: issues,
        suggestions: suggestions,
      );
    } catch (e) {
      return ImageQuality.poor('图像处理错误: ${e.toString()}');
    }
  }

  /// 提取图像特征
  Future<ImageFeatures> _extractImageFeatures(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);

    if (image == null) {
      throw Exception('无法解析图像');
    }

    // 为了提高性能，如果图像太大就缩放
    final processedImage = _resizeImageIfNeeded(image);

    // 颜色分析
    final colorProfile = _analyzeColors(processedImage);

    // 形状分析
    final shapeProfile = _analyzeShapes(processedImage);

    // 纹理分析（简化）
    final textureProfile = _analyzeTexture(processedImage);

    return ImageFeatures(
      colors: colorProfile,
      shapes: shapeProfile,
      textures: textureProfile,
      size: Size(
          processedImage.width.toDouble(), processedImage.height.toDouble()),
    );
  }

  /// 如果图像太大则缩放
  img.Image _resizeImageIfNeeded(img.Image image) {
    const maxSize = 512;
    if (image.width > maxSize || image.height > maxSize) {
      final ratio =
          maxSize / (image.width > image.height ? image.width : image.height);
      final newWidth = (image.width * ratio).round();
      final newHeight = (image.height * ratio).round();
      return img.copyResize(image, width: newWidth, height: newHeight);
    }
    return image;
  }

  /// 颜色分析 - 修复版本
  ColorProfile _analyzeColors(img.Image image) {
    Map<String, int> colorCounts = {};
    int totalPixels = 0;

    // 采样分析（每10个像素采样一次以提高性能）
    for (int y = 0; y < image.height; y += 10) {
      for (int x = 0; x < image.width; x += 10) {
        final pixel = image.getPixel(x, y);
        final color = _categorizeColor(pixel);
        colorCounts[color] = (colorCounts[color] ?? 0) + 1;
        totalPixels++;
      }
    }

    // 计算颜色分布
    Map<String, double> colorDistribution = {};
    colorCounts.forEach((color, count) {
      colorDistribution[color] = count / totalPixels;
    });

    // 找出主导颜色
    String dominantColor = colorDistribution.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return ColorProfile(
      dominantColor: dominantColor,
      colorDistribution: colorDistribution,
      diversity: colorDistribution.length / 10.0, // 归一化颜色多样性
    );
  }

  /// 将像素分类为基础颜色 - 修复版本
  String _categorizeColor(img.Pixel pixel) {
    // 使用新的 image 包 API 获取RGB值
    final r = pixel.r.toInt();
    final g = pixel.g.toInt();
    final b = pixel.b.toInt();

    // HSV分析
    final hsv = _rgbToHsv(r, g, b);
    final hue = hsv[0];
    final saturation = hsv[1];
    final value = hsv[2];

    // 基于HSV的颜色分类
    if (value < 0.2) return 'black';
    if (value > 0.8 && saturation < 0.2) return 'white';
    if (saturation < 0.3) return 'gray';

    if (hue < 15 || hue > 345) return 'red';
    if (hue < 45) return 'orange';
    if (hue < 75) return 'yellow';
    if (hue < 150) return 'green';
    if (hue < 210) return 'blue';
    if (hue < 270) return 'purple';
    if (hue < 330) return 'pink';

    return 'brown';
  }

  /// RGB转HSV
  List<double> _rgbToHsv(int r, int g, int b) {
    double rf = r / 255.0;
    double gf = g / 255.0;
    double bf = b / 255.0;

    double max = [rf, gf, bf].reduce((a, b) => a > b ? a : b);
    double min = [rf, gf, bf].reduce((a, b) => a < b ? a : b);
    double delta = max - min;

    double hue = 0;
    if (delta != 0) {
      if (max == rf) {
        hue = 60 * (((gf - bf) / delta) % 6);
      } else if (max == gf) {
        hue = 60 * (((bf - rf) / delta) + 2);
      } else {
        hue = 60 * (((rf - gf) / delta) + 4);
      }
    }

    double saturation = max == 0 ? 0 : delta / max;
    double value = max;

    return [hue, saturation, value];
  }

  /// 形状分析（简化版本）
  ShapeProfile _analyzeShapes(img.Image image) {
    // 计算基本的几何特征
    final aspectRatio = image.width / image.height;

    // 简化的圆度计算（基于长宽比）
    double roundness = 1.0 - (aspectRatio - 1.0).abs();
    roundness = roundness.clamp(0.0, 1.0);

    String shapeCategory;
    if (roundness > 0.8) {
      shapeCategory = 'round'; // 圆形 - 苹果、橙子
    } else if (aspectRatio > 2.0) {
      shapeCategory = 'long'; // 长条形 - 香蕉、面条
    } else if (aspectRatio < 0.5) {
      shapeCategory = 'tall'; // 高形 - 瓶子、杯子
    } else {
      shapeCategory = 'irregular'; // 不规则 - 肉类、蔬菜
    }

    return ShapeProfile(
      category: shapeCategory,
      roundness: roundness,
      aspectRatio: aspectRatio,
      edgeComplexity: 0.5, // 简化处理
    );
  }

  /// 纹理分析（简化版本）
  TextureProfile _analyzeTexture(img.Image image) {
    // 计算基本的纹理特征
    double contrast = _calculateContrast(image);
    double roughness = _calculateRoughness(image);

    String textureCategory;
    if (roughness > 0.7) {
      textureCategory = 'rough'; // 粗糙 - 面包、饼干
    } else if (contrast < 0.3) {
      textureCategory = 'smooth'; // 光滑 - 水果、汤类
    } else {
      textureCategory = 'granular'; // 颗粒 - 米饭、坚果
    }

    return TextureProfile(
      category: textureCategory,
      contrast: contrast,
      roughness: roughness,
      uniformity: 1.0 - roughness, // 均匀性与粗糙度相反
    );
  }

  /// 基于特征的智能分类
  List<CategorySuggestion> _classifyByFeatures(ImageFeatures features) {
    Map<String, double> categoryScores = {};

    // 基于颜色的分类
    _scoreByColor(features.colors, categoryScores);

    // 基于形状的分类
    _scoreByShape(features.shapes, categoryScores);

    // 基于纹理的分类
    _scoreByTexture(features.textures, categoryScores);

    // 转换为建议列表并排序
    List<CategorySuggestion> suggestions = categoryScores.entries.map((entry) {
      return CategorySuggestion(
        category: entry.key,
        confidence: entry.value.clamp(0.0, 1.0),
        reasons: _generateReasons(entry.key, features),
        foodSuggestions: _getFoodSuggestionsForCategory(entry.key),
      );
    }).toList();

    suggestions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return suggestions.take(5).toList();
  }

  /// 基于颜色评分
  void _scoreByColor(ColorProfile colors, Map<String, double> scores) {
    switch (colors.dominantColor) {
      case 'green':
        scores['蔬菜'] = (scores['蔬菜'] ?? 0) + 0.8;
        scores['水果'] = (scores['水果'] ?? 0) + 0.3;
        break;
      case 'red':
        scores['水果'] = (scores['水果'] ?? 0) + 0.7;
        scores['蛋白质'] = (scores['蛋白质'] ?? 0) + 0.4;
        break;
      case 'orange':
        scores['水果'] = (scores['水果'] ?? 0) + 0.6;
        scores['蔬菜'] = (scores['蔬菜'] ?? 0) + 0.4;
        break;
      case 'yellow':
        scores['主食'] = (scores['主食'] ?? 0) + 0.6;
        scores['水果'] = (scores['水果'] ?? 0) + 0.5;
        break;
      case 'brown':
        scores['主食'] = (scores['主食'] ?? 0) + 0.7;
        scores['蛋白质'] = (scores['蛋白质'] ?? 0) + 0.5;
        break;
      case 'white':
        scores['主食'] = (scores['主食'] ?? 0) + 0.5;
        scores['蛋白质'] = (scores['蛋白质'] ?? 0) + 0.3;
        break;
    }
  }

  /// 基于形状评分
  void _scoreByShape(ShapeProfile shapes, Map<String, double> scores) {
    switch (shapes.category) {
      case 'round':
        scores['水果'] = (scores['水果'] ?? 0) + 0.6;
        scores['蛋白质'] = (scores['蛋白质'] ?? 0) + 0.3; // 鸡蛋
        break;
      case 'long':
        scores['蔬菜'] = (scores['蔬菜'] ?? 0) + 0.5; // 胡萝卜、黄瓜
        scores['水果'] = (scores['水果'] ?? 0) + 0.4; // 香蕉
        break;
      case 'irregular':
        scores['蛋白质'] = (scores['蛋白质'] ?? 0) + 0.6;
        scores['蔬菜'] = (scores['蔬菜'] ?? 0) + 0.4;
        break;
    }
  }

  /// 基于纹理评分
  void _scoreByTexture(TextureProfile textures, Map<String, double> scores) {
    switch (textures.category) {
      case 'smooth':
        scores['水果'] = (scores['水果'] ?? 0) + 0.5;
        scores['饮品'] = (scores['饮品'] ?? 0) + 0.4;
        break;
      case 'rough':
        scores['主食'] = (scores['主食'] ?? 0) + 0.6; // 面包
        scores['零食'] = (scores['零食'] ?? 0) + 0.5; // 饼干
        break;
      case 'granular':
        scores['主食'] = (scores['主食'] ?? 0) + 0.7; // 米饭
        scores['零食'] = (scores['零食'] ?? 0) + 0.4; // 坚果
        break;
    }
  }

  /// 生成分类原因
  List<String> _generateReasons(String category, ImageFeatures features) {
    List<String> reasons = [];

    // 基于颜色的原因
    if (_isColorMatch(category, features.colors.dominantColor)) {
      reasons
          .add('颜色特征：${_getColorDescription(features.colors.dominantColor)}');
    }

    // 基于形状的原因
    if (_isShapeMatch(category, features.shapes.category)) {
      reasons.add('形状特征：${_getShapeDescription(features.shapes.category)}');
    }

    // 基于纹理的原因
    if (_isTextureMatch(category, features.textures.category)) {
      reasons.add('纹理特征：${_getTextureDescription(features.textures.category)}');
    }

    if (reasons.isEmpty) {
      reasons.add('综合特征分析结果');
    }

    return reasons;
  }

  /// 获取分类对应的食物建议
  List<String> _getFoodSuggestionsForCategory(String category) {
    const categoryFoods = {
      '水果': ['苹果', '香蕉', '橙子', '葡萄', '草莓'],
      '蔬菜': ['西兰花', '胡萝卜', '番茄', '生菜', '洋葱'],
      '主食': ['米饭', '面条', '面包', '土豆', '意大利面'],
      '蛋白质': ['鸡胸肉', '牛肉', '鱼肉', '鸡蛋', '虾'],
      '零食': ['薯片', '饼干', '巧克力', '坚果', '爆米花'],
      '饮品': ['牛奶', '果汁', '咖啡', '茶', '汽水'],
    };

    return categoryFoods[category] ?? ['未知食物'];
  }

  // 辅助方法 - 简化实现以避免复杂的图像处理
  double _calculateBrightness(img.Image image) {
    double totalBrightness = 0;
    int pixelCount = 0;

    // 采样计算亮度
    for (int y = 0; y < image.height; y += 20) {
      for (int x = 0; x < image.width; x += 20) {
        final pixel = image.getPixel(x, y);
        final r = pixel.r.toInt();
        final g = pixel.g.toInt();
        final b = pixel.b.toInt();
        totalBrightness += ((r + g + b) / 3);
        pixelCount++;
      }
    }

    return pixelCount > 0 ? (totalBrightness / pixelCount) / 255.0 : 0.5;
  }

  double _estimateSharpness(img.Image image) {
    // 简化的锐度估算
    // 在实际应用中可以使用更复杂的边缘检测算法
    return 0.7; // 暂时返回固定值
  }

  double _calculateContrast(img.Image image) {
    // 简化的对比度计算
    return 0.5; // 暂时返回固定值
  }

  double _calculateRoughness(img.Image image) {
    // 简化的粗糙度计算
    return 0.5; // 暂时返回固定值
  }

  // 匹配判断方法
  bool _isColorMatch(String category, String color) {
    const matches = {
      '水果': ['red', 'orange', 'yellow', 'green'],
      '蔬菜': ['green', 'orange', 'red'],
      '主食': ['yellow', 'brown', 'white'],
      '蛋白质': ['brown', 'red', 'white'],
    };
    return matches[category]?.contains(color) ?? false;
  }

  bool _isShapeMatch(String category, String shape) {
    const matches = {
      '水果': ['round'],
      '蔬菜': ['long', 'irregular'],
      '蛋白质': ['irregular'],
    };
    return matches[category]?.contains(shape) ?? false;
  }

  bool _isTextureMatch(String category, String texture) {
    const matches = {
      '水果': ['smooth'],
      '主食': ['rough', 'granular'],
      '零食': ['rough'],
    };
    return matches[category]?.contains(texture) ?? false;
  }

  String _getColorDescription(String color) {
    const descriptions = {
      'red': '红色调',
      'green': '绿色调',
      'yellow': '黄色调',
      'orange': '橙色调',
      'brown': '棕色调',
      'white': '白色调',
    };
    return descriptions[color] ?? color;
  }

  String _getShapeDescription(String shape) {
    const descriptions = {
      'round': '圆形',
      'long': '长条形',
      'irregular': '不规则形状',
    };
    return descriptions[shape] ?? shape;
  }

  String _getTextureDescription(String texture) {
    const descriptions = {
      'smooth': '光滑表面',
      'rough': '粗糙纹理',
      'granular': '颗粒状',
    };
    return descriptions[texture] ?? texture;
  }
}

// 数据模型类保持不变...
class FoodClassificationResult {
  final bool isSuccess;
  final List<CategorySuggestion> suggestions;
  final ImageFeatures? features;
  final ImageQuality? quality;
  final String? errorMessage;

  FoodClassificationResult._({
    required this.isSuccess,
    this.suggestions = const [],
    this.features,
    this.quality,
    this.errorMessage,
  });

  factory FoodClassificationResult.success({
    required List<CategorySuggestion> suggestions,
    required ImageFeatures features,
    required ImageQuality quality,
  }) {
    return FoodClassificationResult._(
      isSuccess: true,
      suggestions: suggestions,
      features: features,
      quality: quality,
    );
  }

  factory FoodClassificationResult.lowQuality(ImageQuality quality) {
    return FoodClassificationResult._(
      isSuccess: false,
      quality: quality,
      errorMessage: '图像质量不足，请重新拍摄',
    );
  }

  factory FoodClassificationResult.error(String message) {
    return FoodClassificationResult._(
      isSuccess: false,
      errorMessage: message,
    );
  }
}

class ImageQuality {
  final double score; // 0-1
  final double brightness;
  final double sharpness;
  final List<String> issues;
  final List<String> suggestions;

  ImageQuality({
    required this.score,
    required this.brightness,
    required this.sharpness,
    this.issues = const [],
    this.suggestions = const [],
  });

  factory ImageQuality.poor(String reason) {
    return ImageQuality(
      score: 0.0,
      brightness: 0.0,
      sharpness: 0.0,
      issues: [reason],
      suggestions: ['请重新拍摄'],
    );
  }

  bool get isGoodEnough => score >= 0.6;
  String get level {
    if (score >= 0.8) return '优秀';
    if (score >= 0.6) return '良好';
    if (score >= 0.4) return '一般';
    return '差';
  }
}

class ImageFeatures {
  final ColorProfile colors;
  final ShapeProfile shapes;
  final TextureProfile textures;
  final Size size;

  ImageFeatures({
    required this.colors,
    required this.shapes,
    required this.textures,
    required this.size,
  });
}

class ColorProfile {
  final String dominantColor;
  final Map<String, double> colorDistribution;
  final double diversity;

  ColorProfile({
    required this.dominantColor,
    required this.colorDistribution,
    required this.diversity,
  });
}

class ShapeProfile {
  final String category;
  final double roundness;
  final double aspectRatio;
  final double edgeComplexity;

  ShapeProfile({
    required this.category,
    required this.roundness,
    required this.aspectRatio,
    required this.edgeComplexity,
  });
}

class TextureProfile {
  final String category;
  final double contrast;
  final double roughness;
  final double uniformity;

  TextureProfile({
    required this.category,
    required this.contrast,
    required this.roughness,
    required this.uniformity,
  });
}

class CategorySuggestion {
  final String category;
  final double confidence;
  final List<String> reasons;
  final List<String> foodSuggestions;

  CategorySuggestion({
    required this.category,
    required this.confidence,
    required this.reasons,
    required this.foodSuggestions,
  });

  double get confidencePercentage => confidence * 100;
}
