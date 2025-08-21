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

  // ===== Favorites functionality =====

  // Add to favorites
  Future<void> addToFavorites(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];

    if (!favorites.contains(foodName)) {
      favorites.insert(0, foodName); // Add to beginning
      if (favorites.length > 20) {
        // Save maximum 20 items
        favorites = favorites.take(20).toList();
      }
      await prefs.setStringList(_favoritesKey, favorites);
    }
  }

  // Get favorites
  Future<List<String>> getFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_favoritesKey) ?? [];
  }

  // Remove from favorites
  Future<void> removeFromFavorites(String foodName) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> favorites = prefs.getStringList(_favoritesKey) ?? [];
    favorites.remove(foodName);
    await prefs.setStringList(_favoritesKey, favorites);
  }

  // Check if is favorite
  Future<bool> isFavorite(String foodName) async {
    final favorites = await getFavorites();
    return favorites.contains(foodName);
  }

  // ===== Recent foods functionality =====

  // Get recently added foods
  Future<List<String>> getRecentFoods({int days = 7}) async {
    try {
      final records = await DatabaseService.getRecentFoodRecords();

      // Sort by frequency and time
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

      // Sort by combined score (frequency + recency)
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
      print('Failed to get recent foods: $e');
      return [];
    }
  }

  // ===== Smart search functionality =====

  // Smart search foods
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

    // Sort by score
    results.sort((a, b) => b.score.compareTo(a.score));

    return results.map((r) => r.food).toList();
  }

  // Calculate search score
  int _calculateSearchScore(FoodItem food, String query) {
    String foodName = food.name.toLowerCase();
    String category = food.category.toLowerCase();

    // 1. Exact match - highest score
    if (foodName == query) return 100;

    // 2. Starts with match - high score
    if (foodName.startsWith(query)) return 90;

    // 3. Contains match - medium-high score
    if (foodName.contains(query)) return 80;

    // 4. Pinyin first letter match - medium score
    if (_pinyinMatch(foodName, query)) return 70;

    // 5. Category match - medium-low score
    if (category.contains(query)) return 50;

    // 6. Fuzzy match - low score
    if (_fuzzyMatch(foodName, query)) return 30;

    return 0;
  }

  // Simplified pinyin matching
  bool _pinyinMatch(String foodName, String query) {
    // Common food pinyin first letter mapping
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
      'Watermelon': ['xg', 'xigua'],
      'Orange': ['cz', 'chengzi'],
      'Grape': ['pt', 'putao'],
      'Strawberry': ['cm', 'caomei'],
      'Pork': ['zr', 'zhurou'],
      'Potato': ['td', 'tudou'],
      'Cabbage': ['bc', 'baicai'],
      'Spinach': ['bc', 'bocai'],
      'Milk': ['nn', 'niunai'],
    };

    List<String>? pinyins = pinyinMap[foodName];
    if (pinyins != null) {
      return pinyins.any((pinyin) => pinyin.contains(query));
    }

    return false;
  }

  // Fuzzy matching
  bool _fuzzyMatch(String foodName, String query) {
    // Simple fuzzy matching: check if all characters in query appear in foodName
    if (query.length < 2) return false;

    int matchCount = 0;
    for (int i = 0; i < query.length; i++) {
      if (foodName.contains(query[i])) {
        matchCount++;
      }
    }

    return matchCount >= query.length * 0.7; // 70% character match
  }

  // ===== Meal template functionality =====

  // Save meal template
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

    // Get existing template keys
    List<String> templateKeys = prefs.getStringList(_templateKeysKey) ?? [];

    // Save new template
    String templateKey = 'meal_template_$templateName';
    await prefs.setString(templateKey, jsonEncode(template));

    // Update template keys list
    if (!templateKeys.contains(templateKey)) {
      templateKeys.add(templateKey);
      await prefs.setStringList(_templateKeysKey, templateKeys);
    }
  }

  // Get all meal templates
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
          print('Failed to parse template: $e');
        }
      }
    }

    // Sort by creation time (newest first)
    templates.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return templates;
  }

  // Delete meal template
  Future<void> deleteMealTemplate(String templateName) async {
    final prefs = await SharedPreferences.getInstance();
    String templateKey = 'meal_template_$templateName';

    await prefs.remove(templateKey);

    List<String> templateKeys = prefs.getStringList(_templateKeysKey) ?? [];
    templateKeys.remove(templateKey);
    await prefs.setStringList(_templateKeysKey, templateKeys);
  }

  // Apply meal template
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
          category: foodData['category'] ?? 'Other',
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
      print('Failed to apply template: $e');
      return [];
    }
  }

  // ===== Quick quantity suggestions =====

  // Get common quantity suggestions
  List<double> getQuantitySuggestions(FoodItem food) {
    // Return common quantities based on food category
    switch (food.category) {
      case 'Staple Food':
        return [100, 150, 200, 250]; // Staple foods in larger quantities
      case 'Protein':
        return [50, 100, 150, 200]; // Protein in moderate amounts
      case 'Vegetables':
        return [100, 200, 300, 400]; // Vegetables can be eaten more
      case 'Fruits':
        return [100, 150, 200, 250]; // Fruits in moderate amounts
      case 'Snacks':
        return [20, 30, 50, 100]; // Snacks should be limited
      case 'Beverages':
        return [200, 250, 300, 500]; // Beverages in ml
      default:
        return [50, 100, 150, 200];
    }
  }
}

// Search result helper class
class _SearchResult {
  final FoodItem food;
  final int score;

  _SearchResult(this.food, this.score);
}

// Meal template data model
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
