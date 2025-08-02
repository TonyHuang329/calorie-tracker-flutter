// lib/screens/add_food_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/food_item.dart';
import '../services/food_database.dart';

class AddFoodScreen extends StatefulWidget {
  final Function(FoodRecord) onFoodAdded;

  const AddFoodScreen({
    super.key,
    required this.onFoodAdded,
  });

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _quantityController =
      TextEditingController(text: '100');

  List<FoodItem> _allFoods = [];
  List<FoodItem> _filteredFoods = [];
  FoodItem? _selectedFood;
  String _selectedMealType = 'breakfast';
  double _quantity = 100.0;
  List<FoodRecord> _addedRecords = []; // 存储已Add的食物记录

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadFoods();
    _searchController.addListener(_filterFoods);
    _quantityController.addListener(_updateQuantity);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _loadFoods() {
    _allFoods = FoodDatabaseService.getAllFoods();
    _filteredFoods = _allFoods;
    setState(() {});
  }

  void _filterFoods() {
    final query = _searchController.text;
    _filteredFoods = FoodDatabaseService.searchFoods(query);
    setState(() {});
  }

  void _updateQuantity() {
    final text = _quantityController.text;
    _quantity = double.tryParse(text) ?? 100.0;
    setState(() {});
  }

  void _selectFood(FoodItem food) {
    setState(() {
      _selectedFood = food;
      // Settings推荐数量
      final recommended = FoodDatabaseService.getRecommendedServing(food);
      _quantityController.text = recommended.toString();
      _quantity = recommended;
    });
  }

  void _setRecommendedAmount() {
    if (_selectedFood != null) {
      final recommended =
          FoodDatabaseService.getRecommendedServing(_selectedFood!);
      _quantityController.text = recommended.toString();
      _updateQuantity();
    }
  }

  void _addFoodRecord() {
    if (_selectedFood == null) {
      _showErrorMessage('请选择一个食物');
      return;
    }

    if (_quantity <= 0) {
      _showErrorMessage('请输入有效的数量');
      return;
    }

    final totalCalories =
        FoodDatabaseService.calculateCalories(_selectedFood!, _quantity);

    final foodRecord = FoodRecord(
      foodItemId: _selectedFood!.id ?? 0,
      foodItem: _selectedFood,
      quantity: _quantity,
      totalCalories: totalCalories,
      mealType: _selectedMealType,
    );

    // Add到本地记录列表
    setState(() {
      _addedRecords.add(foodRecord);
      _selectedFood = null; // 清除选择，方便继续Add
    });

    // 调用回调函数Save到数据库
    widget.onFoodAdded(foodRecord);

    // 显示成功提示
    _showSuccessMessage(
        '${foodRecord.foodItem?.name} 已Add (${totalCalories.round()} 卡路里)');

    // 保持在当前食物选择页面，不跳转
  }

  void _removeAddedRecord(int index) {
    setState(() {
      _addedRecords.removeAt(index);
    });
    _showInfoMessage('已移除食物记录');
  }

