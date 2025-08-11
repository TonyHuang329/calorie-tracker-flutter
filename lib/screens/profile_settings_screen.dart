// lib/screens/profile_settings_screen.dart
import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/calorie_calculator.dart';

class ProfileSettingsScreen extends StatefulWidget {
  final UserProfile currentUser;
  final Function(UserProfile) onProfileUpdated;

  const ProfileSettingsScreen({
    super.key,
    required this.currentUser,
    required this.onProfileUpdated,
  });

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late String _selectedGender;
  late String _selectedActivityLevel;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _nameController = TextEditingController(text: widget.currentUser.name);
    _ageController =
        TextEditingController(text: widget.currentUser.age.toString());
    _heightController =
        TextEditingController(text: widget.currentUser.height.toString());
    _weightController =
        TextEditingController(text: widget.currentUser.weight.toString());
    _selectedGender = widget.currentUser.gender;
    _selectedActivityLevel = widget.currentUser.activityLevel;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (_formKey.currentState!.validate()) {
      final updatedProfile = widget.currentUser.copyWith(
        name: _nameController.text.trim(),
        age: int.parse(_ageController.text),
        height: double.parse(_heightController.text),
        weight: double.parse(_weightController.text),
        gender: _selectedGender,
        activityLevel: _selectedActivityLevel,
      );

      widget.onProfileUpdated(updatedProfile);
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _resetToDefaults() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset Confirmation'),
        content: const Text('Are you sure you want to reset all settings?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _nameController.text = 'John Doe';
                _ageController.text = '25';
                _heightController.text = '175';
                _weightController.text = '70';
                _selectedGender = 'male';
                _selectedActivityLevel = 'moderate';
              });
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Real-time preview calculation
    double? previewBMR;
    double? previewTDEE;

    try {
      final weight = double.tryParse(_weightController.text) ?? 0;
      final height = double.tryParse(_heightController.text) ?? 0;
      final age = int.tryParse(_ageController.text) ?? 0;

      if (weight > 0 && height > 0 && age > 0) {
        previewBMR = CalorieCalculatorService.calculateBMR(
          weight: weight,
          height: height,
          age: age,
          gender: _selectedGender,
        );
        previewTDEE = CalorieCalculatorService.calculateTDEE(
          bmr: previewBMR,
          activityLevel: _selectedActivityLevel,
        );
      }
    } catch (e) {
      // Ignore calculation errors
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Settings'),
        actions: [
          TextButton(
            onPressed: _saveProfile,
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic information card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Age
                      TextFormField(
                        controller: _ageController,
                        decoration: const InputDecoration(
                          labelText: 'Age',
                          prefixIcon: Icon(Icons.cake),
                          border: OutlineInputBorder(),
                          suffixText: 'years',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your age';
                          }
                          final age = int.tryParse(value);
                          if (age == null || age < 10 || age > 120) {
                            return 'Age should be between 10-120 years';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // Gender selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Gender', style: TextStyle(fontSize: 16)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Male'),
                                  value: 'male',
                                  groupValue: _selectedGender,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<String>(
                                  title: const Text('Female'),
                                  value: 'female',
                                  groupValue: _selectedGender,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedGender = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Body measurements card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Body Measurements',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),

                      // Height
                      TextFormField(
                        controller: _heightController,
                        decoration: const InputDecoration(
                          labelText: 'Height',
                          prefixIcon: Icon(Icons.height),
                          border: OutlineInputBorder(),
                          suffixText: 'cm',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your height';
                          }
                          final height = double.tryParse(value);
                          if (height == null || height < 100 || height > 250) {
                            return 'Height should be between 100-250cm';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),

                      const SizedBox(height: 16),

                      // Weight
                      TextFormField(
                        controller: _weightController,
                        decoration: const InputDecoration(
                          labelText: 'Weight',
                          prefixIcon: Icon(Icons.monitor_weight),
                          border: OutlineInputBorder(),
                          suffixText: 'kg',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your weight';
                          }
                          final weight = double.tryParse(value);
                          if (weight == null || weight < 30 || weight > 300) {
                            return 'Weight should be between 30-300kg';
                          }
                          return null;
                        },
                        onChanged: (value) => setState(() {}),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Activity level card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Activity Level',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 16),
                      ...[
                        'sedentary',
                        'light',
                        'moderate',
                        'active',
                        'very_active'
                      ]
                          .map((level) => RadioListTile<String>(
                                title: Text(CalorieCalculatorService
                                    .getActivityLevelDescription(level)),
                                value: level,
                                groupValue: _selectedActivityLevel,
                                onChanged: (value) {
                                  setState(() {
                                    _selectedActivityLevel = value!;
                                  });
                                },
                              ))
                          .toList(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Preview calculation results
              if (previewBMR != null && previewTDEE != null) ...[
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.preview, color: Colors.blue.shade700),
                            const SizedBox(width: 8),
                            Text(
                              'Preview Calculation Results',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _buildPreviewItem(
                                  'Basal Metabolic Rate (BMR)',
                                  '${previewBMR.round()} kcal'),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildPreviewItem(
                                  'Total Daily Energy Expenditure (TDEE)',
                                  '${previewTDEE.round()} kcal'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'This will be your new calorie target',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _resetToDefaults,
                      child: const Text('Reset to Default'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saveProfile,
                      child: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }
}
