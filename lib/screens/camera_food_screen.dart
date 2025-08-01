// // lib/screens/camera_food_screen.dart
// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import '../models/food_item.dart';
// import '../services/ai_food_recognition_service.dart';
// import '../services/food_database.dart';

// class CameraFoodScreen extends StatefulWidget {
//   final Function(FoodRecord) onFoodAdded;
//   final String mealType;

//   const CameraFoodScreen({
//     Key? key,
//     required this.onFoodAdded,
//     this.mealType = 'breakfast',
//   }) : super(key: key);

//   @override
//   State<CameraFoodScreen> createState() => _CameraFoodScreenState();
// }

// class _CameraFoodScreenState extends State<CameraFoodScreen> {
//   final ImagePicker _picker = ImagePicker();
//   final AIFoodRecognitionService _aiService = AIFoodRecognitionService.instance;

//   File? _selectedImage;
//   FoodRecognitionResult? _recognitionResult;
//   AIRecognitionStatus _status = AIRecognitionStatus.idle;
//   FoodItem? _selectedFood;
//   double _quantity = 100.0;
//   final TextEditingController _quantityController =
//       TextEditingController(text: '100');

//   @override
//   void initState() {
//     super.initState();
//     _initializeAI();
//     _quantityController.addListener(() {
//       final newQuantity = double.tryParse(_quantityController.text) ?? 100.0;
//       if (newQuantity != _quantity) {
//         setState(() {
//           _quantity = newQuantity;
//         });
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _quantityController.dispose();
//     super.dispose();
//   }

//   Future<void> _initializeAI() async {
//     setState(() => _status = AIRecognitionStatus.initializing);

//     final success = await _aiService.initialize();

//     if (mounted) {
//       setState(() {
//         _status =
//             success ? AIRecognitionStatus.idle : AIRecognitionStatus.error;
//       });

//       if (!success) {
//         _showErrorMessage('AI模型初始化失败，请重试');
//       }
//     }
//   }

//   Future<void> _pickImageFromCamera() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.camera,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//           _recognitionResult = null;
//           _selectedFood = null;
//         });

//         await _recognizeFood();
//       }
//     } catch (e) {
//       _showErrorMessage('拍照失败: ${e.toString()}');
//     }
//   }

//   Future<void> _pickImageFromGallery() async {
//     try {
//       final XFile? image = await _picker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1024,
//         maxHeight: 1024,
//         imageQuality: 85,
//       );

//       if (image != null) {
//         setState(() {
//           _selectedImage = File(image.path);
//           _recognitionResult = null;
//           _selectedFood = null;
//         });

//         await _recognizeFood();
//       }
//     } catch (e) {
//       _showErrorMessage('选择图片失败: ${e.toString()}');
//     }
//   }

//   Future<void> _recognizeFood() async {
//     if (_selectedImage == null) return;

//     setState(() => _status = AIRecognitionStatus.processing);

//     try {
//       final result = await _aiService.recognizeFood(_selectedImage!);

//       if (mounted) {
//         setState(() {
//           _recognitionResult = result;
//           _status = AIRecognitionStatus.completed;
//         });

//         if (result.isSuccess && result.predictions.isNotEmpty) {
//           _showSuccessMessage('识别完成！找到 ${result.predictions.length} 个可能的食物');
//         } else {
//           _showErrorMessage(result.errorMessage ?? '未能识别出食物');
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _status = AIRecognitionStatus.error);
//         _showErrorMessage('识别失败: ${e.toString()}');
//       }
//     }
//   }

//   void _selectPrediction(FoodPrediction prediction) {
//     // 尝试从数据库中找到对应的食物
//     final foods = FoodDatabaseService.searchFoods(prediction.displayName);

//     if (foods.isNotEmpty) {
//       setState(() {
//         _selectedFood = foods.first;
//         _quantity = FoodDatabaseService.getRecommendedServing(foods.first);
//         _quantityController.text = _quantity.toString();
//       });
//     } else {
//       // 如果数据库中没有，创建一个默认的食物项
//       final nutritionInfo = _aiService.getFoodNutritionInfo(prediction.label);

//       setState(() {
//         _selectedFood = FoodItem(
//           name: prediction.displayName,
//           caloriesPerUnit: nutritionInfo?['calories'] ?? 1.0,
//           unit: nutritionInfo?['unit'] ?? 'g',
//           category: nutritionInfo?['category'] ?? '其他',
//         );
//         _quantity = 100.0;
//         _quantityController.text = '100';
//       });
//     }
//   }

//   void _addFoodRecord() {
//     if (_selectedFood == null) {
//       _showErrorMessage('请选择一个食物');
//       return;
//     }

//     if (_quantity <= 0) {
//       _showErrorMessage('请输入有效的数量');
//       return;
//     }

