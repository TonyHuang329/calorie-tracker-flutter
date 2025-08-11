// lib/screens/health_goals_screen.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/health_goal.dart';
import '../models/user_profile.dart';
import '../services/health_goal_service.dart';
import 'create_goal_screen.dart';

class HealthGoalsScreen extends StatefulWidget {
  final UserProfile userProfile;

  const HealthGoalsScreen({
    Key? key,
    required this.userProfile,
  }) : super(key: key);

  @override
  State<HealthGoalsScreen> createState() => _HealthGoalsScreenState();
}

class _HealthGoalsScreenState extends State<HealthGoalsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  List<HealthGoal> _activeGoals = [];
  List<HealthGoal> _completedGoals = [];
  List<Map<String, dynamic>> _recommendations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final allGoals = await HealthGoalService.instance.getAllHealthGoals();
      final recommendations =
          HealthGoalService.instance.getGoalRecommendations(widget.userProfile);

      setState(() {
        _activeGoals = allGoals.where((goal) => goal.isActive).toList();
        _completedGoals = allGoals.where((goal) => !goal.isActive).toList();
        _recommendations = recommendations;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading goals: $e');
      setState(() => _isLoading = false);
    }
  }

  void _navigateToCreateGoal({HealthGoalType? suggestedType}) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => CreateGoalScreen(
          userProfile: widget.userProfile,
          suggestedGoalType: suggestedType,
        ),
      ),
    );

    if (result == true) {
      _loadData(); // Refresh data
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Goals'),
        backgroundColor: Colors.green.shade50,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.track_changes),
              text: 'Active Goals (${_activeGoals.length})',
            ),
            Tab(
              icon: const Icon(Icons.lightbulb_outline),
              text: 'Recommendations',
            ),
            Tab(
              icon: const Icon(Icons.history),
              text: 'Completed',
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildActiveGoalsTab(),
                _buildRecommendationsTab(),
                _buildCompletedGoalsTab(),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToCreateGoal(),
        icon: const Icon(Icons.add),
        label: const Text('New Goal'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Widget _buildActiveGoalsTab() {
    if (_activeGoals.isEmpty) {
      return _buildEmptyActiveGoals();
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Overall progress summary
          _buildProgressSummaryCard(),
          const SizedBox(height: 16),

          // Active goals list
          ..._activeGoals.map((goal) => _buildGoalCard(goal)).toList(),
        ],
      ),
    );
  }

  Widget _buildRecommendationsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.psychology,
                        color: Colors.blue.shade600, size: 24),
                    const SizedBox(width: 8),
                    const Text(
                      'Personalized Recommendations',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Based on your profile, here are some goals that might help you achieve better health.',
                  style: TextStyle(color: Colors.blue.shade700),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Recommendations list
        ..._recommendations
            .map((rec) => _buildRecommendationCard(rec))
            .toList(),
      ],
    );
  }

  Widget _buildCompletedGoalsTab() {
    if (_completedGoals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_events,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'No completed goals yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete your first goal to see it here!',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _completedGoals.length,
      itemBuilder: (context, index) {
        return _buildCompletedGoalCard(_completedGoals[index]);
      },
    );
  }

  Widget _buildEmptyActiveGoals() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.flag_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            Text(
              'No Active Goals',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Set your first health goal to start your journey towards better nutrition and wellness.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreateGoal(),
              icon: const Icon(Icons.add),
              label: const Text('Create Your First Goal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                textStyle: const TextStyle(fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSummaryCard() {
    if (_activeGoals.isEmpty) return const SizedBox.shrink();

    final totalProgress =
        _activeGoals.fold(0.0, (sum, goal) => sum + goal.progressPercentage) /
            _activeGoals.length;
    final onTrackGoals =
        _activeGoals.where((goal) => goal.progressPercentage >= 20).length;

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Overall Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                // Progress circle
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 120,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: [
                          PieChartSectionData(
                            value: totalProgress,
                            title: '${totalProgress.round()}%',
                            color: Colors.green,
                            radius: 25,
                            titleStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            value: 100 - totalProgress,
                            title: '',
                            color: Colors.grey.shade200,
                            radius: 25,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Stats
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStatItem(
                        'Active Goals',
                        '${_activeGoals.length}',
                        Icons.flag,
                        Colors.blue,
                      ),
                      const SizedBox(height: 8),
                      _buildStatItem(
                        'On Track',
                        '$onTrackGoals',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      const SizedBox(height: 8),
                      _buildStatItem(
                        'Average Progress',
                        '${totalProgress.round()}%',
                        Icons.percent,
                        Colors.orange,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildGoalCard(HealthGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: goal.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(goal.icon, color: goal.color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        goal.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Goal'),
                    ),
                    const PopupMenuItem(
                      value: 'pause',
                      child: Text('Pause Goal'),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete Goal'),
                    ),
                  ],
                  onSelected: (value) =>
                      _handleGoalAction(goal, value.toString()),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress: ${goal.progressPercentage.round()}%',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '${goal.remainingDays} days left',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: goal.progressPercentage / 100,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(goal.color),
                  minHeight: 8,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _updateProgress(goal),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Update Progress'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _viewGoalDetails(goal),
                    icon: const Icon(Icons.analytics, size: 16),
                    label: const Text('View Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: goal.color,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    final type = recommendation['type'] as HealthGoalType;
    final priority = recommendation['priority'] as String;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: _getTypeColor(type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _getTypeIcon(type),
                    color: _getTypeColor(type),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            recommendation['title'],
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(priority),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority.toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recommendation['description'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _navigateToCreateGoal(suggestedType: type),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Goal'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getTypeColor(type),
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedGoalCard(HealthGoal goal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 32,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    goal.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Completed on ${goal.updatedAt.day}/${goal.updatedAt.month}/${goal.updatedAt.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              goal.icon,
              color: goal.color,
            ),
          ],
        ),
      ),
    );
  }

  // Helper methods
  Color _getTypeColor(HealthGoalType type) {
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

  IconData _getTypeIcon(HealthGoalType type) {
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  // Action handlers
  void _handleGoalAction(HealthGoal goal, String action) {
    switch (action) {
      case 'edit':
        // Navigate to edit goal screen
        break;
      case 'pause':
        // Pause goal
        break;
      case 'delete':
        _showDeleteConfirmation(goal);
        break;
    }
  }

  void _showDeleteConfirmation(HealthGoal goal) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Goal'),
        content: Text(
            'Are you sure you want to delete "${goal.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await HealthGoalService.instance.deleteHealthGoal(goal.id!);
              _loadData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Goal deleted successfully')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _updateProgress(HealthGoal goal) {
    // Navigate to progress update screen
    print('Update progress for: ${goal.name}');
  }

  void _viewGoalDetails(HealthGoal goal) {
    // Navigate to goal details screen
    print('View details for: ${goal.name}');
  }
}
