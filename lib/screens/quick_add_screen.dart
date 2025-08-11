// lib/screens/quick_add_screen.dart - Translated version
import 'package:flutter/material.dart';
import '../models/food_item.dart';
import '../services/quick_add_service.dart';
import '../services/food_database.dart';

class QuickAddScreen extends StatefulWidget {
  final Function(FoodRecord) onFoodAdded;

  const QuickAddScreen({
    super.key,
    required this.onFoodAdded,
  });

  @override
  State<QuickAddScreen> createState() => _QuickAddScreenState();
}

class _QuickAddScreenState extends State<QuickAddScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  List<String> _recentFoods = [];
  List<String> _favoriteFoods = [];
  List<MealTemplate> _mealTemplates = [];
  List<FoodItem> _searchResults = [];
  String _selectedMealType = 'breakfast';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _selectedMealType = _getMealTypeFromTime();
    _loadData();
    _searchController.addListener(_performSearch);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final recent = await QuickAddService.instance.getRecentFoods();
      final favorites = await QuickAddService.instance.getFavorites();
      final templates = await QuickAddService.instance.getAllTemplates();

      if (mounted) {
        setState(() {
          _recentFoods = recent;
          _favoriteFoods = favorites;
          _mealTemplates = templates;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Failed to load data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _performSearch() {
    final query = _searchController.text;
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }

    final allFoods = FoodDatabaseService.getAllFoods();
    final results = QuickAddService.instance.smartSearch(query, allFoods);

    setState(() => _searchResults = results.take(20).toList());
  }

  String _getMealTypeFromTime() {
    final hour = DateTime.now().hour;
    if (hour < 10) return 'breakfast';
    if (hour < 14) return 'lunch';
    if (hour < 18) return 'snack';
    return 'dinner';
  }

  void _quickAddFood(String foodName, {double? customQuantity}) {
    try {
      final allFoods = FoodDatabaseService.getAllFoods();
      final food = allFoods.firstWhere(
        (f) => f.name == foodName,
        orElse: () => throw Exception('Food not found: $foodName'),
      );

      final quantity =
          customQuantity ?? FoodDatabaseService.getRecommendedServing(food);
      final totalCalories =
          FoodDatabaseService.calculateCalories(food, quantity);

      final record = FoodRecord(
        foodItemId: food.id ?? 0,
        foodItem: food,
        quantity: quantity,
        totalCalories: totalCalories,
        mealType: _selectedMealType,
      );

      widget.onFoodAdded(record);

      // Add to favorites (optional)
      QuickAddService.instance.addToFavorites(foodName);

      _showSuccessMessage('Added $foodName');
    } catch (e) {
      _showErrorMessage('Add failed: ${e.toString()}');
    }
  }

  void _showQuantityDialog(String foodName) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final food = allFoods.firstWhere((f) => f.name == foodName);
    final suggestions = QuickAddService.instance.getQuantitySuggestions(food);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Select quantity for $foodName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Recommended quantity:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: suggestions
                  .map(
                    (quantity) => GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        _quickAddFood(foodName, customQuantity: quantity);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${quantity.round()}${food.unit}',
                          style: TextStyle(
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Future<void> _applyMealTemplate(MealTemplate template) async {
    try {
      final records = await QuickAddService.instance
          .applyTemplate(template.name, _selectedMealType);

      for (var record in records) {
        widget.onFoodAdded(record);
      }

      _showSuccessMessage(
          'Applied template: ${template.name} (${records.length} items)');
    } catch (e) {
      _showErrorMessage('Failed to apply template: ${e.toString()}');
    }
  }

  void _showSuccessMessage(String message) {
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

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Add'),
        backgroundColor: Colors.orange.shade50,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top control area
          Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search box
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search food... (supports pinyin)',
                    prefixIcon:
                        Icon(Icons.search, color: Colors.orange.shade600),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
                const SizedBox(height: 12),

                // Meal selection
                Row(
                  children: [
                    Icon(Icons.restaurant_menu,
                        color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text('Meal:',
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedMealType,
                          isExpanded: true,
                          underline: const SizedBox(),
                          onChanged: (value) {
                            setState(() => _selectedMealType = value!);
                          },
                          items: const [
                            DropdownMenuItem(
                                value: 'breakfast',
                                child: Text('🌅 Breakfast')),
                            DropdownMenuItem(
                                value: 'lunch', child: Text('☀️ Lunch')),
                            DropdownMenuItem(
                                value: 'dinner', child: Text('🌙 Dinner')),
                            DropdownMenuItem(
                                value: 'snack', child: Text('🍪 Snacks')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange.shade600,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange.shade600,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.history), text: 'Recent'),
                Tab(icon: Icon(Icons.favorite), text: 'Favorites'),
                Tab(icon: Icon(Icons.restaurant), text: 'Templates'),
                Tab(icon: Icon(Icons.search), text: 'Search'),
              ],
            ),
          ),

          // Content area
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildRecentTab(),
                      _buildFavoritesTab(),
                      _buildTemplatesTab(),
                      _buildSearchTab(),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTab() {
    if (_recentFoods.isEmpty) {
      return _buildEmptyState('No recent foods yet',
          'Recently added foods will appear here after you start tracking your diet');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentFoods.length,
      itemBuilder: (context, index) {
        final foodName = _recentFoods[index];
        return _buildFoodTile(
          foodName,
          subtitle: 'Recently added',
          onTap: () => _quickAddFood(foodName),
          onLongPress: () => _showQuantityDialog(foodName),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteFoods.isEmpty) {
      return _buildEmptyState('No favorite foods yet',
          'Foods will be automatically favorited when added, long press to adjust quantity');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteFoods.length,
      itemBuilder: (context, index) {
        final foodName = _favoriteFoods[index];
        return _buildFoodTile(
          foodName,
          subtitle: 'Favorite food',
          onTap: () => _quickAddFood(foodName),
          onLongPress: () => _showQuantityDialog(foodName),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () async {
              await QuickAddService.instance.removeFromFavorites(foodName);
              _loadData();
              _showSuccessMessage('Removed from favorites');
            },
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    if (_mealTemplates.isEmpty) {
      return _buildEmptyState('No meal templates yet',
          'You can save common meal combinations as templates\n(This feature will be available in future versions)');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mealTemplates.length,
      itemBuilder: (context, index) {
        final template = _mealTemplates[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.restaurant, color: Colors.orange.shade600),
            ),
            title: Text(
              template.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${template.foods.length} food items'),
                Text('${template.totalCalories.round()} kcal'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle,
                      color: Colors.green, size: 20),
                  onPressed: () => _applyMealTemplate(template),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.red, size: 20),
                  onPressed: () async {
                    final confirmed = await _showConfirmDialog(
                        'Delete template "${template.name}"?');
                    if (confirmed) {
                      await QuickAddService.instance
                          .deleteMealTemplate(template.name);
                      _loadData();
                      _showSuccessMessage('Template deleted');
                    }
                  },
                ),
              ],
            ),
            onTap: () => _showTemplateDetails(template),
          ),
        );
      },
    );
  }

  Widget _buildSearchTab() {
    if (_searchController.text.isEmpty) {
      return _buildEmptyState('Enter food name to search',
          'Supports Chinese names and pinyin search\nExample: Enter "pg" to find "Apple"');
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState('No matching foods found',
          'Try other keywords or pinyin abbreviations');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final food = _searchResults[index];
        return _buildFoodTile(
          food.name,
          subtitle:
              '${food.category} • ${food.caloriesPerUnit.toStringAsFixed(1)} kcal/${food.unit}',
          onTap: () => _quickAddFood(food.name),
          onLongPress: () => _showQuantityDialog(food.name),
        );
      },
    );
  }

  Widget _buildFoodTile(
    String foodName, {
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
    Widget? trailing,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _getCategoryColor(foodName),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _getCategoryIcon(foodName),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          foodName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        trailing: trailing ??
            const Icon(Icons.add_circle_outline, color: Colors.green),
        onTap: onTap,
        onLongPress: onLongPress,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.food_bank_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _showTemplateDetails(MealTemplate template) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(template.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total calories: ${template.totalCalories.round()} kcal'),
            const SizedBox(height: 12),
            const Text('Contains foods:',
                style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ...template.foods
                .map((food) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                          '• ${food['foodName']} ${food['quantity']}${food['unit']}'),
                    ))
                .toList(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyMealTemplate(template);
            },
            child: const Text('Apply Template'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirm'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Color _getCategoryColor(String foodName) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final food = allFoods.firstWhere(
      (f) => f.name == foodName,
      orElse: () => FoodItem(
          name: foodName, caloriesPerUnit: 1, unit: 'g', category: 'Other'),
    );

    switch (food.category) {
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

  IconData _getCategoryIcon(String foodName) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final food = allFoods.firstWhere(
      (f) => f.name == foodName,
      orElse: () => FoodItem(
          name: foodName, caloriesPerUnit: 1, unit: 'g', category: 'Other'),
    );

    switch (food.category) {
      case 'Staple Food':
        return Icons.rice_bowl;
      case 'Protein':
        return Icons.egg;
      case 'Vegetables':
        return Icons.eco;
      case 'Fruits':
        return Icons.apple;
      case 'Snacks':
        return Icons.cookie;
      case 'Beverages':
        return Icons.local_drink;
      default:
        return Icons.restaurant;
    }
  }
}
