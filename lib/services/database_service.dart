// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:convert';
import '../models/user_profile.dart';
import '../models/food_item.dart';
import '../models/health_goal.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'calorie_tracker.db';
  static const int _databaseVersion = 2; // Updated version for health goals

  // Table names
  static const String _userProfileTable = 'user_profiles';
  static const String _foodRecordsTable = 'food_records';
  static const String _healthGoalsTable = 'health_goals';
  static const String _goalProgressTable = 'goal_progress';

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
      onUpgrade: _upgradeDatabase,
    );
  }

  // Create database tables (for new installations)
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

    // Create health goals table
    await db.execute('''
      CREATE TABLE $_healthGoalsTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        type INTEGER NOT NULL,
        targetValue REAL NOT NULL,
        currentValue REAL NOT NULL,
        startDate INTEGER NOT NULL,
        targetDate INTEGER NOT NULL,
        difficulty INTEGER NOT NULL,
        customSettings TEXT NOT NULL DEFAULT '{}',
        isActive INTEGER NOT NULL DEFAULT 1,
        createdAt INTEGER NOT NULL,
        updatedAt INTEGER NOT NULL
      )
    ''');

    // Create goal progress table
    await db.execute('''
      CREATE TABLE $_goalProgressTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        goalId INTEGER NOT NULL,
        value REAL NOT NULL,
        caloriesConsumed REAL NOT NULL,
        notes TEXT DEFAULT '',
        recordDate INTEGER NOT NULL,
        createdAt INTEGER NOT NULL,
        FOREIGN KEY (goalId) REFERENCES $_healthGoalsTable (id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute(
        'CREATE INDEX idx_food_records_date ON $_foodRecordsTable (recordedDate)');
    await db.execute(
        'CREATE INDEX idx_health_goals_active ON $_healthGoalsTable (isActive)');
    await db.execute(
        'CREATE INDEX idx_goal_progress_goal ON $_goalProgressTable (goalId, recordDate)');
  }

  // Upgrade database (for existing installations)
  static Future<void> _upgradeDatabase(
      Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add health goals tables
      await db.execute('''
        CREATE TABLE $_healthGoalsTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          type INTEGER NOT NULL,
          targetValue REAL NOT NULL,
          currentValue REAL NOT NULL,
          startDate INTEGER NOT NULL,
          targetDate INTEGER NOT NULL,
          difficulty INTEGER NOT NULL,
          customSettings TEXT NOT NULL DEFAULT '{}',
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
        )
      ''');

      await db.execute('''
        CREATE TABLE $_goalProgressTable (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          goalId INTEGER NOT NULL,
          value REAL NOT NULL,
          caloriesConsumed REAL NOT NULL,
          notes TEXT DEFAULT '',
          recordDate INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY (goalId) REFERENCES $_healthGoalsTable (id) ON DELETE CASCADE
        )
      ''');

      // Create indexes
      await db.execute(
          'CREATE INDEX idx_health_goals_active ON $_healthGoalsTable (isActive)');
      await db.execute(
          'CREATE INDEX idx_goal_progress_goal ON $_goalProgressTable (goalId, recordDate)');
    }
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

  // ========== Health Goal Methods ==========

  // Create a new health goal
  static Future<int> createHealthGoal(HealthGoal goal) async {
    final db = await database;
    final goalMap = goal.toMap();
    goalMap['customSettings'] = jsonEncode(goal.customSettings);
    return await db.insert(_healthGoalsTable, goalMap);
  }

  // Get all health goals
  static Future<List<HealthGoal>> getAllHealthGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _healthGoalsTable,
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _mapToHealthGoal(map)).toList();
  }

  // Get active health goals
  static Future<List<HealthGoal>> getActiveHealthGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _healthGoalsTable,
      where: 'isActive = ?',
      whereArgs: [1],
      orderBy: 'createdAt DESC',
    );

    return maps.map((map) => _mapToHealthGoal(map)).toList();
  }

  // Get health goal by ID
  static Future<HealthGoal?> getHealthGoalById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _healthGoalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return _mapToHealthGoal(maps.first);
    }
    return null;
  }

  // Update health goal
  static Future<int> updateHealthGoal(HealthGoal goal) async {
    final db = await database;
    final goalMap = goal.toMap();
    goalMap['customSettings'] = jsonEncode(goal.customSettings);

    return await db.update(
      _healthGoalsTable,
      goalMap,
      where: 'id = ?',
      whereArgs: [goal.id],
    );
  }

  // Delete health goal
  static Future<int> deleteHealthGoal(int id) async {
    final db = await database;
    return await db.delete(
      _healthGoalsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Deactivate health goal (soft delete)
  static Future<int> deactivateHealthGoal(int id) async {
    final db = await database;
    return await db.update(
      _healthGoalsTable,
      {'isActive': 0, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ========== Goal Progress Methods ==========

  // Add progress entry
  static Future<int> addGoalProgress(GoalProgress progress) async {
    final db = await database;
    return await db.insert(_goalProgressTable, progress.toMap());
  }

  // Get progress entries for a goal
  static Future<List<GoalProgress>> getGoalProgress(int goalId,
      {int? limitDays}) async {
    final db = await database;

    String whereClause = 'goalId = ?';
    List<dynamic> whereArgs = [goalId];

    if (limitDays != null) {
      final cutoffDate = DateTime.now().subtract(Duration(days: limitDays));
      whereClause += ' AND recordDate >= ?';
      whereArgs.add(cutoffDate.millisecondsSinceEpoch);
    }

    final List<Map<String, dynamic>> maps = await db.query(
      _goalProgressTable,
      where: whereClause,
      whereArgs: whereArgs,
      orderBy: 'recordDate DESC',
    );

    return maps.map((map) => GoalProgress.fromMap(map)).toList();
  }

  // Get latest progress for a goal
  static Future<GoalProgress?> getLatestGoalProgress(int goalId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _goalProgressTable,
      where: 'goalId = ?',
      whereArgs: [goalId],
      orderBy: 'recordDate DESC',
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return GoalProgress.fromMap(maps.first);
    }
    return null;
  }

  // Update goal's current value based on latest progress
  static Future<void> updateGoalCurrentValue(
      int goalId, double newValue) async {
    final db = await database;
    await db.update(
      _healthGoalsTable,
      {
        'currentValue': newValue,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  // ========== Enhanced Statistics Methods ==========

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

  // Get nutrition statistics with enhanced goal integration
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

      // Get nutrition data per 100g
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

  // ========== Goal-Enhanced Analytics ==========

  // Get goal progress analytics
  static Future<Map<String, dynamic>> getGoalProgressAnalytics(
      int goalId) async {
    final db = await database;

    final progressData = await db.rawQuery('''
      SELECT 
        value,
        caloriesConsumed,
        recordDate,
        notes
      FROM $_goalProgressTable 
      WHERE goalId = ?
      ORDER BY recordDate ASC
    ''', [goalId]);

    if (progressData.isEmpty) {
      return {
        'totalEntries': 0,
        'avgProgress': 0.0,
        'trend': 'stable',
        'consistencyScore': 0.0,
      };
    }

    // Calculate trend and consistency
    final values = progressData.map((p) => p['value'] as double).toList();
    final totalEntries = progressData.length;
    final avgProgress =
        values.fold(0.0, (sum, val) => sum + val) / totalEntries;

    // Simple trend calculation
    final firstHalf =
        values.take(totalEntries ~/ 2).fold(0.0, (sum, val) => sum + val) /
            (totalEntries ~/ 2);
    final secondHalf =
        values.skip(totalEntries ~/ 2).fold(0.0, (sum, val) => sum + val) /
            (totalEntries - totalEntries ~/ 2);

    String trend = 'stable';
    if (secondHalf > firstHalf * 1.05) trend = 'improving';
    if (secondHalf < firstHalf * 0.95) trend = 'declining';

    // Consistency score based on regular logging
    final daysCovered = progressData.length;
    final goal = await getHealthGoalById(goalId);
    final totalDaysSinceStart =
        goal != null ? DateTime.now().difference(goal.startDate).inDays + 1 : 1;
    final consistencyScore =
        (daysCovered / totalDaysSinceStart).clamp(0.0, 1.0);

    return {
      'totalEntries': totalEntries,
      'avgProgress': avgProgress,
      'trend': trend,
      'consistencyScore': consistencyScore,
      'progressData': progressData,
    };
  }

  // Get adjusted calorie target based on active goals
  static Future<double> getAdjustedCalorieTarget(double baseTDEE) async {
    final activeGoals = await getActiveHealthGoals();
    if (activeGoals.isEmpty) {
      return baseTDEE;
    }

    // Use the primary goal (most recent active goal) for adjustment
    final primaryGoal = activeGoals.first;
    final adjustment = primaryGoal.recommendedCalorieAdjustment;

    return baseTDEE + adjustment;
  }

  // ========== Helper Methods ==========

  // Convert database Map to HealthGoal object
  static HealthGoal _mapToHealthGoal(Map<String, dynamic> map) {
    Map<String, dynamic> customSettings = {};
    try {
      final settingsStr = map['customSettings'] as String?;
      if (settingsStr != null &&
          settingsStr.isNotEmpty &&
          settingsStr != '{}') {
        customSettings = jsonDecode(settingsStr);
      }
    } catch (e) {
      customSettings = {};
    }

    return HealthGoal(
      id: map['id'],
      name: map['name'],
      type: HealthGoalType.values[map['type']],
      targetValue: map['targetValue'].toDouble(),
      currentValue: map['currentValue'].toDouble(),
      startDate: DateTime.fromMillisecondsSinceEpoch(map['startDate']),
      targetDate: DateTime.fromMillisecondsSinceEpoch(map['targetDate']),
      difficulty: GoalDifficulty.values[map['difficulty']],
      customSettings: customSettings,
      isActive: map['isActive'] == 1,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
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

  // ========== Database Management ==========

  // Clear all data (for testing or reset)
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_userProfileTable);
    await db.delete(_foodRecordsTable);
    await db.delete(_healthGoalsTable);
    await db.delete(_goalProgressTable);
  }

  // Clear only health goals data
  static Future<void> clearHealthGoalsData() async {
    final db = await database;
    await db.delete(_goalProgressTable);
    await db.delete(_healthGoalsTable);
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

    final goalCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_healthGoalsTable')) ??
        0;

    final progressCount = Sqflite.firstIntValue(
            await db.rawQuery('SELECT COUNT(*) FROM $_goalProgressTable')) ??
        0;

    return {
      'userProfiles': userCount,
      'foodRecords': recordCount,
      'healthGoals': goalCount,
      'goalProgress': progressCount,
    };
  }

  // Close database connection
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // Database health check
  static Future<bool> isDatabaseHealthy() async {
    try {
      final db = await database;
      await db.rawQuery('SELECT 1');

      // Check if all tables exist
      final tables = [
        'user_profiles',
        'food_records',
        'health_goals',
        'goal_progress'
      ];
      for (String table in tables) {
        final result = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
            [table]);
        if (result.isEmpty) {
          print('Missing table: $table');
          return false;
        }
      }

      return true;
    } catch (e) {
      print('Database health check failed: $e');
      return false;
    }
  }

  // Backup database data to Map (for export/backup)
  static Future<Map<String, dynamic>> exportDatabaseData() async {
    final db = await database;

    final userProfiles = await db.query(_userProfileTable);
    final foodRecords = await db.query(_foodRecordsTable);
    final healthGoals = await db.query(_healthGoalsTable);
    final goalProgress = await db.query(_goalProgressTable);

    return {
      'version': _databaseVersion,
      'exportDate': DateTime.now().toIso8601String(),
      'userProfiles': userProfiles,
      'foodRecords': foodRecords,
      'healthGoals': healthGoals,
      'goalProgress': goalProgress,
    };
  }

  // Import database data from Map (for restore/import)
  static Future<void> importDatabaseData(Map<String, dynamic> data) async {
    final db = await database;

    await db.transaction((txn) async {
      // Clear existing data
      await txn.delete(_userProfileTable);
      await txn.delete(_foodRecordsTable);
      await txn.delete(_goalProgressTable); // Delete first due to foreign key
      await txn.delete(_healthGoalsTable);

      // Import data
      if (data['userProfiles'] != null) {
        for (var profile in data['userProfiles']) {
          await txn.insert(_userProfileTable, profile);
        }
      }

      if (data['foodRecords'] != null) {
        for (var record in data['foodRecords']) {
          await txn.insert(_foodRecordsTable, record);
        }
      }

      if (data['healthGoals'] != null) {
        for (var goal in data['healthGoals']) {
          await txn.insert(_healthGoalsTable, goal);
        }
      }

      if (data['goalProgress'] != null) {
        for (var progress in data['goalProgress']) {
          await txn.insert(_goalProgressTable, progress);
        }
      }
    });
  }

  // ========== Advanced Query Methods ==========

  // Get comprehensive dashboard data
  static Future<Map<String, dynamic>> getDashboardData(UserProfile user) async {
    final today = DateTime.now();
    final todayRecords = await getTodayFoodRecords();
    final activeGoals = await getActiveHealthGoals();
    final recentProgress = <Map<String, dynamic>>[];

    // Get recent progress for active goals
    for (var goal in activeGoals) {
      final progress = await getGoalProgress(goal.id!, limitDays: 7);
      if (progress.isNotEmpty) {
        recentProgress.add({
          'goal': goal,
          'progress': progress,
          'analytics': await getGoalProgressAnalytics(goal.id!),
        });
      }
    }

    final todayCalories =
        todayRecords.fold(0.0, (sum, r) => sum + r.totalCalories);
    final adjustedTarget = await getAdjustedCalorieTarget(user.calculateTDEE());
    final nutritionStats = await getNutritionStatistics(today);

    return {
      'todayCalories': todayCalories,
      'calorieTarget': adjustedTarget,
      'calorieProgress': todayCalories / adjustedTarget,
      'todayRecords': todayRecords,
      'activeGoals': activeGoals,
      'goalProgress': recentProgress,
      'nutritionStats': nutritionStats,
      'weeklyData': await getWeeklyCalorieData(7),
    };
  }

  // Search food records with filters
  static Future<List<FoodRecord>> searchFoodRecords({
    String? foodName,
    String? category,
    String? mealType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    final db = await database;

    List<String> conditions = [];
    List<dynamic> args = [];

    if (foodName != null && foodName.isNotEmpty) {
      conditions.add('foodName LIKE ?');
      args.add('%$foodName%');
    }

    if (category != null && category.isNotEmpty) {
      conditions.add('foodCategory = ?');
      args.add(category);
    }

    if (mealType != null && mealType.isNotEmpty) {
      conditions.add('mealType = ?');
      args.add(mealType);
    }

    if (startDate != null) {
      conditions.add('recordedAt >= ?');
      args.add(startDate.millisecondsSinceEpoch);
    }

    if (endDate != null) {
      conditions.add('recordedAt <= ?');
      args.add(endDate.millisecondsSinceEpoch);
    }

    final whereClause = conditions.isNotEmpty ? conditions.join(' AND ') : null;

    final List<Map<String, dynamic>> maps = await db.query(
      _foodRecordsTable,
      where: whereClause,
      whereArgs: args.isNotEmpty ? args : null,
      orderBy: 'recordedAt DESC',
      limit: limit,
    );

    return maps.map((map) => _mapToFoodRecord(map)).toList();
  }

  // Get food records grouped by date
  static Future<Map<String, List<FoodRecord>>> getFoodRecordsGroupedByDate(
    DateTime startDate,
    DateTime endDate,
  ) async {
    final db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      _foodRecordsTable,
      where: 'recordedAt >= ? AND recordedAt <= ?',
      whereArgs: [
        startDate.millisecondsSinceEpoch,
        endDate.millisecondsSinceEpoch,
      ],
      orderBy: 'recordedAt DESC',
    );

    final records = maps.map((map) => _mapToFoodRecord(map)).toList();
    final Map<String, List<FoodRecord>> groupedRecords = {};

    for (var record in records) {
      final dateKey = _formatDate(record.recordedAt);
      if (!groupedRecords.containsKey(dateKey)) {
        groupedRecords[dateKey] = [];
      }
      groupedRecords[dateKey]!.add(record);
    }

    return groupedRecords;
  }

  // Get calorie trends with goal comparison
  static Future<List<Map<String, dynamic>>> getCalorieTrendsWithGoals(
      int days) async {
    final weeklyData = await getWeeklyCalorieData(days);
    final activeGoals = await getActiveHealthGoals();

    // Get the primary weight-related goal for target calculation
    final weightGoal = activeGoals.firstWhere(
      (goal) =>
          goal.type == HealthGoalType.weightLoss ||
          goal.type == HealthGoalType.weightGain ||
          goal.type == HealthGoalType.muscleGain,
      orElse: () => activeGoals.isNotEmpty
          ? activeGoals.first
          : HealthGoal(
              name: 'Default',
              type: HealthGoalType.maintenance,
              targetValue: 0,
              currentValue: 0,
              startDate: DateTime.now(),
              targetDate: DateTime.now(),
              difficulty: GoalDifficulty.moderate,
            ),
    );

    return weeklyData.map((day) {
      return {
        'date': day.date,
        'actualCalories': day.totalCalories,
        'targetCalories': weightGoal.recommendedCalorieAdjustment != 0
            ? 2000 + weightGoal.recommendedCalorieAdjustment
            : 2000, // Simplified target calculation
        'goalType': weightGoal.type.toString(),
        'mealBreakdown': day.mealBreakdown,
        'foodCount': day.foodCount,
      };
    }).toList();
  }
}
