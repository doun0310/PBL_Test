import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/meal.dart';
import '../services/food_recognition_service.dart';

class FoodRecognitionScreen extends StatefulWidget {
  const FoodRecognitionScreen({Key? key}) : super(key: key);

  @override
  State<FoodRecognitionScreen> createState() => _FoodRecognitionScreenState();
}

class _FoodRecognitionScreenState extends State<FoodRecognitionScreen> {
  File? _imageFile;
  List<Meal>? _recognizedFoods;
  bool _isAnalyzing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _recognizedFoods = null;
        });
        _analyzeImage();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('이미지 선택 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _analyzeImage() async {
    if (_imageFile == null) return;

    setState(() => _isAnalyzing = true);

    try {
      final foods = await FoodRecognitionService.recognizeFood(_imageFile!);
      setState(() {
        _recognizedFoods = foods;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('음식 인식 오류: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('카메라로 촬영'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('갤러리에서 선택'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _saveMeals() {
    if (_recognizedFoods == null || _recognizedFoods!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장할 음식이 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 실제 구현에서는 API 호출하여 서버에 저장
    Navigator.pop(context, _recognizedFoods);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 사진 인식'),
        actions: [
          if (_recognizedFoods != null && _recognizedFoods!.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveMeals,
              tooltip: '식단에 추가',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceSelector,
        icon: const Icon(Icons.add_a_photo),
        label: const Text('사진 선택'),
      ),
    );
  }

  Widget _buildBody() {
    if (_imageFile == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.camera_alt,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '음식 사진을 촬영하거나\n갤러리에서 선택해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showImageSourceSelector,
              icon: const Icon(Icons.add_a_photo),
              label: const Text('사진 선택하기'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 선택한 이미지 표시
          Card(
            elevation: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.file(
                _imageFile!,
                fit: BoxFit.cover,
                height: 300,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 분석 중 표시
          if (_isAnalyzing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('음식을 인식하는 중...'),
                  ],
                ),
              ),
            ),

          // 인식된 음식 목록
          if (!_isAnalyzing && _recognizedFoods != null) ...[
            Text(
              '인식된 음식',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            if (_recognizedFoods!.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('음식을 인식하지 못했습니다.\n다른 사진을 시도해보세요.'),
                  ),
                ),
              )
            else
              ..._recognizedFoods!.map((meal) => _buildFoodCard(meal)),
            const SizedBox(height: 16),
            if (_recognizedFoods!.isNotEmpty)
              ElevatedButton(
                onPressed: _saveMeals,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  '식단에 추가하기',
                  style: TextStyle(fontSize: 16),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFoodCard(Meal meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  meal.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${meal.calories} kcal',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutrientChip('단백질', '${meal.protein}g'),
                _buildNutrientChip('탄수화물', '${meal.carbs}g'),
                _buildNutrientChip('지방', '${meal.fat}g'),
              ],
            ),
            if (meal.allergens.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: meal.allergens.map((allergen) {
                  return Chip(
                    label: Text(
                      allergen,
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.orange[100],
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String label, String value) {
    return Chip(
      label: Text('$label: $value'),
      backgroundColor: Colors.blue[50],
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}