//     final totalCalories =
//         FoodDatabaseService.calculateCalories(_selectedFood!, _quantity);

//     final foodRecord = FoodRecord(
//       foodItemId: _selectedFood!.id ?? 0,
//       foodItem: _selectedFood,
//       quantity: _quantity,
//       totalCalories: totalCalories,
//       mealType: widget.mealType,
//       recordedAt: DateTime.now(),
//     );

//     widget.onFoodAdded(foodRecord);
//     Navigator.of(context).pop();
//   }

//   void _showSuccessMessage(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.check_circle, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.green,
//         duration: const Duration(seconds: 2),
//       ),
//     );
//   }

//   void _showErrorMessage(String message) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: [
//             const Icon(Icons.error, color: Colors.white),
//             const SizedBox(width: 8),
//             Expanded(child: Text(message)),
//           ],
//         ),
//         backgroundColor: Colors.red,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('AI食物识别'),
//         backgroundColor: Colors.purple.shade50,
//         elevation: 0,
//         actions: [
//           if (_selectedFood != null)
//             Padding(
//               padding: const EdgeInsets.only(right: 8.0),
//               child: TextButton.icon(
//                 onPressed: _addFoodRecord,
//                 icon: const Icon(Icons.add, color: Colors.white),
//                 label: const Text('添加', style: TextStyle(color: Colors.white)),
//                 style: TextButton.styleFrom(
//                   backgroundColor: Colors.green,
//                   padding: const EdgeInsets.symmetric(horizontal: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(8),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // AI状态指示器
//             _buildStatusIndicator(),
//             const SizedBox(height: 20),

//             // 拍照/选择图片按钮
//             if (_selectedImage == null) _buildImagePickerButtons(),

//             // 显示选中的图片
//             if (_selectedImage != null) _buildSelectedImage(),

//             const SizedBox(height: 20),

//             // 识别结果
//             if (_recognitionResult != null) _buildRecognitionResults(),

//             // 选中的食物详情
//             if (_selectedFood != null) _buildSelectedFoodDetails(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildStatusIndicator() {
//     Color statusColor;
//     String statusText;
//     IconData statusIcon;

//     switch (_status) {
//       case AIRecognitionStatus.idle:
//         statusColor = Colors.blue;
//         statusText = 'AI已就绪，可以开始识别';
//         statusIcon = Icons.camera_alt;
//         break;
//       case AIRecognitionStatus.initializing:
//         statusColor = Colors.orange;
//         statusText = 'AI模型初始化中...';
//         statusIcon = Icons.hourglass_top;
//         break;
//       case AIRecognitionStatus.processing:
//         statusColor = Colors.purple;
//         statusText = 'AI正在识别食物...';
//         statusIcon = Icons.psychology;
//         break;
//       case AIRecognitionStatus.completed:
//         statusColor = Colors.green;
//         statusText = '识别完成！';
//         statusIcon = Icons.check_circle;
//         break;
//       case AIRecognitionStatus.error:
//         statusColor = Colors.red;
//         statusText = 'AI模型出现错误';
//         statusIcon = Icons.error;
//         break;
//     }

