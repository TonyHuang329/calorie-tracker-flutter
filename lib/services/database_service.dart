// lib/services/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_profile.dart';
import '../models/food_item.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'calorie_tracker.db';
  static const int _databaseVersion = 1;

  // 表名
  static const String _userProfileTable = 'user_profiles';
  static const String _foodRecordsTable = 'food_records';

  // 获取数据库实例
  static Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // 初始化数据库
  static Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createDatabase,
    );
  }

  // 创建数据库表
  static Future<void> _createDatabase(Database db, int version) async {
    // 创建用户资料表
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

    // 创建食物记录表
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

  // ========== 用户资料相关方法 ==========

  // 保存用户资料
  static Future<int> saveUserProfile(UserProfile profile) async {
    final db = await database;

    // 先删除现有的用户资料（假设只有一个用户）
    await db.delete(_userProfileTable);

    // 插入新的用户资料
    return await db.insert(_userProfileTable, profile.toMap());
  }

  // 获取用户资料
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

  // ========== 食物记录相关方法 ==========

  // 保存食物记录
  static Future<int> saveFoodRecord(FoodRecord record) async {
    final db = await database;

    // 转换为数据库格式
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

  // 获取指定日期的食物记录
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

  // 获取今日食物记录
  static Future<List<FoodRecord>> getTodayFoodRecords() async {
    return await getFoodRecordsByDate(DateTime.now());
  }

  // 删除食物记录
  static Future<int> deleteFoodRecord(int id) async {
    final db = await database;
    return await db.delete(
      _foodRecordsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // 获取最近7天的食物记录
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

  // ========== 新增：历史数据和统计方法 ==========

  // 获取指定天数的每日卡路里数据
  static Future<List<DailyCalorieData>> getWeeklyCalorieData(int days) async {
    final db = await database;
    final now = DateTime.now();
    final startDate = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));

    List<DailyCalorieData> result = [];

    for (int i = 0; i < days; i++) {
      final date = startDate.add(Duration(days: i));
      final dateString = _formatDate(date);

      // 获取当日所有食物记录
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

  // 获取目标达成统计
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
        // 目标达成标准：在目标的80%-120%范围内
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

  // 获取营养成分统计
  // 在 database_service.dart 中替换 getNutritionStatistics 方法

// 获取营养成分统计
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

    // 根据实际食物数据计算营养成分
    for (var record in records) {
      totalCalories += record['totalCalories'] as double;
      final quantity = record['quantity'] as double;
      final category = record['foodCategory'] as String;
      final foodName = record['foodName'] as String;

      // 根据食物类别和名称更精确地估算营养成分（每100g的营养成分）
      Map<String, double> nutritionPer100g =
          _getNutritionDataPer100g(foodName, category);

      // 计算实际营养成分（根据实际食用量）
      double actualQuantity = quantity;

      // 如果单位是ml，按照密度换算（简化处理，大部分液体密度接近1）
      if (record['foodUnit'] == 'ml') {
        actualQuantity = quantity; // ml和g近似相等
      }

      // 按比例计算营养成分
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

// 获取食物的营养数据（每100g）
  static Map<String, double> _getNutritionDataPer100g(
      String foodName, String category) {
    // 具体食物的营养数据
    final specificFoodData = {
      '米饭': {'protein': 2.7, 'carbs': 28.0, 'fat': 0.3},
      '面条': {'protein': 11.0, 'carbs': 55.0, 'fat': 1.1},
      '面包': {'protein': 8.5, 'carbs': 58.0, 'fat': 5.1},
      '鸡胸肉': {'protein': 31.0, 'carbs': 0.0, 'fat': 3.6},
      '鸡蛋': {'protein': 13.0, 'carbs': 1.1, 'fat': 11.0},
      '牛肉': {'protein': 26.0, 'carbs': 0.0, 'fat': 17.0},
      '鱼肉': {'protein': 22.0, 'carbs': 0.0, 'fat': 12.0},
      '西兰花': {'protein': 3.0, 'carbs': 5.0, 'fat': 0.3},
      '胡萝卜': {'protein': 0.9, 'carbs': 10.0, 'fat': 0.2},
      '番茄': {'protein': 0.9, 'carbs': 3.9, 'fat': 0.2},
      '苹果': {'protein': 0.3, 'carbs': 14.0, 'fat': 0.2},
      '香蕉': {'protein': 1.1, 'carbs': 23.0, 'fat': 0.3},
      '橙子': {'protein': 0.9, 'carbs': 12.0, 'fat': 0.1},
      '薯片': {'protein': 7.0, 'carbs': 53.0, 'fat': 32.0},
      '巧克力': {'protein': 4.9, 'carbs': 61.0, 'fat': 31.0},
      '牛奶': {'protein': 3.4, 'carbs': 5.0, 'fat': 1.0},
      '可乐': {'protein': 0.0, 'carbs': 10.6, 'fat': 0.0},
    };

    // 如果有具体食物数据，使用具体数据
    if (specificFoodData.containsKey(foodName)) {
      return specificFoodData[foodName]!;
    }

    // 否则根据食物类别估算（每100g的营养成分）
    switch (category) {
      case '蛋白质':
        return {'protein': 25.0, 'carbs': 2.0, 'fat': 8.0};
      case '主食':
        return {'protein': 8.0, 'carbs': 75.0, 'fat': 2.0};
      case '蔬菜':
        return {'protein': 2.5, 'carbs': 6.0, 'fat': 0.5};
      case '水果':
        return {'protein': 1.0, 'carbs': 15.0, 'fat': 0.3};
      case '零食':
        return {'protein': 5.0, 'carbs': 50.0, 'fat': 25.0};
      case '饮品':
        return {'protein': 1.0, 'carbs': 8.0, 'fat': 0.5};
      default:
        return {'protein': 10.0, 'carbs': 30.0, 'fat': 10.0};
    }
  }

  // 获取最常吃的食物
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

  // 获取卡路里摄入趋势
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

  // 获取餐次分布统计
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

  // 获取食物类别分布
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

  // 获取指定日期范围的卡路里统计
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

  // 获取数据库概览统计
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

  // ========== 辅助方法 ==========

  // 格式化日期为字符串 (YYYY-MM-DD)
  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // 将数据库Map转换为FoodRecord对象
  static FoodRecord _mapToFoodRecord(Map<String, dynamic> map) {
    // 重建FoodItem对象
    final foodItem = FoodItem(
      name: map['foodName'],
      unit: map['foodUnit'],
      category: map['foodCategory'],
      caloriesPerUnit: map['caloriesPerUnit'],
    );

    return FoodRecord(
      id: map['id'],
      foodItemId: 0, // 数据库中不存储foodItemId
      foodItem: foodItem,
      quantity: map['quantity'],
      totalCalories: map['totalCalories'],
      mealType: map['mealType'],
      recordedAt: DateTime.fromMillisecondsSinceEpoch(map['recordedAt']),
    );
  }

  // 清除所有数据（用于测试或重置）
  static Future<void> clearAllData() async {
    final db = await database;
    await db.delete(_userProfileTable);
    await db.delete(_foodRecordsTable);
  }

  // 关闭数据库连接
  static Future<void> closeDatabase() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }

  // 获取数据库统计信息
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
