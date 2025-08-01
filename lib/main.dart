import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'models/food_item.dart';
import 'models/food_recommendation.dart';
import 'services/calorie_calculator.dart';
import 'services/database_service.dart';
import 'services/food_database.dart';
import 'services/food_recommendation_service.dart';
import 'screens/add_food_screen.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/history_screen.dart';
import 'screens/nutrition_overview_screen.dart';
import 'widgets/circular_calorie_progress.dart';
import 'services/quick_add_service.dart';
import 'screens/quick_add_screen.dart';

void main() {
  runApp(const CalorieTrackerApp());
}

class CalorieTrackerApp extends StatelessWidget {
  const CalorieTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '卡路里追踪器',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UserProfile? currentUser;
  List<FoodRecord> todayFoodRecords = [];
  bool isLoading = true;

  // 推荐相关变量
  List<String> _quickRecommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // 计算当前卡路里摄入
  double get currentCalorieIntake {
    return todayFoodRecords.fold(
        0.0, (sum, record) => sum + record.totalCalories);
  }

  // 获取今日营养摘要
  Map<String, double> get todayNutritionSummary {
    double protein = 0, carbs = 0, fat = 0;

    for (var record in todayFoodRecords) {
      final quantity = record.quantity;
      final category = record.foodItem?.category ?? '';

      // 根据食物类别估算营养成分
      switch (category) {
        case '蛋白质':
          protein += quantity * 0.25;
          carbs += quantity * 0.02;
          fat += quantity * 0.08;
          break;
        case '主食':
          protein += quantity * 0.08;
          carbs += quantity * 0.75;
          fat += quantity * 0.02;
          break;
        case '蔬菜':
          protein += quantity * 0.025;
          carbs += quantity * 0.06;
          fat += quantity * 0.005;
          break;
        case '水果':
          protein += quantity * 0.01;
          carbs += quantity * 0.15;
          fat += quantity * 0.003;
          break;
        default:
          protein += quantity * 0.15;
          carbs += quantity * 0.55;
          fat += quantity * 0.30;
      }
    }

    return {'protein': protein, 'carbs': carbs, 'fat': fat};
  }

  // 初始化应用
  Future<void> _initializeApp() async {
    await _loadUserData();
    await _loadTodayFoodRecords();
    _loadQuickRecommendations();
  }

