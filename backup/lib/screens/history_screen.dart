// lib/screens/history_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/food_item.dart';
import '../services/database_service.dart';

class HistoryScreen extends StatefulWidget {
  final double dailyTarget;

  const HistoryScreen({
    Key? key,
    required this.dailyTarget,
  }) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<DailyCalorieData> weeklyData = [];
  GoalAchievementStats? goalStats;
  List<Map<String, dynamic>> frequentFoods = [];
  Map<String, double> mealDistribution = {};
  bool isLoading = true;
  int selectedDays = 7;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => isLoading = true);

    try {
      final data = await DatabaseService.getWeeklyCalorieData(selectedDays);
      final stats = await DatabaseService.getGoalAchievementStats(
          widget.dailyTarget, selectedDays);
      final foods = await DatabaseService.getMostFrequentFoods(limit: 10);
      final mealDist =
          await DatabaseService.getMealTypeDistribution(selectedDays);

      setState(() {
        weeklyData = data;
        goalStats = stats;
        frequentFoods = foods;
        mealDistribution = mealDist;
      });
    } catch (e) {
      print('Failed to load data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History Records'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.date_range),
            onSelected: (days) {
              setState(() => selectedDays = days);
              _loadAllData();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 Days')),
              const PopupMenuItem(value: 14, child: Text('Last 14 Days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 Days')),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.trending_up), text: 'Trends'),
            Tab(icon: Icon(Icons.pie_chart), text: 'Statistics'),
            Tab(icon: Icon(Icons.restaurant), text: 'Foods'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildTrendTab(),
                _buildStatsTab(),
                _buildFoodsTab(),
              ],
            ),
    );
  }

  Widget _buildTrendTab() {
    return RefreshIndicator(
      onRefresh: _loadAllData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overview card
          _buildOverviewCard(),
          const SizedBox(height: 20),

          // Trend chart
          _buildTrendChart(),
          const SizedBox(height: 20),

          // Daily detailed records
          _buildDailyRecords(),
        ],
      ),
    );
  }

  Widget _buildStatsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Goal achievement statistics
        _buildGoalAchievementCard(),
        const SizedBox(height: 20),

        // Meal distribution chart
        _buildMealDistributionChart(),
        const SizedBox(height: 20),

        // Statistics cards
        _buildStatsCards(),
      ],
    );
  }

  Widget _buildFoodsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Most frequent foods
        _buildFrequentFoodsCard(),
      ],
    );
  }

  Widget _buildOverviewCard() {
    if (weeklyData.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Text('No data available', textAlign: TextAlign.center),
        ),
      );
    }

    final totalCalories =
        weeklyData.fold(0.0, (sum, day) => sum + day.totalCalories);
    final averageCalories = totalCalories / weeklyData.length;
    final activeDays = weeklyData.where((day) => day.totalCalories > 0).length;

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.insights, color: Colors.blue, size: 24),
                const SizedBox(width: 8),
                Text(
                  'Last ${selectedDays} Days Overview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildOverviewItem(
                    'Average Intake',
                    '${averageCalories.round()}',
                    'kcal/day',
                    Colors.blue,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Active Days',
                    '$activeDays',
                    'days',
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildOverviewItem(
                    'Goal Achievement',
                    '${goalStats?.achievementRate.round() ?? 0}',
                    '%',
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewItem(
      String label, String value, String unit, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTrendChart() {
    if (weeklyData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calorie Intake Trend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: 500,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < weeklyData.length) {
                            final date = weeklyData[index].date;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                '${date.month}/${date.day}',
                                style: const TextStyle(fontSize: 10),
                              ),
                            );
                          }
                          return const Text('');
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '${value.toInt()}',
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    // Actual intake line
                    LineChartBarData(
                      spots: weeklyData.asMap().entries.map((entry) {
                        return FlSpot(
                            entry.key.toDouble(), entry.value.totalCalories);
                      }).toList(),
                      isCurved: true,
                      color: Colors.blue,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.blue,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.blue.withOpacity(0.1),
                      ),
                    ),
                    // Target line
                    LineChartBarData(
                      spots: weeklyData.asMap().entries.map((entry) {
                        return FlSpot(entry.key.toDouble(), widget.dailyTarget);
                      }).toList(),
                      isCurved: false,
                      color: Colors.red.withOpacity(0.7),
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      dashArray: [5, 5],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Actual Intake', Colors.blue),
                const SizedBox(width: 20),
                _buildLegendItem('Target Intake', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 3,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildGoalAchievementCard() {
    if (goalStats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Goal Achievement',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: goalStats!.achievementColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: goalStats!.achievementColor.withOpacity(0.3),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        goalStats!.achievementRate >= 70
                            ? Icons.star
                            : Icons.trending_up,
                        color: goalStats!.achievementColor,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            goalStats!.achievementLevel,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: goalStats!.achievementColor,
                            ),
                          ),
                          Text(
                            '${goalStats!.achievementRate.round()}% Achievement Rate',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Achieved Days',
                          '${goalStats!.achievedDays}',
                          'days',
                          Colors.green,
                          Icons.check_circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Best Performance',
                          '${goalStats!.bestDayCalories.round()}',
                          'kcal',
                          Colors.blue,
                          Icons.trending_up,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealDistributionChart() {
    if (mealDistribution.isEmpty) return const SizedBox.shrink();

    final total =
        mealDistribution.values.fold(0.0, (sum, value) => sum + value);
    if (total == 0) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Meal Distribution',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(),
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildMealLegend(),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections() {
    final total =
        mealDistribution.values.fold(0.0, (sum, value) => sum + value);
    final colors = {
      'breakfast': Colors.orange,
      'lunch': Colors.green,
      'dinner': Colors.blue,
      'snack': Colors.purple,
    };

    return mealDistribution.entries.map((entry) {
      final percentage = (entry.value / total) * 100;
      return PieChartSectionData(
        value: entry.value,
        title: '${percentage.round()}%',
        color: colors[entry.key] ?? Colors.grey,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildMealLegend() {
    final mealNames = {
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snack': 'Snacks',
    };
    final colors = {
      'breakfast': Colors.orange,
      'lunch': Colors.green,
      'dinner': Colors.blue,
      'snack': Colors.purple,
    };

    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: mealDistribution.entries.map((entry) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colors[entry.key],
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${mealNames[entry.key]} ${entry.value.round()}kcal',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatsCards() {
    if (goalStats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Average Intake',
                '${goalStats!.averageCalories.round()}',
                'kcal',
                Colors.blue,
                Icons.bar_chart,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Target Gap',
                '${goalStats!.averageGap.round()}',
                'kcal',
                goalStats!.averageGap > 0 ? Colors.red : Colors.green,
                goalStats!.averageGap > 0
                    ? Icons.arrow_upward
                    : Icons.arrow_downward,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFrequentFoodsCard() {
    if (frequentFoods.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Icon(Icons.restaurant, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No food records yet',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Most Frequent Foods',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...frequentFoods.asMap().entries.map((entry) {
              final index = entry.key;
              final food = entry.value;
              return _buildFoodFrequencyItem(food, index + 1);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodFrequencyItem(Map<String, dynamic> food, int rank) {
    final frequency = food['frequency'] as int;
    final totalCalories = food['totalCalories'] as double;
    final avgCalories = food['avgCalories'] as double;
    final category = food['foodCategory'] as String;
    final name = food['foodName'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Rank badge
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getRankColor(rank),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$rank',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Food information
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(category),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Eaten $frequency times',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Calorie information
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${totalCalories.round()}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const Text(
                'total kcal',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'avg ${avgCalories.round()}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDailyRecords() {
    if (weeklyData.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Records',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...weeklyData.reversed
                .map((dayData) => _buildDayCard(dayData))
                .toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDayCard(DailyCalorieData dayData) {
    final isToday = _isToday(dayData.date);
    final progress =
        widget.dailyTarget > 0 ? dayData.totalCalories / widget.dailyTarget : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isToday ? Colors.blue.shade50 : null,
        border: Border.all(
          color: isToday ? Colors.blue.shade200 : Colors.grey.shade200,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getCalorieColor(dayData.totalCalories),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '${dayData.date.day}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(dayData.date),
                      style: TextStyle(
                        fontWeight: isToday ? FontWeight.bold : FontWeight.w500,
                        color: isToday ? Colors.blue : null,
                      ),
                    ),
                    Text(
                      '${dayData.foodCount} food items',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${dayData.totalCalories.round()}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    '${(progress * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      color: progress > 1 ? Colors.red : Colors.green,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Meal distribution bar
          if (dayData.foodCount > 0) ...[
            const SizedBox(height: 8),
            Container(
              height: 6,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(3),
                color: Colors.grey.shade200,
              ),
              child: Row(
                children: _buildMealBars(
                    dayData.mealBreakdown, dayData.totalCalories),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildMealInfo('B', dayData.mealBreakdown['breakfast'] ?? 0,
                    Colors.orange),
                _buildMealInfo(
                    'L', dayData.mealBreakdown['lunch'] ?? 0, Colors.green),
                _buildMealInfo(
                    'D', dayData.mealBreakdown['dinner'] ?? 0, Colors.blue),
                _buildMealInfo(
                    'S', dayData.mealBreakdown['snack'] ?? 0, Colors.purple),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildMealBars(Map<String, double> mealBreakdown, double total) {
    if (total == 0) return [];

    final colors = {
      'breakfast': Colors.orange,
      'lunch': Colors.green,
      'dinner': Colors.blue,
      'snack': Colors.purple,
    };

    return mealBreakdown.entries.map((entry) {
      final percentage = entry.value / total;
      return Expanded(
        flex: (percentage * 100).round(),
        child: Container(
          height: 6,
          decoration: BoxDecoration(
            color: colors[entry.key],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMealInfo(String label, double calories, Color color) {
    return Column(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10),
        ),
        Text(
          '${calories.round()}',
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String title, String value, String unit, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
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
          ],
        ),
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blue;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Staple Food':
        return Colors.orange;
      case 'Protein':
        return Colors.red;
      case 'Vegetables':
        return Colors.green;
      case 'Fruits':
        return Colors.purple;
      case 'Snacks':
        return Colors.brown;
      case 'Beverages':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);

    final difference = today.difference(targetDate).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Yesterday';
    } else if (difference == 2) {
      return '2 days ago';
    } else {
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return '${date.month}/${date.day} ${weekdays[date.weekday - 1]}';
    }
  }

  Color _getCalorieColor(double calories) {
    if (calories == 0) return Colors.grey;
    if (calories < 1200) return Colors.orange;
    if (calories < 2000) return Colors.green;
    if (calories < 2500) return Colors.blue;
    return Colors.red;
  }
}
