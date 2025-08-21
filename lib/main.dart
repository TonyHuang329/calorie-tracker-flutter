// lib/main.dart - 修复版本

import 'package:flutter/material.dart';
import 'services/database_service.dart';
import 'services/ai_food_recognition_service.dart';
import 'services/food_database.dart';
import 'services/food_recommendation_service.dart';
import 'services/quick_add_service.dart';
import 'services/health_goal_service.dart';
import 'services/calorie_calculator.dart';
import 'screens/ai_camera_screen.dart';
import 'screens/add_food_screen.dart';
import 'screens/quick_add_screen.dart';
import 'screens/history_screen.dart';
import 'screens/nutrition_overview_screen.dart';
import 'screens/health_goals_screen.dart';
import 'models/user_profile.dart';
import 'models/food_item.dart';

void main() async {
  print('🚀 Calorie Tracker App starting...');

  // 确保Flutter binding初始化
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 初始化所有服务
    await AIFoodRecognitionService.initialize();
    print('🤖 AI Food Recognition Service initialized');

    // 初始化食物数据库
    FoodDatabaseService.getAllFoods(); // 预加载食物数据
    print('🍎 Food Database Service initialized');

    print('✅ All services initialized successfully');
  } catch (e) {
    print('⚠️  Service initialization warning: $e');
  }

  runApp(CalorieTrackerApp());
}

class CalorieTrackerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker Pro',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
      ),
      home: MainNavigationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  UserProfile? _userProfile;
  List<Widget>? _screens; // 修改为可空类型

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _initializeScreens() {
    if (_screens == null) {
      // 只初始化一次
      _screens = [
        EnhancedHomeScreen(
          userProfile: _userProfile,
          onProfileUpdate: () => _loadUserProfile(),
        ),
        AICameraScreen(),
        AddFoodScreen(onFoodAdded: _onFoodAdded),
        QuickAddScreen(onFoodAdded: _onFoodAdded),
        HistoryScreen(dailyTarget: _userProfile?.calculateTDEE() ?? 2000),
      ];
    } else {
      // 如果已初始化，只更新需要更新的页面
      _screens![0] = EnhancedHomeScreen(
        userProfile: _userProfile,
        onProfileUpdate: () => _loadUserProfile(),
      );
      _screens![4] =
          HistoryScreen(dailyTarget: _userProfile?.calculateTDEE() ?? 2000);
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      final profile = await DatabaseService.getUserProfile();
      if (mounted) {
        setState(() {
          _userProfile = profile;
          _initializeScreens();
        });
      }
    } catch (e) {
      print('Failed to load user profile: $e');
      if (mounted) {
        setState(() {
          _initializeScreens();
        });
      }
    }
  }

  void _onFoodAdded(FoodRecord record) {
    print('Food added: ${record.foodItem?.name}');
    // 刷新主页数据
    if (_selectedIndex == 0) {
      _loadUserProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_screens == null) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens!,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        selectedItemColor: Colors.blue.shade600,
        unselectedItemColor: Colors.grey.shade600,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: 'AI Camera',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Food',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flash_on),
            label: 'Quick Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              onPressed: () => _showQuickActions(),
              child: Icon(Icons.add),
              backgroundColor: Colors.blue.shade600,
            )
          : null,
    );
  }

  void _showQuickActions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildQuickActionTile(
              'AI Camera',
              'Recognize food with AI',
              Icons.camera_alt,
              Colors.orange,
              () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 1);
              },
            ),
            _buildQuickActionTile(
              'Add Food',
              'Manual food entry',
              Icons.restaurant,
              Colors.green,
              () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 2);
              },
            ),
            _buildQuickActionTile(
              'Quick Add',
              'Recent foods & templates',
              Icons.flash_on,
              Colors.blue,
              () {
                Navigator.pop(context);
                setState(() => _selectedIndex = 3);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionTile(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: color.withOpacity(0.1),
        child: Icon(icon, color: color),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}

// 增强版主页，集成所有服务
class EnhancedHomeScreen extends StatefulWidget {
  final UserProfile? userProfile;
  final VoidCallback onProfileUpdate;

  const EnhancedHomeScreen({
    Key? key,
    this.userProfile,
    required this.onProfileUpdate,
  }) : super(key: key);

  @override
  State<EnhancedHomeScreen> createState() => _EnhancedHomeScreenState();
}

class _EnhancedHomeScreenState extends State<EnhancedHomeScreen> {
  List<FoodRecord> todayRecords = [];
  double todayCalories = 0;
  List<String> recommendations = [];
  List<String> favorites = [];
  List<String> recentFoods = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      // 加载今日数据
      final records = await DatabaseService.getTodayFoodRecords();
      final totalCalories = records.fold<double>(
        0,
        (sum, record) => sum + record.totalCalories,
      );

      // 加载个性化推荐（如果有用户配置）
      List<String> recs = [];
      if (widget.userProfile != null) {
        try {
          final recService = FoodRecommendationService.instance;
          final recommendations =
              await recService.getQuickRecommendations(widget.userProfile!);
          recs = recommendations;
        } catch (e) {
          print('Failed to load recommendations: $e');
        }
      }

      // 加载收藏和最近食物
      final quickService = QuickAddService.instance;
      final favs = await quickService.getFavorites();
      final recent = await quickService.getRecentFoods();

      if (mounted) {
        setState(() {
          todayRecords = records;
          todayCalories = totalCalories;
          recommendations = recs;
          favorites = favs;
          recentFoods = recent;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load data: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Calorie Tracker Pro'),
        backgroundColor: Colors.blue.shade50,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.track_changes),
            onPressed: () => _navigateToHealthGoals(),
          ),
          IconButton(
            icon: Icon(Icons.person),
            onPressed: () => _showProfileOptions(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    SizedBox(height: 20),
                    _buildCalorieProgress(),
                    SizedBox(height: 20),
                    _buildServicesStatus(),
                    SizedBox(height: 20),
                    if (recommendations.isNotEmpty) _buildRecommendations(),
                    if (recommendations.isNotEmpty) SizedBox(height: 20),
                    _buildQuickAccessSection(),
                    SizedBox(height: 20),
                    _buildRecentMeals(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.blue.shade400, Colors.blue.shade600],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.white, size: 28),
            SizedBox(height: 12),
            Text(
              widget.userProfile != null
                  ? 'Hello, ${widget.userProfile!.name}!'
                  : 'Welcome to Calorie Tracker Pro',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 4),
            Text(
              widget.userProfile != null
                  ? 'Your AI-powered nutrition companion'
                  : 'Create a profile to unlock personalized features',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieProgress() {
    final targetCalories = widget.userProfile?.calculateTDEE() ?? 2000;
    final progress = (todayCalories / targetCalories).clamp(0.0, 1.0);
    final remaining =
        (targetCalories - todayCalories).clamp(0.0, double.infinity);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Today\'s Progress',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (widget.userProfile != null)
                  Text(
                    'TDEE: ${targetCalories.round()}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
              ],
            ),
            SizedBox(height: 16),
            Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 10,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      progress >= 1.0 ? Colors.green : Colors.blue,
                    ),
                  ),
                ),
                Column(
                  children: [
                    Text(
                      '${todayCalories.round()}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    Text(
                      'calories',
                      style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildProgressStat(
                    'Target', '${targetCalories.round()}', Colors.blue),
                _buildProgressStat('Remaining', '${remaining.round()}',
                    remaining > 0 ? Colors.orange : Colors.green),
                _buildProgressStat('Progress', '${(progress * 100).round()}%',
                    progress >= 1.0 ? Colors.green : Colors.blue),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildServicesStatus() {
    final aiStatus = AIFoodRecognitionService.getStatus();
    final isAIReady = AIFoodRecognitionService.isInitialized;
    final foodDbCount = FoodDatabaseService.getAllFoods().length;

    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Service Status',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            _buildServiceStatusRow(
              'AI Recognition',
              isAIReady
                  ? (aiStatus['has_real_model']
                      ? 'EfficientNet Model'
                      : 'Simulation Mode')
                  : 'Service Unavailable',
              isAIReady
                  ? (aiStatus['has_real_model'] ? Colors.green : Colors.orange)
                  : Colors.red,
              Icons.smart_toy,
            ),
            _buildServiceStatusRow(
              'Food Database',
              '$foodDbCount foods available',
              Colors.blue,
              Icons.restaurant,
            ),
            _buildServiceStatusRow(
              'Recommendations',
              widget.userProfile != null ? 'Personalized' : 'Create profile',
              widget.userProfile != null ? Colors.green : Colors.grey,
              Icons.lightbulb,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceStatusRow(
      String title, String status, Color color, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                Text(
                  status,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
          Icon(
            color == Colors.green
                ? Icons.check_circle
                : color == Colors.orange
                    ? Icons.warning
                    : Icons.info,
            color: color,
            size: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text(
                  'AI Recommendations',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: recommendations
                  .map((food) => Chip(
                        label: Text(food, style: TextStyle(fontSize: 12)),
                        backgroundColor: Colors.orange.shade50,
                        side: BorderSide(color: Colors.orange.shade200),
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Row(
          children: [
            if (favorites.isNotEmpty)
              Expanded(
                  child: _buildQuickAccessCard(
                      'Favorites', favorites, Icons.favorite, Colors.red)),
            if (favorites.isNotEmpty && recentFoods.isNotEmpty)
              SizedBox(width: 12),
            if (recentFoods.isNotEmpty)
              Expanded(
                  child: _buildQuickAccessCard(
                      'Recent', recentFoods, Icons.history, Colors.blue)),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAccessCard(
      String title, List<String> foods, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 16),
                SizedBox(width: 6),
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            SizedBox(height: 8),
            ...foods.take(3).map((food) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: Text(
                    food,
                    style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                    overflow: TextOverflow.ellipsis,
                  ),
                )),
            if (foods.length > 3)
              Text(
                '+${foods.length - 3} more...',
                style: TextStyle(fontSize: 10, color: Colors.grey[500]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentMeals() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Meals',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (todayRecords.isNotEmpty)
                  TextButton(
                    onPressed: () => _navigateToHistory(),
                    child: Text('View All'),
                  ),
              ],
            ),
            SizedBox(height: 8),
            if (todayRecords.isEmpty)
              Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.restaurant_menu,
                          size: 48, color: Colors.grey[400]),
                      SizedBox(height: 8),
                      Text(
                        'No meals logged today',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      Text(
                        'Tap + to add your first meal',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...todayRecords.take(3).map((record) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor:
                          _getMealColor(record.mealType).withOpacity(0.1),
                      child: Icon(_getMealIcon(record.mealType),
                          color: _getMealColor(record.mealType)),
                    ),
                    title: Text(record.foodItem?.name ?? 'Unknown Food'),
                    subtitle: Text(
                        '${record.mealType.toUpperCase()} • ${record.quantity}g'),
                    trailing: Text(
                      '${record.totalCalories.round()} cal',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Color _getMealColor(String mealType) {
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

  IconData _getMealIcon(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_sunny_outlined;
      case 'dinner':
        return Icons.nights_stay;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  void _navigateToHealthGoals() {
    if (widget.userProfile != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) =>
              HealthGoalsScreen(userProfile: widget.userProfile!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please create a profile first'),
          action: SnackBarAction(
            label: 'Create',
            onPressed: () => _showProfileDialog(),
          ),
        ),
      );
    }
  }

  void _navigateToHistory() {
    final mainScreen =
        context.findAncestorStateOfType<_MainNavigationScreenState>();
    if (mainScreen != null) {
      mainScreen.setState(() {
        mainScreen._selectedIndex = 4;
      });
    }
  }

  void _showProfileOptions() {
    if (widget.userProfile != null) {
      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.person),
                title: Text('View Profile'),
                subtitle: Text(widget.userProfile!.name),
                onTap: () {
                  Navigator.pop(context);
                  _showProfileDialog();
                },
              ),
              ListTile(
                leading: Icon(Icons.pie_chart),
                title: Text('Nutrition Overview'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NutritionOverviewScreen(
                        userProfile: widget.userProfile!,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      );
    } else {
      _showProfileDialog();
    }
  }

  void _showProfileDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleProfileDialog(
        existingProfile: widget.userProfile,
        onProfileSaved: (profile) {
          widget.onProfileUpdate();
          _loadAllData();
        },
      ),
    );
  }
}

// 简化的用户配置对话框
class SimpleProfileDialog extends StatefulWidget {
  final UserProfile? existingProfile;
  final Function(UserProfile) onProfileSaved;

  const SimpleProfileDialog({
    Key? key,
    this.existingProfile,
    required this.onProfileSaved,
  }) : super(key: key);

  @override
  State<SimpleProfileDialog> createState() => _SimpleProfileDialogState();
}

class _SimpleProfileDialogState extends State<SimpleProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  String _selectedGender = 'male';
  String _selectedActivityLevel = 'moderate';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingProfile != null) {
      _loadExistingProfile();
    }
  }

  void _loadExistingProfile() {
    final profile = widget.existingProfile!;
    _nameController.text = profile.name;
    _ageController.text = profile.age.toString();
    _heightController.text = profile.height.toString();
    _weightController.text = profile.weight.toString();
    _selectedGender = profile.gender;
    _selectedActivityLevel = profile.activityLevel;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
          widget.existingProfile != null ? 'Edit Profile' : 'Create Profile'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _ageController,
                      decoration: InputDecoration(labelText: 'Age'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final age = int.tryParse(value);
                        if (age == null || age < 10 || age > 120) {
                          return 'Invalid age';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedGender,
                      decoration: InputDecoration(labelText: 'Gender'),
                      items: [
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'female', child: Text('Female')),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedGender = value!),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _heightController,
                      decoration: InputDecoration(labelText: 'Height (cm)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final height = double.tryParse(value);
                        if (height == null || height < 100 || height > 250) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: InputDecoration(labelText: 'Weight (kg)'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Required';
                        }
                        final weight = double.tryParse(value);
                        if (weight == null || weight < 30 || weight > 300) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedActivityLevel,
                decoration: InputDecoration(labelText: 'Activity Level'),
                items: [
                  DropdownMenuItem(
                      value: 'sedentary', child: Text('Sedentary')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'moderate', child: Text('Moderate')),
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(
                      value: 'very_active', child: Text('Very Active')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedActivityLevel = value!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _saveProfile,
          child: _isLoading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Save'),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final profile = UserProfile(
        id: widget.existingProfile?.id,
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        gender: _selectedGender,
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        activityLevel: _selectedActivityLevel,
        createdAt: widget.existingProfile?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // 使用正确的数据库方法
      await DatabaseService.saveUserProfile(profile);

      if (mounted) {
        widget.onProfileSaved(profile);
        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Profile ${widget.existingProfile != null ? 'updated' : 'created'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error saving profile: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }
}
