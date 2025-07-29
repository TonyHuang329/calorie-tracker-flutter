// lib/screens/nutrition_overview_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';
import '../services/database_service.dart';

class NutritionOverviewScreen extends StatefulWidget {
  final UserProfile userProfile;

  const NutritionOverviewScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<NutritionOverviewScreen> createState() =>
      _NutritionOverviewScreenState();
}

class _NutritionOverviewScreenState extends State<NutritionOverviewScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<FoodRecord> todayRecords = [];
  NutritionStats? todayNutrition;
  Map<String, double> nutritionGoals = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeNutritionGoals();
    _loadTodayData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _initializeNutritionGoals() {
    // 根据用户信息计算推荐的营养目标
    final tdee = widget.userProfile.calculateTDEE();

    nutritionGoals = {
      'calories': tdee,
      'protein': widget.userProfile.weight * 1.2, // 每公斤体重1.2g蛋白质
      'carbs': tdee * 0.5 / 4, // 50%来自碳水化合物，每克4卡路里
      'fat': tdee * 0.3 / 9, // 30%来自脂肪，每克9卡路里
    };
  }

  Future<void> _loadTodayData() async {
    setState(() => isLoading = true);

    try {
      final records = await DatabaseService.getTodayFoodRecords();
      final nutrition =
          await DatabaseService.getNutritionStatistics(DateTime.now());

      setState(() {
        todayRecords = records;
        todayNutrition = nutrition;
      });
    } catch (e) {
      print('加载营养数据失败: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('营养概览'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: '今日营养'),
            Tab(icon: Icon(Icons.trending_up), text: '营养趋势'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTodayNutritionTab(),
                _buildNutritionTrendsTab(),
              ],
            ),
    );
  }

  Widget _buildTodayNutritionTab() {
    if (todayNutrition == null) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: _loadTodayData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 营养成分饼图
          _buildNutritionPieChart(),
          const SizedBox(height: 20),

          // 营养目标进度
          _buildNutritionProgress(),
          const SizedBox(height: 20),

          // 营养建议
          _buildNutritionAdvice(),
          const SizedBox(height: 20),

          // 今日食物分解
          _buildTodayFoodBreakdown(),
        ],
      ),
    );
  }

  Widget _buildNutritionTrendsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 7天营养趋势
        _build7DayNutritionTrend(),
        const SizedBox(height: 20),

        // 营养平衡评分
        _buildNutritionScore(),
        const SizedBox(height: 20),

        // 改善建议
        _buildImprovementSuggestions(),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.pie_chart_outline,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            '今天还没有食物记录',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '添加一些食物来查看营养分析',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionPieChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.purple.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '营养成分分布',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            SizedBox(
              height: 200,
              child: Row(
                children: [
                  // 饼图
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: _buildPieChartSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),

                  // 图例
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('蛋白质', Colors.red,
                            todayNutrition!.totalProtein, 'g'),
                        const SizedBox(height: 12),
                        _buildLegendItem('碳水化合物', Colors.amber,
                            todayNutrition!.totalCarbs, 'g'),
                        const SizedBox(height: 12),
                        _buildLegendItem(
                            '脂肪', Colors.purple, todayNutrition!.totalFat, 'g'),
                        const SizedBox(height: 12),
                        _buildLegendItem('总卡路里', Colors.green,
                            todayNutrition!.totalCalories, 'kcal'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 营养比例显示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildPercentageItem(
                    '蛋白质',
                    '${todayNutrition!.proteinPercentage.round()}%',
                    Colors.red,
                    _isHealthyPercentage(
                        todayNutrition!.proteinPercentage, 10, 35),
                  ),
                  _buildPercentageItem(
                    '碳水',
                    '${todayNutrition!.carbsPercentage.round()}%',
                    Colors.amber,
                    _isHealthyPercentage(
                        todayNutrition!.carbsPercentage, 45, 65),
                  ),
                  _buildPercentageItem(
                    '脂肪',
                    '${todayNutrition!.fatPercentage.round()}%',
                    Colors.purple,
                    _isHealthyPercentage(todayNutrition!.fatPercentage, 20, 35),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final proteinCalories = todayNutrition!.totalProtein * 4;
    final carbsCalories = todayNutrition!.totalCarbs * 4;
    final fatCalories = todayNutrition!.totalFat * 9;
    final total = proteinCalories + carbsCalories + fatCalories;

    if (total == 0) {
      return [
        PieChartSectionData(
          value: 1,
          title: '暂无数据',
          color: Colors.grey,
          radius: 60,
        ),
      ];
    }

    return [
      PieChartSectionData(
        value: proteinCalories,
        title: '${(proteinCalories / total * 100).round()}%',
        color: Colors.red,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: carbsCalories,
        title: '${(carbsCalories / total * 100).round()}%',
        color: Colors.amber,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        value: fatCalories,
        title: '${(fatCalories / total * 100).round()}%',
        color: Colors.purple,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  Widget _buildLegendItem(
      String label, Color color, double value, String unit) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${value.round()} $unit',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPercentageItem(
      String label, String percentage, Color color, bool isHealthy) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          percentage,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Icon(
          isHealthy ? Icons.check_circle : Icons.warning,
          color: isHealthy ? Colors.green : Colors.orange,
          size: 16,
        ),
      ],
    );
  }

  bool _isHealthyPercentage(double percentage, double min, double max) {
    return percentage >= min && percentage <= max;
  }

  Widget _buildNutritionProgress() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.track_changes,
                    color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '营养目标达成情况',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              '卡路里',
              todayNutrition!.totalCalories,
              nutritionGoals['calories']!,
              'kcal',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              '蛋白质',
              todayNutrition!.totalProtein,
              nutritionGoals['protein']!,
              'g',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              '碳水化合物',
              todayNutrition!.totalCarbs,
              nutritionGoals['carbs']!,
              'g',
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              '脂肪',
              todayNutrition!.totalFat,
              nutritionGoals['fat']!,
              'g',
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label, double current, double target, String unit, Color color) {
    final progress = current / target;
    final percentage = (progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${current.round()}/${target.round()} $unit ($percentage%)',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation<Color>(
            progress > 1.0 ? Colors.red : color,
          ),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildNutritionAdvice() {
    List<String> advice = [];

    if (todayNutrition!.proteinPercentage < 10) {
      advice.add('蛋白质摄入偏低，建议增加鸡胸肉、鱼类或豆类');
    } else if (todayNutrition!.proteinPercentage > 35) {
      advice.add('蛋白质摄入过高，注意营养平衡');
    }

    if (todayNutrition!.carbsPercentage < 45) {
      advice.add('碳水化合物偏低，适量增加全谷物和水果');
    } else if (todayNutrition!.carbsPercentage > 65) {
      advice.add('碳水化合物过高，减少精制糖和加工食品');
    }

    if (todayNutrition!.fatPercentage < 20) {
      advice.add('脂肪摄入偏低，可以适量增加坚果和健康油脂');
    } else if (todayNutrition!.fatPercentage > 35) {
      advice.add('脂肪摄入过高，减少油炸和高脂食物');
    }

    if (advice.isEmpty) {
      advice.add('营养比例很均衡，继续保持！');
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blue.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '营养建议',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...advice
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.fiber_manual_record,
                            size: 6,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayFoodBreakdown() {
    if (todayRecords.isEmpty) {
      return const SizedBox.shrink();
    }

    // 按餐次分组
    Map<String, List<FoodRecord>> mealGroups = {};
    for (var record in todayRecords) {
      mealGroups[record.mealType] = mealGroups[record.mealType] ?? [];
      mealGroups[record.mealType]!.add(record);
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: Colors.green.shade600, size: 24),
                const SizedBox(width: 8),
                const Text(
                  '今日食物详情',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...mealGroups.entries.map((entry) {
              return _buildMealSection(entry.key, entry.value);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildMealSection(String mealType, List<FoodRecord> records) {
    final mealNames = {
      'breakfast': '早餐',
      'lunch': '午餐',
      'dinner': '晚餐',
      'snack': '零食',
    };

    final mealColors = {
      'breakfast': Colors.orange,
      'lunch': Colors.green,
      'dinner': Colors.blue,
      'snack': Colors.purple,
    };

    final totalCalories =
        records.fold(0.0, (sum, record) => sum + record.totalCalories);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: mealColors[mealType],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${mealNames[mealType]} (${totalCalories.round()} kcal)',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...records
              .map((record) => Padding(
                    padding: const EdgeInsets.only(left: 20, bottom: 4),
                    child: Text(
                      '${record.foodItem?.name} - ${record.quantity}${record.foodItem?.unit} (${record.totalCalories.round()} kcal)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ))
              .toList(),
        ],
      ),
    );
  }

  Widget _build7DayNutritionTrend() {
    // 这里可以实现7天营养趋势图
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7天营养趋势',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: 200,
              child: const Center(
                child: Text(
                  '7天趋势图\n(待实现)',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionScore() {
    double score = 0;

    // 计算营养平衡评分
    if (todayNutrition!.isHealthyBalance) {
      score += 40;
    }

    // 卡路里目标达成
    final calorieProgress =
        todayNutrition!.totalCalories / nutritionGoals['calories']!;
    if (calorieProgress >= 0.8 && calorieProgress <= 1.2) {
      score += 30;
    }

    // 蛋白质充足
    if (todayNutrition!.totalProtein >= nutritionGoals['protein']! * 0.8) {
      score += 30;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '营养平衡评分',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: [
                  Text(
                    '${score.round()}',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _getScoreColor(score),
                    ),
                  ),
                  Text(
                    '分 / 100分',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreDescription(score),
                    style: TextStyle(
                      fontSize: 14,
                      color: _getScoreColor(score),
                      fontWeight: FontWeight.w500,
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

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _getScoreDescription(double score) {
    if (score >= 80) return '营养均衡，非常棒！';
    if (score >= 60) return '还不错，继续努力！';
    return '需要改善营养搭配';
  }

  Widget _buildImprovementSuggestions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '改善建议',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSuggestionItem(
              '增加蔬菜摄入',
              '每餐至少包含一份绿叶蔬菜',
              Icons.eco,
              Colors.green,
            ),
            _buildSuggestionItem(
              '选择优质蛋白',
              '鱼类、瘦肉、豆类是很好的选择',
              Icons.egg,
              Colors.red,
            ),
            _buildSuggestionItem(
              '控制加工食品',
              '减少高糖、高盐的加工食品',
              Icons.warning,
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(
      String title, String description, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