  void _finishAdding() {
    Navigator.of(context).pop();
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

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _showQuantityDialog() {
    if (_selectedFood == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Settings ${_selectedFood!.name} 的数量'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: InputDecoration(
                labelText: '数量',
                suffixText: _selectedFood!.unit,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickAmountButton('50'),
                _buildQuickAmountButton('100'),
                _buildQuickAmountButton('150'),
                _buildQuickAmountButton('200'),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    '${(_selectedFood!.caloriesPerUnit * _quantity).round()} 卡路里',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    '${_quantity}${_selectedFood!.unit}',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _addFoodRecord();
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAmountButton(String amount) {
    return GestureDetector(
      onTap: () {
        _quantityController.text = amount;
        _updateQuantity();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          amount,
          style: TextStyle(
            color: Colors.blue.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        actions: [
          if (_addedRecords.isNotEmpty)
            TextButton.icon(
              onPressed: _finishAdding,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text('完成', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.add_circle_outline),
              text: '选择食物',
            ),
            Tab(
              icon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.playlist_add_check),
                  if (_addedRecords.isNotEmpty) ...[
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${_addedRecords.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              text: '已Add',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFoodSelectionTab(),
          _buildAddedRecordsTab(),
        ],
      ),
    );
  }

  Widget _buildFoodSelectionTab() {
    return Stack(
      children: [
        Column(
          children: [
            // 顶部Search和餐次选择
            Container(
              color: Colors.green.shade50,
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // Search栏
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search食物名称或分类...',
                      prefixIcon:
                          Icon(Icons.search, color: Colors.green.shade600),
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
                          color: Colors.green.shade600, size: 20),
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
                              setState(() {
                                _selectedMealType = value!;
                              });
                            },
                            items: const [
                              DropdownMenuItem(
                                value: 'breakfast',
                                child: Row(
                                  children: [
                                    Icon(Icons.wb_sunny,
                                        color: Colors.orange, size: 16),
                                    SizedBox(width: 8),
                                    Text('Breakfast'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'lunch',
                                child: Row(
                                  children: [
                                    Icon(Icons.wb_sunny_outlined,
                                        color: Colors.green, size: 16),
                                    SizedBox(width: 8),
                                    Text('Lunch'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'dinner',
                                child: Row(
                                  children: [
                                    Icon(Icons.nightlight_round,
                                        color: Colors.blue, size: 16),
                                    SizedBox(width: 8),
                                    Text('Dinner'),
                                  ],
                                ),
                              ),
                              DropdownMenuItem(
                                value: 'snack',
                                child: Row(
                                  children: [
                                    Icon(Icons.cookie,
                                        color: Colors.purple, size: 16),
                                    SizedBox(width: 8),
                                    Text('Snacks'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 食物分类快捷选择
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children:
                      FoodDatabaseService.getAllCategories().map((category) {
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(category),
                        onSelected: (selected) {
                          if (selected) {
                            _searchController.text = category;
                            _filterFoods();
                          } else {
                            _searchController.clear();
                            _filterFoods();
                          }
                        },
                        backgroundColor:
                            _getCategoryColor(category).withOpacity(0.1),
                        selectedColor:
                            _getCategoryColor(category).withOpacity(0.3),
                        labelStyle: TextStyle(
                          color: _getCategoryColor(category),
                          fontWeight: FontWeight.w500,
                          fontSize: 12,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),

            // 食物列表
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 8,
                  bottom: _selectedFood != null ? 120 : 16,
                ),
                itemCount: _filteredFoods.length,
                itemBuilder: (context, index) {
                  final food = _filteredFoods[index];
                  final isSelected = _selectedFood == food;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected ? Colors.green.shade50 : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      elevation: isSelected ? 3 : 1,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _selectFood(food),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.green.shade300
                                  : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              // 食物图标
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(food.category)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  _getCategoryIcon(food.category),
                                  color: _getCategoryColor(food.category),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),

                              // 食物信息
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isSelected
                                            ? Colors.green.shade700
                                            : Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${food.caloriesPerUnit.toStringAsFixed(1)} 卡路里/每${food.unit}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // 分类标签
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getCategoryColor(food.category),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  food.category,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),

                              // 选中指示器
                              if (isSelected) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green.shade600,
                                  size: 20,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),

        // 底部固定的操作区域
        if (_selectedFood != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 选中食物信息条
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getCategoryIcon(_selectedFood!.category),
                            color: _getCategoryColor(_selectedFood!.category),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedFood!.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${(_selectedFood!.caloriesPerUnit * _quantity).round()} 卡路里 (${_quantity}${_selectedFood!.unit})',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: _showQuantityDialog,
                            child: Text(
                              '调整数量',
                              style: TextStyle(color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Add按钮
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _addFoodRecord,
                        icon: const Icon(Icons.add_circle_outline, size: 20),
                        label: const Text(
                          'Add并继续',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAddedRecordsTab() {
    if (_addedRecords.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              '还没有Add任何食物',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '在"选择食物"标签页中Add Food',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    double totalCalories =
        _addedRecords.fold(0, (sum, record) => sum + record.totalCalories);

    return Column(
      children: [
        // 总计信息
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade50, Colors.green.shade100],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '本次Add',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${_addedRecords.length} 项食物',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '总卡路里',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${totalCalories.round()} kcal',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 已Add Food列表
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _addedRecords.length,
            itemBuilder: (context, index) {
              final record = _addedRecords[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
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
                        size: 20,
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
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
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
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'kcal',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _removeAddedRecord(index),
                      iconSize: 20,
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // 底部完成按钮
        Container(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _finishAdding,
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text(
                '完成Add',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
            ),
          ),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
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
        return 'Breakfast';
      case 'lunch':
        return 'Lunch';
      case 'dinner':
        return 'Dinner';
      case 'snack':
        return 'Snacks';
      default:
        return '未知';
    }
  }
}

