// lib/screens/smart_analysis_test_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/smart_image_analysis_service.dart';

class SmartAnalysisTestScreen extends StatefulWidget {
  const SmartAnalysisTestScreen({Key? key}) : super(key: key);

  @override
  State<SmartAnalysisTestScreen> createState() =>
      _SmartAnalysisTestScreenState();
}

class _SmartAnalysisTestScreenState extends State<SmartAnalysisTestScreen> {
  final ImagePicker _picker = ImagePicker();
  final SmartImageAnalysisService _analysisService =
      SmartImageAnalysisService.instance;

  File? _selectedImage;
  FoodClassificationResult? _result;
  bool _isAnalyzing = false;

  Future<void> _pickAndAnalyzeImage(ImageSource source) async {
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
          _result = null;
          _isAnalyzing = true;
        });

        // 分析图像
        final result = await _analysisService.analyzeImage(_selectedImage!);

        setState(() {
          _result = result;
          _isAnalyzing = false;
        });
      }
    } catch (e) {
      setState(() => _isAnalyzing = false);
      _showError('分析失败: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('智能分析测试'),
        backgroundColor: Colors.purple.shade50,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 选择图片按钮
            if (_selectedImage == null) _buildImagePicker(),

            // 显示选中的图片
            if (_selectedImage != null) _buildImageDisplay(),

            const SizedBox(height: 20),

            // 分析状态
            if (_isAnalyzing) _buildAnalyzingIndicator(),

            // 分析结果
            if (_result != null) _buildAnalysisResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.image, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text('选择要测试的食物图片', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndAnalyzeImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('拍照'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pickAndAnalyzeImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('相册'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageDisplay() {
    return Column(
      children: [
        Card(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              _selectedImage!,
              height: 250,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() {
                  _selectedImage = null;
                  _result = null;
                }),
                child: const Text('重新选择'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: _isAnalyzing
                    ? null
                    : () => _pickAndAnalyzeImage(ImageSource.gallery),
                child: const Text('重新分析'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnalyzingIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('智能分析中...', style: TextStyle(fontSize: 16)),
            SizedBox(height: 8),
            Text('正在分析颜色、形状、纹理特征',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisResult() {
    if (!_result!.isSuccess) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.error, size: 48, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(_result!.errorMessage ?? '分析失败'),
              if (_result!.quality != null)
                _buildQualityInfo(_result!.quality!),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // 图像质量评估
        if (_result!.quality != null) _buildQualityCard(_result!.quality!),

        const SizedBox(height: 16),

        // 图像特征详情
        if (_result!.features != null) _buildFeaturesCard(_result!.features!),

        const SizedBox(height: 16),

        // 分类建议
        _buildSuggestionsCard(_result!.suggestions),
      ],
    );
  }

  Widget _buildQualityCard(ImageQuality quality) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  quality.isGoodEnough ? Icons.check_circle : Icons.warning,
                  color: quality.isGoodEnough ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  '图像质量: ${quality.level}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getScoreColor(quality.score),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(quality.score * 100).round()}分',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildQualityMetric('亮度', quality.brightness)),
                Expanded(child: _buildQualityMetric('清晰度', quality.sharpness)),
              ],
            ),
            if (quality.issues.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('问题:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...quality.issues.map((issue) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child:
                        Text('• $issue', style: const TextStyle(fontSize: 12)),
                  )),
            ],
            if (quality.suggestions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('建议:', style: TextStyle(fontWeight: FontWeight.w500)),
              ...quality.suggestions.map((suggestion) => Padding(
                    padding: const EdgeInsets.only(left: 16, top: 4),
                    child: Text('• $suggestion',
                        style:
                            const TextStyle(fontSize: 12, color: Colors.blue)),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesCard(ImageFeatures features) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '特征分析',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // 颜色特征
            _buildFeatureSection(
              '颜色特征',
              Icons.palette,
              Colors.red,
              [
                '主色调: ${_getColorName(features.colors.dominantColor)}',
                '颜色多样性: ${(features.colors.diversity * 100).round()}%',
                '颜色分布: ${features.colors.colorDistribution.entries.take(3).map((e) => '${_getColorName(e.key)} ${(e.value * 100).round()}%').join(', ')}',
              ],
            ),

            const SizedBox(height: 12),

            // 形状特征
            _buildFeatureSection(
              '形状特征',
              Icons.crop_free,
              Colors.blue,
              [
                '形状类型: ${_getShapeName(features.shapes.category)}',
                '圆度: ${(features.shapes.roundness * 100).round()}%',
                '长宽比: ${features.shapes.aspectRatio.toStringAsFixed(2)}',
              ],
            ),

            const SizedBox(height: 12),

            // 纹理特征
            _buildFeatureSection(
              '纹理特征',
              Icons.texture,
              Colors.green,
              [
                '纹理类型: ${_getTextureName(features.textures.category)}',
                '对比度: ${(features.textures.contrast * 100).round()}%',
                '粗糙度: ${(features.textures.roughness * 100).round()}%',
                '均匀性: ${(features.textures.uniformity * 100).round()}%',
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsCard(List<CategorySuggestion> suggestions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '分类建议',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...suggestions
                .map((suggestion) => _buildSuggestionTile(suggestion)),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionTile(CategorySuggestion suggestion) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getCategoryColor(suggestion.category),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  suggestion.category,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const Spacer(),
              Text(
                '${suggestion.confidencePercentage.round()}%',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: _getConfidenceColor(suggestion.confidence),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '原因: ${suggestion.reasons.join(', ')}',
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(
            '建议食物: ${suggestion.foodSuggestions.take(3).join(', ')}',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureSection(
      String title, IconData icon, Color color, List<String> details) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(fontWeight: FontWeight.w500, color: color)),
            ],
          ),
          const SizedBox(height: 8),
          ...details.map((detail) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(detail, style: const TextStyle(fontSize: 12)),
              )),
        ],
      ),
    );
  }

  Widget _buildQualityMetric(String label, double value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: value,
          backgroundColor: Colors.grey.shade200,
          valueColor: AlwaysStoppedAnimation(_getScoreColor(value)),
        ),
        const SizedBox(height: 4),
        Text('${(value * 100).round()}%', style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildQualityInfo(ImageQuality quality) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Text('质量评分: ${(quality.score * 100).round()}分'),
        if (quality.issues.isNotEmpty)
          ...quality.issues.map((issue) => Text('问题: $issue',
              style: const TextStyle(color: Colors.red, fontSize: 12))),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.7) return Colors.green;
    if (confidence >= 0.5) return Colors.orange;
    return Colors.red;
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case '水果':
        return Colors.red;
      case '蔬菜':
        return Colors.green;
      case '主食':
        return Colors.orange;
      case '蛋白质':
        return Colors.purple;
      case '零食':
        return Colors.brown;
      case '饮品':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getColorName(String color) {
    const names = {
      'red': '红色',
      'green': '绿色',
      'blue': '蓝色',
      'yellow': '黄色',
      'orange': '橙色',
      'purple': '紫色',
      'brown': '棕色',
      'white': '白色',
      'black': '黑色',
      'gray': '灰色',
      'pink': '粉色'
    };
    return names[color] ?? color;
  }

  String _getShapeName(String shape) {
    const names = {
      'round': '圆形',
      'long': '长条形',
      'tall': '高形',
      'irregular': '不规则'
    };
    return names[shape] ?? shape;
  }

  String _getTextureName(String texture) {
    const names = {'smooth': '光滑', 'rough': '粗糙', 'granular': '颗粒状'};
    return names[texture] ?? texture;
  }
}
