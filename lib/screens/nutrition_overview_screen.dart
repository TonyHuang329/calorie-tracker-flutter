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
    // Calculate recommended nutrition goals based on user information
    final tdee = widget.userProfile.calculateTDEE();

    nutritionGoals = {
      'calories': tdee,
      'protein':
          widget.userProfile.weight * 1.2, // 1.2g protein per kg body weight
      'carbs': tdee * 0.5 / 4, // 50% from carbohydrates, 4 calories per gram
      'fat': tdee * 0.3 / 9, // 30% from fat, 9 calories per gram
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
      print('Failed to load nutrition data: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nutrition Overview'),
        backgroundColor: Colors.purple.shade50,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.pie_chart), text: 'Today\'s Nutrition'),
            Tab(icon: Icon(Icons.trending_up), text: 'Nutrition Trends'),
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
          // Nutrition composition pie chart
          _buildNutritionPieChart(),
          const SizedBox(height: 20),

          // Nutrition goal progress
          _buildNutritionProgress(),
          const SizedBox(height: 20),

          // Nutrition advice
          _buildNutritionAdvice(),
          const SizedBox(height: 20),

          // Today's food breakdown
          _buildTodayFoodBreakdown(),
        ],
      ),
    );
  }

  Widget _buildNutritionTrendsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 7-day nutrition trends
        _build7DayNutritionTrend(),
        const SizedBox(height: 20),

        // Nutrition balance score
        _buildNutritionScore(),
        const SizedBox(height: 20),

        // Improvement suggestions
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
            'No food records for today',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some foods to view nutrition analysis',
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
                  'Nutrition Composition',
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
                  // Pie chart
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

                  // Legend
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLegendItem('Protein', Colors.red,
                            todayNutrition!.totalProtein, 'g'),
                        const SizedBox(height: 12),
                        _buildLegendItem('Carbohydrates', Colors.amber,
                            todayNutrition!.totalCarbs, 'g'),
                        const SizedBox(height: 12),
                        _buildLegendItem('Fat', Colors.purple,
                            todayNutrition!.totalFat, 'g'),
                        const SizedBox(height: 12),
                        _buildLegendItem('Total Calories', Colors.green,
                            todayNutrition!.totalCalories, 'kcal'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Nutrition ratio display
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
                    'Protein',
                    '${todayNutrition!.proteinPercentage.round()}%',
                    Colors.red,
                    _isHealthyPercentage(
                        todayNutrition!.proteinPercentage, 10, 35),
                  ),
                  _buildPercentageItem(
                    'Carbs',
                    '${todayNutrition!.carbsPercentage.round()}%',
                    Colors.amber,
                    _isHealthyPercentage(
                        todayNutrition!.carbsPercentage, 45, 65),
                  ),
                  _buildPercentageItem(
                    'Fat',
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
          title: 'No Data',
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
                  'Nutrition Goal Progress',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildProgressBar(
              'Calories',
              todayNutrition!.totalCalories,
              nutritionGoals['calories']!,
              'kcal',
              Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Protein',
              todayNutrition!.totalProtein,
              nutritionGoals['protein']!,
              'g',
              Colors.red,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Carbohydrates',
              todayNutrition!.totalCarbs,
              nutritionGoals['carbs']!,
              'g',
              Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildProgressBar(
              'Fat',
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
      advice.add(
          'Protein intake is low, consider adding chicken breast, fish, or beans');
    } else if (todayNutrition!.proteinPercentage > 35) {
      advice.add('Protein intake is high, maintain nutritional balance');
    }

    if (todayNutrition!.carbsPercentage < 45) {
      advice.add(
          'Carbohydrate intake is low, add whole grains and fruits moderately');
    } else if (todayNutrition!.carbsPercentage > 65) {
      advice.add(
          'Carbohydrate intake is high, reduce refined sugars and processed foods');
    }

    if (todayNutrition!.fatPercentage < 20) {
      advice.add(
          'Fat intake is low, consider adding nuts and healthy oils moderately');
    } else if (todayNutrition!.fatPercentage > 35) {
      advice.add('Fat intake is high, reduce fried and high-fat foods');
    }

    if (advice.isEmpty) {
      advice.add('Nutrition ratios are well balanced, keep it up!');
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
                  'Nutrition Advice',
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

    // Group by meal type
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
                  'Today\'s Food Details',
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
      'breakfast': 'Breakfast',
      'lunch': 'Lunch',
      'dinner': 'Dinner',
      'snack': 'Snacks',
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
    // This can implement 7-day nutrition trend chart
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '7-Day Nutrition Trends',
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
                  '7-Day Trend Chart\n(To be implemented)',
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

    // Calculate nutrition balance score
    if (todayNutrition!.isHealthyBalance) {
      score += 40;
    }

    // Calorie goal achievement
    final calorieProgress =
        todayNutrition!.totalCalories / nutritionGoals['calories']!;
    if (calorieProgress >= 0.8 && calorieProgress <= 1.2) {
      score += 30;
    }

    // Adequate protein
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
              'Nutrition Balance Score',
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
                    'points / 100',
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
    if (score >= 80) return 'Excellent nutrition balance!';
    if (score >= 60) return 'Good, keep improving!';
    return 'Needs improvement in nutrition balance';
  }

  Widget _buildImprovementSuggestions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Improvement Suggestions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildSuggestionItem(
              'Increase vegetable intake',
              'Include at least one serving of leafy greens per meal',
              Icons.eco,
              Colors.green,
            ),
            _buildSuggestionItem(
              'Choose quality protein',
              'Fish, lean meat, and legumes are excellent choices',
              Icons.egg,
              Colors.red,
            ),
            _buildSuggestionItem(
              'Control processed foods',
              'Reduce high-sugar, high-sodium processed foods',
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