//     return Container(
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: statusColor.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: statusColor.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           Icon(statusIcon, color: statusColor, size: 24),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Text(
//               statusText,
//               style: TextStyle(
//                 color: statusColor,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//           if (_status == AIRecognitionStatus.processing ||
//               _status == AIRecognitionStatus.initializing)
//             SizedBox(
//               width: 20,
//               height: 20,
//               child: CircularProgressIndicator(
//                 strokeWidth: 2,
//                 valueColor: AlwaysStoppedAnimation<Color>(statusColor),
//               ),
//             ),
//         ],
//       ),
//     );
//   }

//   Widget _buildImagePickerButtons() {
//     return Column(
//       children: [
//         Container(
//           height: 200,
//           decoration: BoxDecoration(
//             color: Colors.grey.shade100,
//             borderRadius: BorderRadius.circular(12),
//             border: Border.all(
//               color: Colors.grey.shade300,
//               width: 2,
//               style: BorderStyle.solid,
//             ),
//           ),
//           child: Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.camera_alt, size: 48, color: Colors.grey.shade400),
//                 const SizedBox(height: 16),
//                 Text(
//                   '选择或拍摄食物照片',
//                   style: TextStyle(
//                     fontSize: 16,
//                     color: Colors.grey.shade600,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 const SizedBox(height: 8),
//                 Text(
//                   'AI将自动识别食物类型',
//                   style: TextStyle(
//                     fontSize: 14,
//                     color: Colors.grey.shade500,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//         const SizedBox(height: 20),
//         Row(
//           children: [
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _status == AIRecognitionStatus.idle
//                     ? _pickImageFromCamera
//                     : null,
//                 icon: const Icon(Icons.camera_alt),
//                 label: const Text('拍照'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.purple,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _status == AIRecognitionStatus.idle
//                     ? _pickImageFromGallery
//                     : null,
//                 icon: const Icon(Icons.photo_library),
//                 label: const Text('相册'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.blue,
//                   foregroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 16),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildSelectedImage() {
//     return Column(
//       children: [
//         Container(
//           height: 250,
//           width: double.infinity,
//           decoration: BoxDecoration(
//             borderRadius: BorderRadius.circular(12),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.1),
//                 blurRadius: 10,
//                 offset: const Offset(0, 4),
//               ),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(12),
//             child: Image.file(
//               _selectedImage!,
//               fit: BoxFit.cover,
//             ),
//           ),
//         ),
//         const SizedBox(height: 16),
//         Row(
//           children: [
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _pickImageFromCamera,
//                 icon: const Icon(Icons.camera_alt),
//                 label: const Text('重新拍照'),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: OutlinedButton.icon(
//                 onPressed: _pickImageFromGallery,
//                 icon: const Icon(Icons.photo_library),
//                 label: const Text('重新选择'),
//               ),
//             ),
//             const SizedBox(width: 12),
//             Expanded(
//               child: ElevatedButton.icon(
//                 onPressed: _recognizeFood,
//                 icon: const Icon(Icons.psychology),
//                 label: const Text('重新识别'),
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.purple,
//                   foregroundColor: Colors.white,
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildRecognitionResults() {
//     if (!_recognitionResult!.isSuccess) {
//       return Card(
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             children: [
//               Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
//               const SizedBox(height: 16),
//               Text(
//                 '识别失败',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                   color: Colors.red.shade700,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Text(
//                 _recognitionResult!.errorMessage ?? '未知错误',
//                 style: TextStyle(color: Colors.grey.shade600),
//                 textAlign: TextAlign.center,
//               ),
//             ],
//           ),
//         ),
//       );
//     }

//     final predictions = _recognitionResult!.predictions;

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.psychology, color: Colors.purple.shade600, size: 24),
//                 const SizedBox(width: 8),
//                 Text(
//                   'AI识别结果',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.purple.shade700,
//                       ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),
//             Text(
//               '点击选择识别的食物：',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade600,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//             const SizedBox(height: 12),
//             ...predictions
//                 .map((prediction) => _buildPredictionTile(prediction))
//                 .toList(),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildPredictionTile(FoodPrediction prediction) {
//     return Container(
//       margin: const EdgeInsets.only(bottom: 8),
//       child: Material(
//         color: Colors.transparent,
//         child: InkWell(
//           borderRadius: BorderRadius.circular(8),
//           onTap: () => _selectPrediction(prediction),
//           child: Container(
//             padding: const EdgeInsets.all(12),
//             decoration: BoxDecoration(
//               border: Border.all(color: Colors.grey.shade200),
//               borderRadius: BorderRadius.circular(8),
//             ),
//             child: Row(
//               children: [
//                 // 置信度条
//                 Container(
//                   width: 60,
//                   height: 8,
//                   decoration: BoxDecoration(
//                     color: Colors.grey.shade200,
//                     borderRadius: BorderRadius.circular(4),
//                   ),
//                   child: FractionallySizedBox(
//                     alignment: Alignment.centerLeft,
//                     widthFactor: prediction.confidence,
//                     child: Container(
//                       decoration: BoxDecoration(
//                         color: _getConfidenceColor(prediction.confidence),
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),

//                 // 食物信息
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         prediction.displayName,
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         '置信度: ${prediction.confidencePercentage.toStringAsFixed(1)}%',
//                         style: TextStyle(
//                           fontSize: 12,
//                           color: Colors.grey.shade600,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // 选择按钮
//                 Icon(
//                   Icons.arrow_forward_ios,
//                   size: 16,
//                   color: Colors.grey.shade400,
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Color _getConfidenceColor(double confidence) {
//     if (confidence >= 0.7) return Colors.green;
//     if (confidence >= 0.5) return Colors.orange;
//     return Colors.red;
//   }

//   Widget _buildSelectedFoodDetails() {
//     final totalCalories =
//         FoodDatabaseService.calculateCalories(_selectedFood!, _quantity);

//     return Card(
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               children: [
//                 Icon(Icons.restaurant, color: Colors.green.shade600, size: 24),
//                 const SizedBox(width: 8),
//                 Text(
//                   '已选择的食物',
//                   style: Theme.of(context).textTheme.titleLarge?.copyWith(
//                         fontWeight: FontWeight.bold,
//                         color: Colors.green.shade700,
//                       ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // 食物名称
//             Text(
//               _selectedFood!.name,
//               style: const TextStyle(
//                 fontSize: 20,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 8),

//             // 食物分类
//             Container(
//               padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//               decoration: BoxDecoration(
//                 color: _getCategoryColor(_selectedFood!.category),
//                 borderRadius: BorderRadius.circular(12),
//               ),
//               child: Text(
//                 _selectedFood!.category,
//                 style: const TextStyle(
//                   color: Colors.white,
//                   fontSize: 12,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ),
//             const SizedBox(height: 16),

//             // 数量输入
//             Row(
//               children: [
//                 Expanded(
//                   flex: 2,
//                   child: TextField(
//                     controller: _quantityController,
//                     keyboardType:
//                         const TextInputType.numberWithOptions(decimal: true),
//                     decoration: InputDecoration(
//                       labelText: '数量',
//                       suffixText: _selectedFood!.unit,
//                       border: const OutlineInputBorder(),
//                       contentPadding: const EdgeInsets.symmetric(
//                         horizontal: 12,
//                         vertical: 8,
//                       ),
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   flex: 3,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: Colors.orange.shade50,
//                       border: Border.all(color: Colors.orange.shade200),
//                       borderRadius: BorderRadius.circular(8),
//                     ),
//                     child: Column(
//                       children: [
//                         Text(
//                           '${totalCalories.round()}',
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.bold,
//                             color: Colors.orange.shade700,
//                           ),
//                         ),
//                         const Text(
//                           '卡路里',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey,
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 16),

//             // 快速数量选择
//             Wrap(
//               spacing: 8,
//               children: [50.0, 100.0, 150.0, 200.0].map((amount) {
//                 return GestureDetector(
//                   onTap: () {
//                     _quantityController.text = amount.toString();
//                     setState(() => _quantity = amount);
//                   },
//                   child: Container(
//                     padding:
//                         const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                     decoration: BoxDecoration(
//                       color: _quantity == amount
//                           ? Colors.purple.shade100
//                           : Colors.grey.shade100,
//                       borderRadius: BorderRadius.circular(16),
//                       border: Border.all(
//                         color: _quantity == amount
//                             ? Colors.purple.shade300
//                             : Colors.grey.shade300,
//                       ),
//                     ),
//                     child: Text(
//                       '${amount.toInt()}${_selectedFood!.unit}',
//                       style: TextStyle(
//                         color: _quantity == amount
//                             ? Colors.purple.shade700
//                             : Colors.grey.shade700,
//                         fontWeight: FontWeight.w500,
//                         fontSize: 12,
//                       ),
//                     ),
//                   ),
//                 );
//               }).toList(),
//             ),
//             const SizedBox(height: 16),

//             // 营养信息
//             if (_selectedFood!.protein != null ||
//                 _selectedFood!.carbs != null ||
//                 _selectedFood!.fat != null) ...[
//               const Divider(),
//               const SizedBox(height: 8),
//               Text(
//                 '营养信息 (每${_quantity}${_selectedFood!.unit})',
//                 style: const TextStyle(
//                   fontSize: 14,
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//               const SizedBox(height: 8),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   if (_selectedFood!.protein != null)
//                     _buildNutritionItem(
//                         '蛋白质',
//                         (_selectedFood!.protein! * _quantity)
//                             .toStringAsFixed(1),
//                         'g',
//                         Colors.red),
//                   if (_selectedFood!.carbs != null)
//                     _buildNutritionItem(
//                         '碳水',
//                         (_selectedFood!.carbs! * _quantity).toStringAsFixed(1),
//                         'g',
//                         Colors.amber),
//                   if (_selectedFood!.fat != null)
//                     _buildNutritionItem(
//                         '脂肪',
//                         (_selectedFood!.fat! * _quantity).toStringAsFixed(1),
//                         'g',
//                         Colors.purple),
//                 ],
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildNutritionItem(
//       String label, String value, String unit, Color color) {
//     return Column(
//       children: [
//         Text(
//           value,
//           style: TextStyle(
//             fontSize: 16,
//             fontWeight: FontWeight.bold,
//             color: color,
//           ),
//         ),
//         Text(
//           '$unit $label',
//           style: const TextStyle(
//             fontSize: 10,
//             color: Colors.grey,
//           ),
//         ),
//       ],
//     );
//   }

//   Color _getCategoryColor(String category) {
//     switch (category) {
//       case '主食':
//         return Colors.orange;
//       case '蛋白质':
//         return Colors.red;
//       case '蔬菜':
//         return Colors.green;
//       case '水果':
//         return Colors.purple;
//       case '零食':
//         return Colors.brown;
//       case '饮品':
//         return Colors.blue;
//       default:
//         return Colors.grey;
//     }
//   }
// }
