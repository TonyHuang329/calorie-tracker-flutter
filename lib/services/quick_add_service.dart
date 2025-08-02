// lib/services/quick_add_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/food_item.dart';
import 'database_service.dart';
import 'food_database.dart';

class QuickAddService {
  static QuickAddService? _instance;
  static QuickAddService get instance => _instance ??= QuickAddService._();
  QuickAddService._();

  static const String _favoritesKey = 'favorite_foods';
  static const String _templatesKey = 'meal_templates';
  static const String _templateKeysKey = 'meal_template_keys';

  // ===== 收藏夹功能 =====

  // Add到收藏夹
  Future<void> addToFavorites(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    if (!favorites.contains(foodName)) {
      favorites.insert(0, foodName); // Add到开头
      if (favorites.length > 20) {
        // 最多Save20个
        favorites = favorites.take(20).toList();
      }
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // 获取收藏夹
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // 从收藏夹移除
  Future<void> removeFromFavorites(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    favorites.remove(foodName);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // 检查是否在收藏夹中
  Future<bool> isFavorite(String foodName) async {
    final favorites = await getFavorites();
    return favorites.contains(foodName);
  }

  // ===== 最近Add功能 =====

  // 获取最近Add的食物
  Future<List<String>> getRecentFoods({int days = 7}) async {
    try {
      final records = await DatabaseService.getRecentFoodRecords();

      // 按频率和时间排序
      Map<String, int> foodCount = {};
      Map<String, DateTime> lastEaten = {};

      final cutoffDate = DateTime.now().subtract(Duration(days: days));

      for (var record in records) {
        if (record.recordedAt.isAfter(cutoffDate)) {
          final foodName = record.foodItem?.name ?? '';
          if (foodName.isNotEmpty) {
            foodCount[foodName] = (foodCount[foodName] ?? 0) + 1;

            if (!lastEaten.containsKey(foodName) ||
                record.recordedAt.isAfter(lastEaten[foodName]!)) {
              lastEaten[foodName] = record.recordedAt;
            }
          }
        }
      }

      // 按综合评分排序（频率 + 最近程度）
      var sortedFoods = foodCount.entries.toList();
      sortedFoods.sort((a, b) {
        final aScore = a.value * 10 +
            (DateTime.now().difference(lastEaten[a.key]!).inHours > 24 ? 0 : 5);
        final bScore = b.value * 10 +
            (DateTime.now().difference(lastEaten[b.key]!).inHours > 24 ? 0 : 5);
        return bScore.compareTo(aScore);
      });

      return sortedFoods.take(10).map((e) => e.key).toList();
    } catch (e) {
      print('获取最近食物失败: $e');
      return [];
    }
  }

  // ===== 智能Search功能 =====

  // 智能Search食物
  List<FoodItem> smartSearch(String query, List<FoodItem> allFoods) {
    if (query.isEmpty) return allFoods;

    query = query.toLowerCase().trim();

    List<_SearchResult> results = [];

    for (var food in allFoods) {
      int score = _calculateSearchScore(food, query);
      if (score > 0) {
        results.add(_SearchResult(food, score));
      }
    }

    // 按分数排序
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.map((r) => r.food).toList();
  }

  // 计算Search评分
  int _calculateSearchScore(FoodItem food, String query) {
    String foodName = food.name.toLowerCase();
    String category = food.category.toLowerCase();

    // 1. 完全匹配 - 最高分
    if (foodName == query) return 100;

    // 2. 开头匹配 - 高分
    if (foodName.startsWith(query)) return 90;

    // 3. 包含匹配 - 中高分
    if (foodName.contains(query)) return 80;

    // 4. 拼音首字母匹配 - 中分
    if (_pinyinMatch(foodName, query)) return 70;

    // 5. 类别匹配 - 中低分
    if (category.contains(query)) return 50;

    // 6. 模糊匹配 - 低分
    if (_fuzzyMatch(foodName, query)) return 30;

    return 0;
  }

  // 简化的拼音匹配
  bool _pinyinMatch(String foodName, String query) {
    // 常用食物的拼音首字母映射
    Map<String, List<String>> pinyinMap = {
      'Apple': ['pg', 'pingguo'],
      'Banana': ['xj', 'xiangjiao'],
      'Rice': ['mf', 'mifan'],
      'Egg': ['jd', 'jidan'],
      'Beef': ['nr', 'niurou'],
      'Chicken Breast': ['jxr', 'jixiongrou'],
      'Broccoli': ['xlh', 'xilanhua'],
      'Tomato': ['fq', 'fanqie'],
      'Carrot': ['hlb', 'huluobo'],
      'Noodles': ['mt', 'miantiao'],
      'Bread': ['mb', 'mianbao'],
      'Fish': ['yr', 'yurou'],
      '西瓜': ['xg', 'xigua'],
      'Orange': ['cz', 'chengzi'],
      '葡萄': ['pt', 'putao'],
      '草莓': ['cm', 'caomei'],
      '猪肉': ['zr', 'zhurou'],
      '土豆': ['td', 'tudou'],
      '白菜': ['bc', 'baicai'],
      '菠菜': ['bc', 'bocai'],
      'Milk': ['nn', 'niunai'],
    };

    List<String>? pinyins = pinyinMap[foodName];
    if (pinyins != null) {
      return pinyins.any((pinyin) => pinyin.contains(query));
    }

    return false;
  }

  // 模糊匹配
  bool _fuzzyMatch(String foodName, String query) {
    // 简单的模糊匹配：检查query中的字符是否都在foodName中出现
    if (query.length < 2) return false;

    int matchCount = 0;
    for (int i = 0; i < query.length; i++) {
      if (foodName.contains(query[i])) {
        matchCount++;
      }
    }

    return matchCount >= query.length * 0.7; // 70%的字符匹配
  }

  // ===== 餐次模板功能 =====

  // Save餐次模板
  Future<void> saveMealTemplate(
      String templateName, List<FoodRecord> foods) async {
    final prefs = await SharedPreferences.getInstance();

    Map<String, dynamic> template = {
      'name': templateName,
      'foods': foods
          .map((food) => {
                'foodName': food.foodItem?.name,
                'quantity': food.quantity,
                'unit': food.foodItem?.unit,
                'category': food.foodItem?.category,
                'caloriesPerUnit': food.foodItem?.caloriesPerUnit,
              })
          .toList(),
      'totalCalories': foods.fold(0.0, (sum, food) => sum + food.totalCalories),
      'createdAt': DateTime.now().toIso8601String(),
    };

    // 获取现有模板键
    List<String> templateKeys = prefs.getStringList(_templateKeysKey) ?? [];

    // Save新模板
    String templateKey = 'meal_template_$templateName';
    await prefs.setString(templateKey, jsonEncode(template));

    // 更新模板键列表
    if (!templateKeys.contains(templateKey)) {
      templateKeys.add(templateKey);
      await prefs.setStringList(_templateKeysKey, templateKeys);
    }
  }

  // 获取所有餐次模板
  Future<List<MealTemplate>> getAllTemplates() async {
    final prefs = await SharedPreferences.getInstance();
    List<String> templateKeys = prefs.getStringList(_templateKeysKey) ?? [];

    List<MealTemplate> templates = [];
    for (String key in templateKeys) {
      String? templateData = prefs.getString(key);
      if (templateData != null) {
        try {
          Map<String, dynamic> data = jsonDecode(templateData);
          templates.add(MealTemplate.fromMap(data));
        } catch (e) {
          print('解析模板失败: $e');
        }
      }
    }

    // 按创建时间排序（最新的在前面）
    templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return templates;
  }

  // Delete餐次模板
  Future<void> deleteMealTemplate(String templateName) async {
    final prefs = await SharedPreferences.getInstance();
    String templateKey = 'meal_template_$templateName';

    await prefs.remove(templateKey);

    List<String> templateKeys = prefs.getStringList(_templateKeysKey) ?? [];
    templateKeys.remove(templateKey);
    await prefs.setStringList(_templateKeysKey, templateKeys);
  }

  // 应用餐次模板
  Future<List<FoodRecord>> applyTemplate(
      String templateName, String mealType) async {
    final prefs = await SharedPreferences.getInstance();
    String templateKey = 'meal_template_$templateName';
    String? templateData = prefs.getString(templateKey);

    if (templateData == null) return [];

    try {
      Map<String, dynamic> template = jsonDecode(templateData);
      List<dynamic> foods = template['foods'];

      List<FoodRecord> records = [];

      for (var foodData in foods) {
        final foodItem = FoodItem(
          name: foodData['foodName'] ?? '',
          caloriesPerUnit: foodData['caloriesPerUnit']?.toDouble() ?? 1.0,
          unit: foodData['unit'] ?? 'g',
          category: foodData['category'] ?? '其他',
        );

        final quantity = foodData['quantity']?.toDouble() ?? 100.0;
        final totalCalories =
            FoodDatabaseService.calculateCalories(foodItem, quantity);

        records.add(FoodRecord(
          foodItemId: 0,
          foodItem: foodItem,
          quantity: quantity,
          totalCalories: totalCalories,
          mealType: mealType,
        ));
      }

      return records;
    } catch (e) {
      print('应用模板失败: $e');
      return [];
    }
  }

  // ===== 快速数量建议 =====

  // 获取常用数量建议
  List<double> getQuantitySuggestions(FoodItem food) {
    // 根据食物类别返回常用数量
    switch (food.category) {
      case 'Staple Food':
        return [100, 150, 200, 250]; // Staple Food量较大
      case 'Protein':
        return [50, 100, 150, 200]; // Protein适中
      case 'Vegetables':
        return [100, 200, 300, 400]; // Vegetables可以多吃
      case 'Fruits':
        return [100, 150, 200, 250]; // Fruits适中
      case 'Snacks':
        return [20, 30, 50, 100]; // Snacks要少
      case 'Beverages':
        return [200, 250, 300, 500]; // Beverages以ml计
      default:
        return [50, 100, 150, 200];
    }
  }
}

// Search结果辅助类
class _SearchResult {
  final FoodItem food;
  final int score;

  _SearchResult(this.food, this.score);
}

// 餐次模板数据模型
class MealTemplate {
  final String name;
  final List<Map<String, dynamic>> foods;
  final double totalCalories;
  final DateTime createdAt;

  MealTemplate({
    required this.name,
    required this.foods,
    required this.totalCalories,
    required this.createdAt,
  });

  factory MealTemplate.fromMap(Map<String, dynamic> map) {
    return MealTemplate(
      name: map['name'] ?? '',
      foods: List<Map<String, dynamic>>.from(map['foods'] ?? []),
      totalCalories: map['totalCalories']?.toDouble() ?? 0.0,
      createdAt:
          DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'foods': foods,
      'totalCalories': totalCalories,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

