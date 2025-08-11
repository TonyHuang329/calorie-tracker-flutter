import 'package:flutter/material.dart';
import 'models/user_profile.dart';
import 'models/food_item.dart';
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
      title: 'Calorie Tracker',
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

  // Recommendation related variables
  List<String> _quickRecommendations = [];
  bool _isLoadingRecommendations = false;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  // Calculate current calorie intake
  double get currentCalorieIntake {
    return todayFoodRecords.fold(
        0.0, (sum, record) => sum + record.totalCalories);
  }

  // Get today's nutrition summary
  Map<String, double> get todayNutritionSummary {
    double protein = 0, carbs = 0, fat = 0;

    for (var record in todayFoodRecords) {
      final quantity = record.quantity;
      final category = record.foodItem?.category ?? '';

      // Estimate nutrition based on food category
      switch (category) {
        case 'Protein':
          protein += quantity * 0.25;
          carbs += quantity * 0.02;
          fat += quantity * 0.08;
          break;
        case 'Staple Food':
          protein += quantity * 0.08;
          carbs += quantity * 0.75;
          fat += quantity * 0.02;
          break;
        case 'Vegetables':
          protein += quantity * 0.025;
          carbs += quantity * 0.06;
          fat += quantity * 0.005;
          break;
        case 'Fruits':
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

  // Initialize app
  Future<void> _initializeApp() async {
    await _loadUserData();
    await _loadTodayFoodRecords();
    _loadQuickRecommendations();
  }

  // Load user data
  Future<void> _loadUserData() async {
    try {
      final savedUser = await DatabaseService.getUserProfile();

      if (savedUser != null) {
        currentUser = savedUser;
      } else {
        // Create default user
        currentUser = UserProfile(
          name: 'User',
          age: 25,
          gender: 'male',
          height: 170,
          weight: 65,
          activityLevel: 'moderate',
        );
        await DatabaseService.saveUserProfile(currentUser!);
      }
    } catch (e) {
      _handleError('Failed to load user data', e);
      // Use default user data
      currentUser = UserProfile(
        name: 'User',
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

  // Load today's food records
  Future<void> _loadTodayFoodRecords() async {
    try {
      final records = await DatabaseService.getTodayFoodRecords();
      if (mounted) {
        setState(() => todayFoodRecords = records);
      }
    } catch (e) {
      _handleError('Failed to load today\'s food records', e);
    }
  }

  // Load quick recommendations
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
      print('Failed to load quick recommendations: $e');
      if (mounted) {
        setState(() => _isLoadingRecommendations = false);
      }
    }
  }

  // Add food record
  Future<void> _addFoodRecord(FoodRecord record) async {
    try {
      await DatabaseService.saveFoodRecord(record);

      if (mounted) {
        setState(() => todayFoodRecords.add(record));
        _showSuccessMessage(
            'Added ${record.foodItem?.name} (${record.totalCalories.round()} calories)');
        // Reload recommendations
        _loadQuickRecommendations();
      }
    } catch (e) {
      _handleError('Failed to save food record', e);
    }
  }

  // Delete food record
  Future<void> _removeFoodRecord(int index) async {
    try {
      final record = todayFoodRecords[index];

      if (record.id != null) {
        await DatabaseService.deleteFoodRecord(record.id!);
      }

      if (mounted) {
        setState(() => todayFoodRecords.removeAt(index));
        _showInfoMessage('Food record deleted');
        // Reload recommendations
        _loadQuickRecommendations();
      }
    } catch (e) {
      _handleError('Failed to delete food record', e);
    }
  }

  // Update user profile
  Future<void> _updateUserProfile(UserProfile newProfile) async {
    try {
      await DatabaseService.saveUserProfile(newProfile);

      if (mounted) {
        setState(() => currentUser = newProfile);
        _showSuccessMessage('Profile saved');
        // Reload recommendations
        _loadQuickRecommendations();
      }
    } catch (e) {
      _handleError('Failed to save user profile', e);
    }
  }

  // Quick add recommended food
  void _quickAddRecommendedFood(String foodName) {
    try {
      // Find corresponding food from database
      final allFoods = FoodDatabaseService.getAllFoods();
      final food = allFoods.firstWhere(
        (f) => f.name == foodName,
        orElse: () => throw Exception('Food not found: $foodName'),
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
      _showErrorMessage('Add failed: ${e.toString()}');
    }
  }

  // Navigation methods
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

  void _navigateToQuickAdd() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => QuickAddScreen(onFoodAdded: _addFoodRecord),
      ),
    );
  }

  // Intelligently select meal type based on time
  String _getMealTypeFromTime() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 18) return 'snack';
    return 'dinner';
  }

  // Message prompt methods
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
    _showErrorMessage('$message, please try again');
  }

  // Debug functionality
  Future<void> _clearAllData() async {
    final confirmed =
        await _showConfirmDialog('Are you sure you want to clear all data?');
    if (confirmed) {
      try {
        await DatabaseService.clearAllData();
        if (mounted) {
          setState(() => todayFoodRecords.clear());
          _showInfoMessage('All data cleared');
          _loadQuickRecommendations();
        }
      } catch (e) {
        _handleError('Failed to clear data', e);
      }
    }
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Confirm'),
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

            // Smart recommendation card
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
        label: const Text('Add Food'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calorie Tracker'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading data...'),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Calorie Tracker'),
      backgroundColor: Colors.blue.shade50,
      elevation: 0,
      actions: [
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            switch (value) {
              case 'stats':
                final stats = await DatabaseService.getDatabaseStats();
                _showInfoMessage(
                    'Data Statistics: ${stats['foodRecords']} records');
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
                  Text('Data Statistics'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'clear',
              child: Row(
                children: [
                  Icon(Icons.delete_sweep, size: 20),
                  SizedBox(width: 8),
                  Text('Clear Data'),
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
                    'Hello, ${currentUser!.name}!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${currentUser!.age} years • ${currentUser!.gender == 'male' ? 'Male' : 'Female'} • ${currentUser!.height.round()}cm • ${currentUser!.weight.round()}kg',
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
              tooltip: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayGoalCard(double targetCalories) {
    final now = DateTime.now();
    final timeOfDay = now.hour < 12
        ? 'Good morning'
        : (now.hour < 18 ? 'Good afternoon' : 'Good evening');

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
                    '$timeOfDay! Today\'s Goal',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Let\'s start recording today\'s diet, goal: ${targetCalories.round()} kcal',
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
              'Today\'s Calorie Progress',
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

  Widget _buildQuickRecommendationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🤖 AI Recommendations',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (_isLoadingRecommendations)
              const Center(child: CircularProgressIndicator())
            else if (_quickRecommendations.isNotEmpty)
              ...(_quickRecommendations.map((food) => ListTile(
                    title: Text(food),
                    trailing: IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => _quickAddRecommendedFood(food),
                    ),
                  )))
            else
              const Text('No recommendations available'),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStatsCard(
      double targetCalories, Map<String, double> nutrition) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Overview',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text('Target: ${targetCalories.round()} kcal'),
            Text('Consumed: ${currentCalorieIntake.round()} kcal'),
            Text('Food items: ${todayFoodRecords.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayFoodCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Today\'s Food Records',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...todayFoodRecords.asMap().entries.map((entry) {
              final index = entry.key;
              final record = entry.value;
              return ListTile(
                title: Text(record.foodItem?.name ?? 'Unknown'),
                subtitle: Text(
                    '${record.quantity}${record.foodItem?.unit} • ${_getMealTypeName(record.mealType)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${record.totalCalories.round()} kcal'),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _removeFoodRecord(index),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                _buildActionTile('Add Food', Icons.add_circle, Colors.green,
                    _navigateToAddFood),
                _buildActionTile('Quick Add', Icons.flash_on, Colors.orange,
                    _navigateToQuickAdd),
                _buildActionTile('Nutrition Analysis', Icons.pie_chart,
                    Colors.blue, _navigateToNutritionOverview),
                _buildActionTile('View History', Icons.history, Colors.purple,
                    _navigateToHistory),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Settings & Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Personal Settings'),
              subtitle: const Text('Modify personal information and goals'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _navigateToSettings,
            ),
          ],
        ),
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

  // Helper methods
  String _getMealTypeName(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snack';
      default:
        return 'Unknown';
    }
  }
}
