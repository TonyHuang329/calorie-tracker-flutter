// lib/screens/create_goal_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/health_goal.dart';
import '../models/user_profile.dart';
import '../services/health_goal_service.dart';

class CreateGoalScreen extends StatefulWidget {
  final UserProfile userProfile;
  final HealthGoalType? suggestedGoalType;

  const CreateGoalScreen({
    Key? key,
    required this.userProfile,
    this.suggestedGoalType,
  }) : super(key: key);

  @override
  State<CreateGoalScreen> createState() => _CreateGoalScreenState();
}

class _CreateGoalScreenState extends State<CreateGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final PageController _pageController = PageController();

  // Form controllers
  final TextEditingController _goalNameController = TextEditingController();
  final TextEditingController _targetWeightController = TextEditingController();
  final TextEditingController _customDurationController =
      TextEditingController();

  // Form state
  HealthGoalType _selectedGoalType = HealthGoalType.weightLoss;
  GoalDifficulty _selectedDifficulty = GoalDifficulty.moderate;
  DateTime _targetDate = DateTime.now().add(const Duration(days: 90));
  bool _useCustomDuration = false;
  int _currentPage = 0;

  // Calculated values
  Map<String, dynamic> _timeline = {};
  double _recommendedTargetWeight = 0;
  bool _isCalculating = false;

  @override
  void initState() {
    super.initState();
    if (widget.suggestedGoalType != null) {
      _selectedGoalType = widget.suggestedGoalType!;
    }
    _initializeDefaults();
  }

  void _initializeDefaults() {
    _goalNameController.text = _getDefaultGoalName(_selectedGoalType);
    _recommendedTargetWeight = _calculateRecommendedTarget();
    _targetWeightController.text = _recommendedTargetWeight.toStringAsFixed(1);
    _calculateTimeline();
  }

  String _getDefaultGoalName(HealthGoalType type) {
    switch (type) {
      case HealthGoalType.weightLoss:
        return 'Lose Weight Healthily';
      case HealthGoalType.weightGain:
        return 'Gain Weight Gradually';
      case HealthGoalType.muscleGain:
        return 'Build Muscle Mass';
      case HealthGoalType.maintenance:
        return 'Maintain Current Weight';
      case HealthGoalType.healthyEating:
        return 'Develop Healthy Habits';
      case HealthGoalType.energyBoost:
        return 'Boost Energy Levels';
    }
  }

  double _calculateRecommendedTarget() {
    final currentWeight = widget.userProfile.weight;
    final height = widget.userProfile.height;
    final bmi = currentWeight / ((height / 100) * (height / 100));

    switch (_selectedGoalType) {
      case HealthGoalType.weightLoss:
        if (bmi > 25) {
          // Target healthy BMI of 22
          return (22 * (height / 100) * (height / 100));
        }
        return currentWeight - 5; // Default 5kg loss

      case HealthGoalType.weightGain:
        if (bmi < 18.5) {
          // Target healthy BMI of 21
          return (21 * (height / 100) * (height / 100));
        }
        return currentWeight + 5; // Default 5kg gain

      case HealthGoalType.muscleGain:
        return currentWeight + 3; // 3kg muscle gain

      default:
        return currentWeight; // Maintenance
    }
  }

  void _calculateTimeline() {
    if (_targetWeightController.text.isNotEmpty) {
      final targetWeight = double.tryParse(_targetWeightController.text) ??
          _recommendedTargetWeight;

      setState(() => _isCalculating = true);

      Future.delayed(const Duration(milliseconds: 500), () {
        final timeline =
            HealthGoalService.instance.calculateRecommendedTimeline(
          _selectedGoalType,
          widget.userProfile.weight,
          targetWeight,
          _selectedDifficulty,
        );

        setState(() {
          _timeline = timeline;
          if (!_useCustomDuration) {
            _targetDate = DateTime.now().add(Duration(days: timeline['days']));
          }
          _isCalculating = false;
        });
      });
    }
  }

  Future<void> _createGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final targetWeight = double.parse(_targetWeightController.text);

    final newGoal = HealthGoal(
      name: _goalNameController.text.trim(),
      type: _selectedGoalType,
      targetValue: targetWeight,
      currentValue: widget.userProfile.weight,
      startDate: DateTime.now(),
      targetDate: _targetDate,
      difficulty: _selectedDifficulty,
      customSettings: {
        'startWeight': widget.userProfile.weight,
        'recommendedCalorieAdjustment': _getCalorieAdjustment(),
      },
    );

    try {
      await HealthGoalService.instance.createHealthGoal(newGoal);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Health goal created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create goal: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  double _getCalorieAdjustment() {
    switch (_selectedGoalType) {
      case HealthGoalType.weightLoss:
        switch (_selectedDifficulty) {
          case GoalDifficulty.easy:
            return -250;
          case GoalDifficulty.moderate:
            return -400;
          case GoalDifficulty.hard:
            return -550;
        }
      case HealthGoalType.weightGain:
      case HealthGoalType.muscleGain:
        switch (_selectedDifficulty) {
          case GoalDifficulty.easy:
            return 250;
          case GoalDifficulty.moderate:
            return 400;
          case GoalDifficulty.hard:
            return 550;
        }
      default:
        return 0;
    }
  }

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _createGoal();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Health Goal'),
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(
                      right: index < 2 ? 8 : 0,
                    ),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentPage
                          ? Colors.green
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // Page content
          Expanded(
            child: Form(
              key: _formKey,
              child: PageView(
                controller: _pageController,
                onPageChanged: (page) {
                  setState(() => _currentPage = page);
                },
                children: [
                  _buildGoalTypeSelectionPage(),
                  _buildGoalDetailsPage(),
                  _buildReviewPage(),
                ],
              ),
            ),
          ),

          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      child: const Text('Back'),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _nextPage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      _currentPage == 2 ? 'Create Goal' : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalTypeSelectionPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'What\'s your health goal?',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the goal that best matches what you want to achieve.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Goal type cards
          ...HealthGoalType.values.map((type) {
            return _buildGoalTypeCard(type);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildGoalTypeCard(HealthGoalType type) {
    final isSelected = _selectedGoalType == type;
    final color = _getGoalTypeColor(type);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedGoalType = type;
          _goalNameController.text = _getDefaultGoalName(type);
          _recommendedTargetWeight = _calculateRecommendedTarget();
          _targetWeightController.text =
              _recommendedTargetWeight.toStringAsFixed(1);
          _calculateTimeline();
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getGoalTypeIcon(type),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getGoalTypeTitle(type),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getGoalTypeDescription(type),
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalDetailsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Goal Details',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Customize your goal with specific targets and timeline.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Goal name
          TextFormField(
            controller: _goalNameController,
            decoration: const InputDecoration(
              labelText: 'Goal Name',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.edit),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a goal name';
              }
              return null;
            },
          ),

          const SizedBox(height: 16),

          // Target weight (for weight-related goals)
          if (_selectedGoalType == HealthGoalType.weightLoss ||
              _selectedGoalType == HealthGoalType.weightGain ||
              _selectedGoalType == HealthGoalType.muscleGain) ...[
            TextFormField(
              controller: _targetWeightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Target Weight',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.monitor_weight),
                suffixText: 'kg',
                helperText:
                    'Current: ${widget.userProfile.weight.toStringAsFixed(1)} kg',
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter target weight';
                }
                final weight = double.tryParse(value);
                if (weight == null || weight < 30 || weight > 300) {
                  return 'Please enter a valid weight (30-300 kg)';
                }
                return null;
              },
              onChanged: (value) => _calculateTimeline(),
            ),
            const SizedBox(height: 16),
          ],

          // Difficulty selection
          const Text(
            'Difficulty Level',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...GoalDifficulty.values.map((difficulty) {
            return RadioListTile<GoalDifficulty>(
              title: Text(_getDifficultyTitle(difficulty)),
              subtitle: Text(_getDifficultyDescription(difficulty)),
              value: difficulty,
              groupValue: _selectedDifficulty,
              onChanged: (value) {
                setState(() {
                  _selectedDifficulty = value!;
                  _calculateTimeline();
                });
              },
            );
          }).toList(),

          const SizedBox(height: 16),

          // Timeline preview
          if (_timeline.isNotEmpty && !_isCalculating)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue.shade600),
                        const SizedBox(width: 8),
                        const Text(
                          'Recommended Timeline',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${_timeline['weeks']} weeks (${_timeline['days']} days)',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeline['difficultyDescription'],
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    if (!_timeline['isRealistic'])
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning,
                                color: Colors.orange, size: 16),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'This timeline might be too aggressive. Consider a more gradual approach.',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

          if (_isCalculating)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            ),

          const SizedBox(height: 16),

          // Custom target date
          SwitchListTile(
            title: const Text('Set custom target date'),
            subtitle: Text(_useCustomDuration
                ? 'Target: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}'
                : 'Use recommended timeline'),
            value: _useCustomDuration,
            onChanged: (value) {
              setState(() => _useCustomDuration = value);
              if (value) {
                _showDatePicker();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReviewPage() {
    final targetWeight = double.tryParse(_targetWeightController.text) ??
        _recommendedTargetWeight;
    final weightChange = (targetWeight - widget.userProfile.weight).abs();
    final calorieAdjustment = _getCalorieAdjustment();
    final baseTDEE = widget.userProfile.calculateTDEE();
    final adjustedTDEE = baseTDEE + calorieAdjustment;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review Your Goal',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please review your goal details before creating.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),

          // Goal summary card
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _getGoalTypeColor(_selectedGoalType)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getGoalTypeIcon(_selectedGoalType),
                          color: _getGoalTypeColor(_selectedGoalType),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _goalNameController.text,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getGoalTypeTitle(_selectedGoalType),
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Details cards
          _buildReviewDetailCard(
            'Target',
            [
              if (_selectedGoalType == HealthGoalType.weightLoss ||
                  _selectedGoalType == HealthGoalType.weightGain ||
                  _selectedGoalType == HealthGoalType.muscleGain)
                'Weight: ${targetWeight.toStringAsFixed(1)} kg',
              'Change: ${weightChange.toStringAsFixed(1)} kg',
              'Timeline: ${_timeline['weeks'] ?? 0} weeks',
            ],
            Icons.flag,
            Colors.blue,
          ),

          _buildReviewDetailCard(
            'Difficulty & Approach',
            [
              _getDifficultyTitle(_selectedDifficulty),
              _getDifficultyDescription(_selectedDifficulty),
              'Target date: ${_targetDate.day}/${_targetDate.month}/${_targetDate.year}',
            ],
            Icons.speed,
            Colors.orange,
          ),

          _buildReviewDetailCard(
            'Daily Calorie Adjustment',
            [
              'Base TDEE: ${baseTDEE.round()} kcal',
              'Adjustment: ${calorieAdjustment >= 0 ? '+' : ''}${calorieAdjustment.round()} kcal',
              'New target: ${adjustedTDEE.round()} kcal/day',
            ],
            Icons.local_fire_department,
            Colors.red,
          ),

          const SizedBox(height: 16),

          // Nutrition recommendations
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.green.shade600),
                      const SizedBox(width: 8),
                      const Text(
                        'Nutrition Tips',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...HealthGoal(
                    name: '',
                    type: _selectedGoalType,
                    targetValue: targetWeight,
                    currentValue: widget.userProfile.weight,
                    startDate: DateTime.now(),
                    targetDate: _targetDate,
                    difficulty: _selectedDifficulty,
                  ).nutritionRecommendations.take(3).map((tip) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: Colors.green.shade600,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              tip,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewDetailCard(
    String title,
    List<String> details,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...details
                .map((detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        detail,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ))
                .toList(),
          ],
        ),
      ),
    );
  }

  void _showDatePicker() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _targetDate,
      firstDate: DateTime.now().add(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _targetDate = date);
    }
  }

  // Helper methods
  Color _getGoalTypeColor(HealthGoalType type) {
    switch (type) {
      case HealthGoalType.weightLoss:
        return Colors.red;
      case HealthGoalType.weightGain:
        return Colors.green;
      case HealthGoalType.muscleGain:
        return Colors.blue;
      case HealthGoalType.maintenance:
        return Colors.orange;
      case HealthGoalType.healthyEating:
        return Colors.purple;
      case HealthGoalType.energyBoost:
        return Colors.amber;
    }
  }

  IconData _getGoalTypeIcon(HealthGoalType type) {
    switch (type) {
      case HealthGoalType.weightLoss:
        return Icons.trending_down;
      case HealthGoalType.weightGain:
        return Icons.trending_up;
      case HealthGoalType.muscleGain:
        return Icons.fitness_center;
      case HealthGoalType.maintenance:
        return Icons.balance;
      case HealthGoalType.healthyEating:
        return Icons.restaurant_menu;
      case HealthGoalType.energyBoost:
        return Icons.bolt;
    }
  }

  String _getGoalTypeTitle(HealthGoalType type) {
    switch (type) {
      case HealthGoalType.weightLoss:
        return 'Weight Loss';
      case HealthGoalType.weightGain:
        return 'Weight Gain';
      case HealthGoalType.muscleGain:
        return 'Muscle Building';
      case HealthGoalType.maintenance:
        return 'Weight Maintenance';
      case HealthGoalType.healthyEating:
        return 'Healthy Eating';
      case HealthGoalType.energyBoost:
        return 'Energy Enhancement';
    }
  }

  String _getGoalTypeDescription(HealthGoalType type) {
    switch (type) {
      case HealthGoalType.weightLoss:
        return 'Lose weight in a healthy, sustainable way';
      case HealthGoalType.weightGain:
        return 'Gain weight through proper nutrition';
      case HealthGoalType.muscleGain:
        return 'Build muscle mass and strength';
      case HealthGoalType.maintenance:
        return 'Maintain current weight and health';
      case HealthGoalType.healthyEating:
        return 'Develop balanced nutrition habits';
      case HealthGoalType.energyBoost:
        return 'Optimize nutrition for better energy';
    }
  }

  String _getDifficultyTitle(GoalDifficulty difficulty) {
    switch (difficulty) {
      case GoalDifficulty.easy:
        return 'Easy - Gentle Pace';
      case GoalDifficulty.moderate:
        return 'Moderate - Balanced';
      case GoalDifficulty.hard:
        return 'Intensive - Fast Track';
    }
  }

  String _getDifficultyDescription(GoalDifficulty difficulty) {
    switch (difficulty) {
      case GoalDifficulty.easy:
        return 'Comfortable and sustainable approach';
      case GoalDifficulty.moderate:
        return 'Steady progress with manageable changes';
      case GoalDifficulty.hard:
        return 'Requires strong commitment and discipline';
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _goalNameController.dispose();
    _targetWeightController.dispose();
    _customDurationController.dispose();
    super.dispose();
  }
}
