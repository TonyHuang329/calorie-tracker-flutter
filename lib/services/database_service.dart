// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'calorie_tracker.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String _userProfileTable = 'user_profiles';
  static const String _foodRecordsTable = 'food_records';

  // Get database instance
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Initialize database
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  // Create database tables
  static Future<void> _createDatabase(Database db, int version) async {
    // Create user profile table
    await db.execute('''
      CREATE TABLE $_userProfileTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        age INTEGER NOT NULL,
        gender TEXT NOT NULL,
        height REAL NOT NULL,
        weight REAL NOT NULL,
        activityLevel TEXT NOT NULL,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create food records table
    await db.execute('''
      CREATE TABLE $_foodRecordsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        foodName TEXT NOT NULL,
        foodUnit TEXT NOT NULL,
        foodCategory TEXT NOT NULL,
        caloriesPerUnit REAL NOT NULL,
        quantity REAL NOT NULL,
        totalCalories REAL NOT NULL,
        mealType TEXT NOT NULL,
        recordedAt INTEGER NOT NULL,
        recordedDate TEXT NOT NULL
      )
    ''');
  }

  // ========== User Profile Methods ==========

  // Save user profile
  static Future<int> saveUserProfile(UserProfile profile) async {
    final db = await database;

    // Delete existing user profile first (assuming single user)
    await db.delete(_userProfileTable);

    // Insert new user profile
    return await db.insert(_userProfileTable, profile.toMap());
  }

  // Get user profile
  static Future<UserProfile?> getUserProfile() async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _userProfileTable,
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  // ========== Food Record Methods ==========

  // Save food record
  static Future<int> saveFoodRecord(FoodRecord record) async {
    final db = await database;

    // Convert to database format
    final recordMap = {
      'foodName': record.foodItem?.name ?? '',
      'foodUnit': record.foodItem?.unit ?? '',
      'foodCategory': record.foodItem?.category ?? '',
      'caloriesPerUnit': record.foodItem?.caloriesPerUnit ?? 0.0,
      'quantity': record.quantity,
      'totalCalories': record.totalCalories,
      'mealType': record.mealType,
      'recordedAt': record.recordedAt.millisecondsSinceEpoch,
      'recordedDate': _formatDate(record.recordedAt),
    };

    return await db.insert(_foodRecordsTable, recordMap);
  }

  // Get food records by date
  static Future<List<FoodRecord>> getFoodRecordsByDate(DateTime date) async {
    final db = await database;
    final dateString = _formatDate(date);

    final List<Map<String, dynamic>> maps = await db.query(
      _foodRecordsTable,
      where: 'recordedDate = ?',
      whereArgs: [dateString],
      orderBy: 'recordedAt DESC',
    );

    return maps.map((map) => _mapToFoodRecord(map)).toList();
  }

  // Get today's food records
  static Future<List<FoodRecord>> getTodayFoodRecords() async {
    return await getFoodRecordsByDate(DateTime.now());
  }

  // Delete food record
  static Future<int> deleteFoodRecord(int id) async {
    final db = await database;
    return await db.delete(
      _foodRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Get recent food records (last 7 days)
  static Future<List<FoodRecord>> getRecentFoodRecords() async {
    final db = await database;
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    final List<Map<String, dynamic>> maps = await db.query(
      _foodRecordsTable,
      where: 'recordedAt >= ?',
      whereArgs: [sevenDaysAgo.millisecondsSinceEpoch],
      orderBy: 'recordedAt DESC',
    );

    return maps.map((map) => _mapToFoodRecord(map)).toList();
  }

  // ========== New: Historical Data and Statistics Methods ==========

  // Get daily calorie data for specified number of days
  static Future<List<DailyCalorieData>> getWeeklyCalorieData(int days) async {
    final db = await database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    List<DailyCalorieData> result = [];

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateString = _formatDate(date);

      // Get all food records for the day
      final List<Map<String, dynamic>> records = await db.query(
        _foodRecordsTable,
        where: 'recordedDate = ?',
        whereArgs: [dateString],
      );

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
        final calories = record['totalCalories'] as double;
        final mealType = record['mealType'] as String;

        totalCalories += calories;
        mealBreakdown[mealType] = (mealBreakdown[mealType] ?? 0) + calories;
        mealCounts[mealType] = (mealCounts[mealType] ?? 0) + 1;
      }

      result.add(DailyCalorieData(
        date: date,
        totalCalories: totalCalories,
        foodCount: records.length,
        mealBreakdown: mealBreakdown,
        mealCounts: mealCounts,
      ));
    }

    return result;
  }

  // Get goal achievement statistics
  static Future<GoalAchievementStats> getGoalAchievementStats(
      double dailyTarget, int days) async {
    final weeklyData = await getWeeklyCalorieData(days);

    int achievedDays = 0;
    int totalDays = weeklyData.length;
    double totalCalories = 0;
    double bestDay = 0;
    double worstDay = double.infinity;

    if (totalDays > 0) {
      for (var day in weeklyData) {
        // Goal achievement criteria: within 80%-120% of target
        if (day.totalCalories >= dailyTarget * 0.8 &&
            day.totalCalories <= dailyTarget * 1.2) {
          achievedDays++;
        }

        totalCalories += day.totalCalories;

        if (day.totalCalories > bestDay) {
          bestDay = day.totalCalories;
        }

        if (day.totalCalories < worstDay && day.totalCalories > 0) {
          worstDay = day.totalCalories;
        }
      }

      if (worstDay == double.infinity) worstDay = 0;
    }

    return GoalAchievementStats(
      totalDays: totalDays,
      achievedDays: achievedDays,
      averageCalories: totalDays > 0 ? totalCalories / totalDays : 0,
      bestDayCalories: bestDay,
      worstDayCalories: worstDay,
      targetCalories: dailyTarget,
    );
  }

  // Get nutrition statistics
  static Future<NutritionStats> getNutritionStatistics(DateTime date) async {
    final db = await database;
    final dateString = _formatDate(date);

    final List<Map<String, dynamic>> records = await db.query(
      _foodRecordsTable,
      where: 'recordedDate = ?',
      whereArgs: [dateString],
    );

    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalCalories = 0;

    // Calculate nutrition based on actual food data
    for (var record in records) {
      totalCalories += record['totalCalories'] as double;
      final quantity = record['quantity'] as double;
      final category = record['foodCategory'] as String;
      final foodName = record['foodName'] as String;

      // Get more accurate nutrition estimation based on food category and name (per 100g)
      Map<String, double> nutritionPer100g =
          _getNutritionDataPer100g(foodName, category);

      // Calculate actual nutrition (based on actual consumption)
      double actualQuantity = quantity;

      // If unit is ml, convert by density (simplified, most liquids density ≈ 1)
      if (record['foodUnit'] == 'ml') {
        actualQuantity = quantity; // ml and g approximately equal
      }

      // Calculate nutrition proportionally
      totalProtein += (nutritionPer100g['protein']! * actualQuantity / 100);
      totalCarbs += (nutritionPer100g['carbs']! * actualQuantity / 100);
      totalFat += (nutritionPer100g['fat']! * actualQuantity / 100);
    }

    return NutritionStats(
      totalCalories: totalCalories,
      totalProtein: totalProtein,
      totalCarbs: totalCarbs,
      totalFat: totalFat,
      date: date,
    );
  }

  // Get nutrition data for food (per 100g)
  static Map<String, double> _getNutritionDataPer100g(
      String foodName, String category) {
    // Specific food nutrition data
    final specificFoodData = {
      'Rice': {'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      'Noodles': {'protein': 11.0, 'carbs': 55.0, 'fat': 1.1},
      'Bread': {'protein': 8.5, 'carbs': 58.0, 'fat': 5.1},
      'Chicken Breast': {'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      'Egg': {'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
      'Beef': {'protein': 26.0, 'carbs': 0.0, 'fat': 17.0},
      'Fish': {'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
      'Broccoli': {'protein': 3.0, 'carbs': 5.0, 'fat': 0.3},
      'Carrot': {'protein': 0.9, 'carbs': 10.0, 'fat': 0.2},
      'Tomato': {'protein': 0.9, 'carbs': 3.9, 'fat': 0.2},
      'Apple': {'protein': 0.3, 'carbs': 14.0, 'fat': 0.2},
      'Banana': {'protein': 1.1, 'carbs': 23.0, 'fat': 0.3},
      'Orange': {'protein': 0.9, 'carbs': 12.0, 'fat': 0.1},
      'Potato Chips': {'protein': 7.0, 'carbs': 53.0, 'fat': 32.0},
      'Chocolate': {'protein': 4.9, 'carbs': 61.0, 'fat': 31.0},
      'Milk': {'protein': 3.4, 'carbs': 5.0, 'fat': 1.0},
      'Cola': {'protein': 0.0, 'carbs': 10.6, 'fat': 0.0},
    };

    // If specific food data exists, use it
    if (specificFoodData.containsKey(foodName)) {
      return specificFoodData[foodName]!;
    }

    // Otherwise estimate based on food category (per 100g nutrition)
    switch (category) {
      case 'Protein':
        return {'protein': 25.0, 'carbs': 2.0, 'fat': 8.0};
      case 'Staple Food':
        return {'protein': 8.0, 'carbs': 75.0, 'fat': 2.0};
      case 'Vegetables':
        return {'protein': 2.5, 'carbs': 6.0, 'fat': 0.5};
      case 'Fruits':
        return {'protein': 1.0, 'carbs': 15.0, 'fat': 0.3};
      case 'Snacks':
        return {'protein': 5.0, 'carbs': 50.0, 'fat': 25.0};
      case 'Beverages':
        return {'protein': 1.0, 'carbs': 8.0, 'fat': 0.5};
      default:
        return {'protein': 10.0, 'carbs': 30.0, 'fat': 10.0};
    }
  }

  // Get most frequently eaten foods
  static Future<List<Map<String, dynamic>>> getMostFrequentFoods(
      {int limit = 10}) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        foodName,
        foodCategory,
        COUNT(*) as frequency,
        AVG(totalCalories) as avgCalories,
        SUM(totalCalories) as totalCalories,
        MAX(recordedAt) as lastEaten
      FROM $_foodRecordsTable 
      GROUP BY foodName
      ORDER BY frequency DESC
      LIMIT ?
    ''', [limit]);

    return result;
  }

  // Get calorie intake trend
  static Future<List<Map<String, dynamic>>> getCalorieTrend(int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        recordedDate,
        SUM(totalCalories) as dailyCalories,
        COUNT(*) as foodCount,
        AVG(totalCalories) as avgCaloriesPerFood
      FROM $_foodRecordsTable 
      WHERE recordedAt >= ?
      GROUP BY recordedDate
      ORDER BY recordedDate
    ''', [startDate.millisecondsSinceEpoch]);

    return result;
  }

  // Get meal type distribution statistics
  static Future<Map<String, double>> getMealTypeDistribution(int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        mealType,
        SUM(totalCalories) as totalCalories,
        COUNT(*) as frequency
      FROM $_foodRecordsTable 
      WHERE recordedAt >= ?
      GROUP BY mealType
    ''', [startDate.millisecondsSinceEpoch]);

    Map<String, double> distribution = {};
    for (var row in result) {
      distribution[row['mealType']] = row['totalCalories'].toDouble();
    }

    return distribution;
  }

  // Get food category distribution
  static Future<Map<String, double>> getFoodCategoryDistribution(
      int days) async {
    final db = await database;
    final startDate = DateTime.now().subtract(Duration(days: days));

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        foodCategory,
        SUM(totalCalories) as totalCalories,
        COUNT(*) as frequency
      FROM $_foodRecordsTable 
      WHERE recordedAt >= ?
      GROUP BY foodCategory
    ''', [startDate.millisecondsSinceEpoch]);

    Map<String, double> distribution = {};
    for (var row in result) {
      distribution[row['foodCategory']] = row['totalCalories'].toDouble();
    }

    return distribution;
  }

  // Get calorie statistics for specified date range
  static Future<Map<String, double>> getCalorieStatistics(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT 
        recordedDate,
        SUM(totalCalories) as dailyCalories
      FROM $_foodRecordsTable 
      WHERE recordedAt >= ? AND recordedAt <= ?
      GROUP BY recordedDate
      ORDER BY recordedDate
    ''', [
      startDate.millisecondsSinceEpoch,
      endDate.millisecondsSinceEpoch,
    ]);

    Map<String, double> statistics = {};
    for (var row in result) {
      statistics[row['recordedDate']] = row['dailyCalories'].toDouble();
    }

    return statistics;
  }

  // Get database overview statistics
  static Future<Map<String, dynamic>> getDatabaseOverview() async {
    final db = await database;

    final totalRecords = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_foodRecordsTable')) ??
        0;

    final totalDays = Sqflite.firstIntValue(await db.rawQuery(
            'SELECT COUNT(DISTINCT recordedDate) FROM $_foodRecordsTable')) ??
        0;

    final totalCalories = await db
        .rawQuery('SELECT SUM(totalCalories) as total FROM $_foodRecordsTable');

    final avgDailyCalories = await db.rawQuery('''
      SELECT AVG(dailyTotal) as avgDaily FROM (
        SELECT SUM(totalCalories) as dailyTotal 
        FROM $_foodRecordsTable 
        GROUP BY recordedDate
      )
    ''');

    return {
      'totalRecords': totalRecords,
      'totalDays': totalDays,
      'totalCalories': totalCalories.isNotEmpty
          ? (totalCalories.first['total'] ?? 0.0)
          : 0.0,
      'averageDailyCalories': avgDailyCalories.isNotEmpty
          ? (avgDailyCalories.first['avgDaily'] ?? 0.0)
          : 0.0,
    };
  }

  // ========== Helper Methods ==========

  // Format date to string (YYYY-MM-DD)
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Convert database Map to FoodRecord object
  static FoodRecord _mapToFoodRecord(Map<String, dynamic> map) {
    // Rebuild FoodItem object
    final foodItem = FoodItem(
      name: map['foodName'],
      unit: map['foodUnit'],
      category: map['foodCategory'],
      caloriesPerUnit: map['caloriesPerUnit'],
    );

    return FoodRecord(
      id: map['id'],
      foodItemId: 0, // foodItemId not stored in database
      foodItem: foodItem,
      quantity: map['quantity'],
      totalCalories: map['totalCalories'],
      mealType: map['mealType'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt']),
    );
  }

  // Clear all data (for testing or reset)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_userProfileTable);
    await db.delete(_foodRecordsTable);
  }

  // Close database connection
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Get database statistics
  static Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final userCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_userProfileTable')) ??
        0;

    final recordCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_foodRecordsTable')) ??
        0;

    return {
      'userProfiles': userCount,
      'foodRecords': recordCount,
    };
  }
}