  // 加载用户数据
  Future<void> _loadUserData() async {
    try {
      final savedUser = await DatabaseService.getUserProfile();

      if (savedUser != null) {
        currentUser = savedUser;
      } else {
        // 创建默认用户
        currentUser = UserProfile(
          name: '用户',
          age: 25,
          gender: 'male',
          height: 170,
          weight: 65,
          activityLevel: 'moderate',
        );
        await DatabaseService.saveUserProfile(currentUser!);
      }
    } catch (e) {
      _handleError('加载用户数据失败', e);
      // 使用默认用户数据
      currentUser = UserProfile(
        name: '用户',
        age: 25,
        gender: 'male',
        height: 170,
        weight: 65,
        activityLevel: 'moderate',
      );
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // 加载今日食物记录
  Future<void> _loadTodayFoodRecords() async {
    try {
      final records = await DatabaseService.getTodayFoodRecords();
      if (mounted) {
        setState(() => todayFoodRecords = records);
      }
    } catch (e) {
      _handleError('加载今日食物记录失败', e);
    }
  }

  // 加载快速推荐
  Future<void> _loadQuickRecommendations() async {
    if (currentUser == null) return;

    setState(() => _isLoadingRecommendations = true);

    try {
      final recommendations = await FoodRecommendationService.instance
          .getQuickRecommendations(currentUser!);

      if (mounted) {
        setState(() {
          _quickRecommendations = recommendations;
          _isLoadingRecommendations = false;
        });
      }
    } catch (e) {
      print('加载快速推荐失败: $e');
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  // 添加食物记录
  Future<void> _addFoodRecord(FoodRecord record) async {
    try {
      await DatabaseService.saveFoodRecord(record);

      if (mounted) {
        setState(() => todayFoodRecords.add(record));
        _showSuccessMessage(
            '添加了 ${record.foodItem?.name} (${record.totalCalories.round()} 卡路里)');
        // 重新加载推荐
        _loadQuickRecommendations();
      }
    } catch (e) {
      _handleError('保存食物记录失败', e);
    }
  }

  // 删除食物记录
  Future<void> _removeFoodRecord(int index) async {
    try {
      final record = todayFoodRecords[index];

      if (record.id != null) {
        await DatabaseService.deleteFoodRecord(record.id!);
      }

      if (mounted) {
        setState(() => todayFoodRecords.removeAt(index));
        _showInfoMessage('已删除食物记录');
        // 重新加载推荐
        _loadQuickRecommendations();
      }
    } catch (e) {
      _handleError('删除食物记录失败', e);
    }
  }

  // 更新用户资料
  Future<void> _updateUserProfile(UserProfile newProfile) async {
    try {
      await DatabaseService.saveUserProfile(newProfile);

      if (mounted) {
        setState(() => currentUser = newProfile);
        _showSuccessMessage('个人资料已保存');
        // 重新加载推荐
        _loadQuickRecommendations();
      }
    } catch (e) {
      _handleError('保存用户资料失败', e);
    }
  }

  // 快速添加推荐食物
  void _quickAddRecommendedFood(String foodName) {
    try {
      // 从食物数据库找到对应食物
      final allFoods = FoodDatabaseService.getAllFoods();
      final food = allFoods.firstWhere(
        (f) => f.name == foodName,
        orElse: () => throw Exception('未找到食物: $foodName'),
      );

      final quantity = FoodDatabaseService.getRecommendedServing(food);
      final totalCalories =
          FoodDatabaseService.calculateCalories(food, quantity);

      final record = FoodRecord(
        foodItemId: food.id ?? 0,
        foodItem: food,
        quantity: quantity,
        totalCalories: totalCalories,
        mealType: _getMealTypeFromTime(),
      );

      _addFoodRecord(record);
    } catch (e) {
      _showErrorMessage('添加失败：${e.toString()}');
    }
  }

  // 导航方法
  void _navigateToAddFood() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddFoodScreen(onFoodAdded: _addFoodRecord),
      ),
    );
  }

  void _navigateToSettings() {
    if (currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ProfileSettingsScreen(
            currentUser: currentUser!,
            onProfileUpdated: _updateUserProfile,
          ),
        ),
      );
    }
  }

  void _navigateToNutritionOverview() {
    if (currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              NutritionOverviewScreen(userProfile: currentUser!),
        ),
      );
    }
  }

  void _navigateToHistory() {
    if (currentUser != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              HistoryScreen(dailyTarget: currentUser!.calculateTDEE()),
        ),
      );
    }
  }

  // 根据时间智能选择餐次
  String _getMealTypeFromTime() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 18) return 'snack';
    return 'dinner';
  }

  // 消息提示方法
  void _showSuccessMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.blue,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _handleError(String message, dynamic error) {
    print('$message: $error');
    _showErrorMessage('$message，请重试');
  }

  // 调试功能
  Future<void> _clearAllData() async {
    final confirmed = await _showConfirmDialog('确定要清除所有数据吗？');
    if (confirmed) {
      try {
        await DatabaseService.clearAllData();
        if (mounted) {
          setState(() => todayFoodRecords.clear());
          _showInfoMessage('所有数据已清除');
          _loadQuickRecommendations();
        }
      } catch (e) {
        _handleError('清除数据失败', e);
      }
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('确定'),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || currentUser == null) {
      return _buildLoadingScreen();
    }

    final targetCalories = currentUser!.calculateTDEE();
    final nutritionSummary = todayNutritionSummary;

    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadTodayFoodRecords();
          _loadQuickRecommendations();
        },
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 16),
            _buildTodayGoalCard(targetCalories),
            const SizedBox(height: 20),
            _buildCalorieProgressCard(targetCalories),
            const SizedBox(height: 20),
            _buildQuickStatsCard(targetCalories, nutritionSummary),
            const SizedBox(height: 20),

            // 新增：智能推荐卡片
            _buildQuickRecommendationCard(),
            const SizedBox(height: 20),

            if (todayFoodRecords.isNotEmpty) ...[
              _buildTodayFoodCard(),
              const SizedBox(height: 20),
            ],
            _buildQuickActionsCard(),
            const SizedBox(height: 20),
            _buildSettingsCard(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToAddFood,
        icon: const Icon(Icons.add),
        label: const Text('添加食物'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('卡路里追踪器'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('正在加载数据...'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('卡路里追踪器'),
      backgroundColor: Colors.blue.shade50,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'stats':
                final stats = await DatabaseService.getDatabaseStats();
                _showInfoMessage('数据统计: ${stats['foodRecords']} 条记录');
                break;
              case 'clear':
                await _clearAllData();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'stats',
              child: Row(
                children: [
                  Icon(Icons.bar_chart, size: 20),
                  SizedBox(width: 8),
                  Text('数据统计'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20),
                  SizedBox(width: 8),
                  Text('清除数据'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade50, Colors.blue.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 35,
              backgroundColor: Colors.blue.shade200,
              child: Text(
                currentUser!.name.isNotEmpty
                    ? currentUser!.name[0].toUpperCase()
                    : 'U',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '你好, ${currentUser!.name}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentUser!.age}岁 • ${currentUser!.gender == 'male' ? '男' : '女'} • ${currentUser!.height.round()}cm • ${currentUser!.weight.round()}kg',
                    style: TextStyle(
                      color: Colors.blue.shade600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    CalorieCalculatorService.getActivityLevelDescription(
                        currentUser!.activityLevel),
                    style: TextStyle(
                      color: Colors.blue.shade500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _navigateToSettings,
              icon: Icon(Icons.settings, color: Colors.blue.shade600),
              tooltip: '个人设置',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayGoalCard(double targetCalories) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 ? '上午好' : (now.hour < 18 ? '下午好' : '晚上好');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                _getTimeIcon(now.hour),
                color: Colors.orange.shade700,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$timeOfDay！今日目标',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '让我们开始记录今天的饮食，目标：${targetCalories.round()} kcal',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTimeIcon(int hour) {
    if (hour < 12) return Icons.wb_sunny;
    if (hour < 18) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  Widget _buildCalorieProgressCard(double targetCalories) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              '今日卡路里进度',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            CircularCalorieProgress(
              currentCalories: currentCalorieIntake,
              targetCalories: targetCalories,
              size: 220,
            ),
          ],
        ),
      ),
    );
  }

  // 新增：智能推荐卡片
  Widget _buildQuickRecommendationCard() {
    if (_quickRecommendations.isEmpty && !_isLoadingRecommendations) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade50, Colors.pink.shade50],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.psychology,
                    color: Colors.purple.shade600,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🤖 AI智能推荐',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                ),
                      ),
                      Text(
                        '基于您的饮食习惯和当前时间',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.purple.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _loadQuickRecommendations,
                  icon: Icon(
                    Icons.refresh,
                    color: Colors.purple.shade600,
                  ),
                  tooltip: '刷新推荐',
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_isLoadingRecommendations)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('AI正在分析您的需求...'),
                    ],
                  ),
                ),
              )
            else if (_quickRecommendations.isNotEmpty) ...[
              Text(
                '为您推荐以下食物：',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _quickRecommendations
                    .map(
                      (foodName) => _buildRecommendationChip(foodName),
                    )
                    .toList(),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: _navigateToAddFood,
                  icon: const Icon(Icons.add_circle_outline),
                  label: const Text('查看更多推荐'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.purple.shade600,
                  ),
                ),
              ),
            ] else ...[
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 32,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '暂无推荐',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '多记录一些饮食，推荐会更准确',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationChip(String foodName) {
    return GestureDetector(
      onTap: () => _quickAddRecommendedFood(foodName),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.purple.shade100, Colors.pink.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.purple.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.purple.shade100.withOpacity(0.5),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              foodName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.purple.shade700,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.purple.shade600,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                size: 12,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(
      double targetCalories, Map<String, double> nutrition) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '今日概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '目标卡路里',
                    '${targetCalories.round()}',
                    'kcal',
                    Colors.blue,
                    Icons.flag,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '已摄入',
                    '${currentCalorieIntake.round()}',
                    'kcal',
                    Colors.orange,
                    Icons.local_fire_department,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'BMR',
                    '${currentUser!.calculateBMR().round()}',
                    'kcal',
                    Colors.green,
                    Icons.speed,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '今日食物',
                    '${todayFoodRecords.length}',
                    '项',
                    Colors.purple,
                    Icons.restaurant,
                  ),
                ),
              ],
            ),
            if (todayFoodRecords.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '营养摘要',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutritionItem(
                      '蛋白质', nutrition['protein']!, 'g', Colors.red),
                  _buildNutritionItem(
                      '碳水', nutrition['carbs']!, 'g', Colors.amber),
                  _buildNutritionItem(
                      '脂肪', nutrition['fat']!, 'g', Colors.purple),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String title, String value, String unit, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            unit,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(
      String label, double value, String unit, Color color) {
    return Column(
      children: [
        Text(
          '${value.round()}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          '$unit $label',
          style: const TextStyle(
            fontSize: 10,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildTodayFoodCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '今日食物记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todayFoodRecords.length} 项',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...todayFoodRecords.take(3).toList().asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return _buildFoodRecordTile(record, index);
            }).toList(),
            if (todayFoodRecords.length > 3)
              TextButton(
                onPressed: _navigateToHistory,
                child: Text('查看全部 ${todayFoodRecords.length} 项记录'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodRecordTile(FoodRecord record, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getMealTypeColor(record.mealType),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              _getMealTypeIcon(record.mealType),
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.foodItem?.name ?? '未知食物',
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${record.quantity}${record.foodItem?.unit ?? ''} • ${_getMealTypeName(record.mealType)}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${record.totalCalories.round()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                'kcal',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(Icons.delete_outline, color: Colors.red.shade300),
            onPressed: () => _removeFoodRecord(index),
            iconSize: 18,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }

  // 在 main.dart 中修改 _buildQuickActionsCard 方法

  Widget _buildQuickActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildActionTile(
                  '添加食物',
                  Icons.add_circle,
                  Colors.green,
                  _navigateToAddFood,
                ),
                _buildActionTile(
                  '快速添加', // 新功能，替代AI识别
                  Icons.flash_on,
                  Colors.orange,
                  _navigateToQuickAdd,
                ),
                _buildActionTile(
                  '营养分析',
                  Icons.pie_chart,
                  Colors.blue,
                  _navigateToNutritionOverview,
                ),
                _buildActionTile(
                  '查看历史',
                  Icons.history,
                  Colors.purple,
                  _navigateToHistory,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

// 添加快速添加导航方法
  void _navigateToQuickAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuickAddScreen(onFoodAdded: _addFoodRecord),
      ),
    );
  }

  Widget _buildActionTile(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: color.withOpacity(0.8),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '设置与管理',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.person, color: Colors.blue.shade700),
              ),
              title: const Text('个人设置'),
              subtitle: const Text('修改个人信息和目标'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _navigateToSettings,
            ),
          ],
        ),
      ),
    );
  }

  // 辅助方法
  IconData _getMealTypeIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nightlight_round;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  Color _getMealTypeColor(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Colors.orange;
      case 'lunch':
        return Colors.green;
      case 'dinner':
        return Colors.blue;
      case 'snack':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _getMealTypeName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return '早餐';
      case 'lunch':
        return '午餐';
      case 'dinner':
        return '晚餐';
      case 'snack':
        return '零食';
      default:
        return '未知';
    }
  }
}
