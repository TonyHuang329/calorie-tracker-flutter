// lib/screens/quick_add_screen.dart - 修复版
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
      print('加载数据失败: $e');
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
        orElse: () => throw Exception('未找到食物: $foodName'),
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

      // 添加到收藏夹（可选）
      QuickAddService.instance.addToFavorites(foodName);

      _showSuccessMessage('已添加 $foodName');
    } catch (e) {
      _showErrorMessage('添加失败：${e.toString()}');
    }
  }

  void _showQuantityDialog(String foodName) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final food = allFoods.firstWhere((f) => f.name == foodName);
    final suggestions = QuickAddService.instance.getQuantitySuggestions(food);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('选择 $foodName 的数量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('推荐数量：', style: TextStyle(fontWeight: FontWeight.w500)),
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
            child: const Text('取消'),
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

      _showSuccessMessage('已添加模板：${template.name} (${records.length}项食物)');
    } catch (e) {
      _showErrorMessage('应用模板失败：${e.toString()}');
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
        title: const Text('快速添加'),
        backgroundColor: Colors.orange.shade50,
        elevation: 0,
        // 移除 bottom，改为在 body 中处理
      ),
      body: Column(
        children: [
          // 顶部控制区域
          Container(
            color: Colors.orange.shade50,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // 搜索框
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: '搜索食物... (支持拼音)',
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

                // 餐次选择
                Row(
                  children: [
                    Icon(Icons.restaurant_menu,
                        color: Colors.orange.shade600, size: 20),
                    const SizedBox(width: 8),
                    const Text('餐次:',
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
                                value: 'breakfast', child: Text('🌅 早餐')),
                            DropdownMenuItem(
                                value: 'lunch', child: Text('☀️ 午餐')),
                            DropdownMenuItem(
                                value: 'dinner', child: Text('🌙 晚餐')),
                            DropdownMenuItem(
                                value: 'snack', child: Text('🍪 零食')),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Tab栏
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.orange.shade600,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.orange.shade600,
              indicatorWeight: 3,
              tabs: const [
                Tab(icon: Icon(Icons.history), text: '最近'),
                Tab(icon: Icon(Icons.favorite), text: '收藏'),
                Tab(icon: Icon(Icons.restaurant), text: '模板'),
                Tab(icon: Icon(Icons.search), text: '搜索'),
              ],
            ),
          ),

          // 内容区域
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
      return _buildEmptyState('暂无最近添加的食物', '开始记录饮食后，这里会显示最近吃过的食物');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _recentFoods.length,
      itemBuilder: (context, index) {
        final foodName = _recentFoods[index];
        return _buildFoodTile(
          foodName,
          subtitle: '最近添加',
          onTap: () => _quickAddFood(foodName),
          onLongPress: () => _showQuantityDialog(foodName),
        );
      },
    );
  }

  Widget _buildFavoritesTab() {
    if (_favoriteFoods.isEmpty) {
      return _buildEmptyState('暂无收藏的食物', '添加食物时会自动收藏，长按可调整数量');
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _favoriteFoods.length,
      itemBuilder: (context, index) {
        final foodName = _favoriteFoods[index];
        return _buildFoodTile(
          foodName,
          subtitle: '收藏的食物',
          onTap: () => _quickAddFood(foodName),
          onLongPress: () => _showQuantityDialog(foodName),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () async {
              await QuickAddService.instance.removeFromFavorites(foodName);
              _loadData();
              _showSuccessMessage('已从收藏夹移除');
            },
          ),
        );
      },
    );
  }

  Widget _buildTemplatesTab() {
    if (_mealTemplates.isEmpty) {
      return _buildEmptyState('暂无餐次模板', '您可以保存常用的餐次组合作为模板\n(此功能未来版本开放)');
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
                Text('${template.foods.length} 种食物'),
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
                        '确定删除模板 "${template.name}" 吗？');
                    if (confirmed) {
                      await QuickAddService.instance
                          .deleteMealTemplate(template.name);
                      _loadData();
                      _showSuccessMessage('已删除模板');
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
      return _buildEmptyState('输入食物名称开始搜索', '支持中文名称、拼音搜索\n例如：输入"pg"可以找到"苹果"');
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState('未找到相关食物', '试试其他关键词或拼音缩写');
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
            Text('总卡路里: ${template.totalCalories.round()} kcal'),
            const SizedBox(height: 12),
            const Text('包含食物:', style: TextStyle(fontWeight: FontWeight.w500)),
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
            child: const Text('关闭'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _applyMealTemplate(template);
            },
            child: const Text('应用模板'),
          ),
        ],
      ),
    );
  }

  Future<bool> _showConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('确认'),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('确定'),
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
          name: foodName, caloriesPerUnit: 1, unit: 'g', category: '其他'),
    );

    switch (food.category) {
      case '主食':
        return Colors.orange;
      case '蛋白质':
        return Colors.red;
      case '蔬菜':
        return Colors.green;
      case '水果':
        return Colors.purple;
      case '零食':
        return Colors.brown;
      case '饮品':
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
          name: foodName, caloriesPerUnit: 1, unit: 'g', category: '其他'),
    );

    switch (food.category) {
      case '主食':
        return Icons.rice_bowl;
      case '蛋白质':
        return Icons.egg;
      case '蔬菜':
        return Icons.eco;
      case '水果':
        return Icons.apple;
      case '零食':
        return Icons.cookie;
      case '饮品':
        return Icons.local_drink;
      default:
        return Icons.restaurant;
    }
  }
}
