// lib/screens/ai_camera_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ai_food_recognition_service.dart';
import '../models/food_recognition_result.dart'; // 使用独立的模型文件
import '../models/food_item.dart';
import '../services/database_service.dart';

/// AI 相机屏幕
class AICameraScreen extends StatefulWidget {
  const AICameraScreen({Key? key}) : super(key: key);

  @override
  State<AICameraScreen> createState() => _AICameraScreenState();
}

class _AICameraScreenState extends State<AICameraScreen> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isProcessing = false;
  FoodRecognitionResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Food Recognition'),
        backgroundColor: Colors.orange[600],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 状态卡片
            _buildStatusCard(),

            const SizedBox(height: 20),

            // 图片选择区域
            _buildImageSection(),

            const SizedBox(height: 20),

            // 操作按钮
            _buildActionButtons(),

            const SizedBox(height: 20),

            // 识别结果
            if (_lastResult != null) _buildResultSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard() {
    final isInitialized = AIFoodRecognitionService.isInitialized;
    final status = AIFoodRecognitionService.getStatus();

    return Card(
      color: isInitialized ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isInitialized ? Icons.check_circle : Icons.warning,
                  color: isInitialized ? Colors.green[600] : Colors.orange[600],
                ),
                const SizedBox(width: 8),
                Text(
                  isInitialized ? 'AI Service Ready' : 'AI Service Unavailable',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color:
                        isInitialized ? Colors.green[800] : Colors.orange[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (isInitialized) ...[
              Text(
                'Model Type: ${status['has_real_model'] ? 'Real AI Model' : 'Simulation Mode'}',
                style: TextStyle(color: Colors.green[700]),
              ),
              Text(
                'Supported Foods: ${status['supported_foods']}',
                style: TextStyle(color: Colors.green[700]),
              ),
            ] else ...[
              Text(
                'AI food recognition is currently unavailable.',
                style: TextStyle(color: Colors.orange[700]),
              ),
              if (status['last_error'] != null)
                Text(
                  'Error: ${status['last_error']}',
                  style: TextStyle(
                    color: Colors.orange[600],
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.file(
                _selectedImage!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: 300,
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.camera_alt,
                  size: 64,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'No image selected',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Take a photo or select from gallery',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // 图片选择按钮
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('Gallery'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // 识别按钮
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _selectedImage != null &&
                    AIFoodRecognitionService.isInitialized &&
                    !_isProcessing
                ? _recognizeFood
                : null,
            icon: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.smart_toy),
            label: Text(_isProcessing ? 'Processing...' : 'Recognize Food'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultSection() {
    if (_lastResult == null) return const SizedBox.shrink();

    return Card(
      color: _lastResult!.success ? Colors.green[50] : Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _lastResult!.success ? Icons.check_circle : Icons.error,
                  color: _lastResult!.success
                      ? Colors.green[600]
                      : Colors.red[600],
                ),
                const SizedBox(width: 8),
                Text(
                  _lastResult!.success
                      ? 'Recognition Successful'
                      : 'Recognition Failed',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _lastResult!.success
                        ? Colors.green[800]
                        : Colors.red[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_lastResult!.success && _lastResult!.detectedFood != null) ...[
              _buildFoodInfoRow('Food:', _lastResult!.detectedFood!.name),
              _buildFoodInfoRow(
                  'Category:', _lastResult!.detectedFood!.category),
              _buildFoodInfoRow('Calories:',
                  '${_lastResult!.detectedFood!.caloriesPerUnit} kcal/g'),
              _buildFoodInfoRow(
                  'Confidence:', _lastResult!.confidencePercentage),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _addFoodToLog(_lastResult!.detectedFood!),
                  icon: const Icon(Icons.add),
                  label: const Text('Add to Food Log'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ] else ...[
              Text(
                _lastResult!.message,
                style: TextStyle(color: Colors.red[700]),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFoodInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
          _lastResult = null; // 清除之前的结果
        });
      }
    } catch (e) {
      _showErrorDialog('Failed to pick image: $e');
    }
  }

  Future<void> _recognizeFood() async {
    if (_selectedImage == null) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final result =
          await AIFoodRecognitionService.recognizeFood(_selectedImage!);
      setState(() {
        _lastResult = result;
      });

      if (result.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recognized: ${result.detectedFood?.name}'),
            backgroundColor: Colors.green[600],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: Colors.red[600],
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Recognition failed: $e');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  void _addFoodToLog(FoodItem food) async {
    try {
      // 创建食物记录，默认使用100g
      final record = FoodRecord(
        foodItemId: food.id ?? 0,
        foodItem: food,
        quantity: 100.0,
        totalCalories: food.caloriesPerUnit * 100,
        mealType: _getCurrentMealType(),
      );

      // 保存到数据库
      await DatabaseService.saveFoodRecord(record);

      // 显示成功消息
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${food.name} added to your food log!'),
            backgroundColor: Colors.green[600],
            action: SnackBarAction(
              label: 'View',
              textColor: Colors.white,
              onPressed: () {
                Navigator.of(context).pop(); // 返回主屏幕
              },
            ),
          ),
        );
      }
    } catch (e) {
      _showErrorDialog('Failed to add food to log: $e');
    }
  }

  String _getCurrentMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      return 'breakfast';
    } else if (hour < 16) {
      return 'lunch';
    } else if (hour < 21) {
      return 'dinner';
    } else {
      return 'snack';
    }
  }

  void _showErrorDialog(String message) {
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}
