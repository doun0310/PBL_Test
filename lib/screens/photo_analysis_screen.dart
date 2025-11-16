import 'dart:io';
import 'package:flutter/material.dart';
import '../models/meal_entry.dart';
import '../services/food_database_service.dart';

class PhotoAnalysisScreen extends StatefulWidget {
  final String imagePath;

  const PhotoAnalysisScreen({
    super.key,
    required this.imagePath,
  });

  @override
  State<PhotoAnalysisScreen> createState() => _PhotoAnalysisScreenState();
}

class _PhotoAnalysisScreenState extends State<PhotoAnalysisScreen> {
  bool _isAnalyzing = true;
  List<FoodItemEntry> _detectedFoods = [];

  @override
  void initState() {
    super.initState();
    _analyzeImage();
  }

  Future<void> _analyzeImage() async {
    // 실제 AI 분석 대신 모의 분석 수행
    await Future.delayed(const Duration(seconds: 2));

    // 샘플 검출 결과 (실제로는 AI 모델 사용)
    final sampleFoods = FoodDatabaseService.getAllFoods();
    final randomFoods = (sampleFoods..shuffle()).take(3).toList();

    setState(() {
      _detectedFoods = randomFoods.map((food) {
        return FoodItemEntry(
          foodItem: food,
          servingSize: food.servingSize,
        );
      }).toList();
      _isAnalyzing = false;
    });
  }

  void _confirmSelection() {
    Navigator.pop(context, _detectedFoods);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('음식 분석'),
        actions: [
          if (!_isAnalyzing && _detectedFoods.isNotEmpty)
            TextButton(
              onPressed: _confirmSelection,
              child: const Text(
                '확인',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _buildImagePreview(),
          Expanded(
            child: _isAnalyzing
                ? _buildAnalyzingView()
                : _buildDetectedFoods(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    return Container(
      height: 250,
      width: double.infinity,
      color: Colors.black,
      child: Image.file(
        File(widget.imagePath),
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildAnalyzingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF4CAF50)),
          ),
          const SizedBox(height: 24),
          const Text(
            'AI로 음식 분석 중...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '잠시만 기다려주세요',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetectedFoods() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF4CAF50).withOpacity(0.1),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: Color(0xFF4CAF50),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_detectedFoods.length}개의 음식을 발견했습니다',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '각 음식의 양을 조절할 수 있습니다',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _detectedFoods.length,
            itemBuilder: (context, index) {
              return _buildFoodCard(index);
            },
          ),
        ),
        _buildTotalNutrition(),
      ],
    );
  }

  Widget _buildFoodCard(int index) {
    final foodEntry = _detectedFoods[index];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    foodEntry.foodItem.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() => _detectedFoods.removeAt(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  '양: ',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                Expanded(
                  child: Slider(
                    value: foodEntry.servingSize,
                    min: 10,
                    max: foodEntry.foodItem.servingSize * 3,
                    divisions: 20,
                    label: '${foodEntry.servingSize.toInt()}${foodEntry.foodItem.unit}',
                    activeColor: const Color(0xFF4CAF50),
                    onChanged: (value) {
                      setState(() {
                        _detectedFoods[index] = foodEntry.copyWith(
                          servingSize: value,
                        );
                      });
                    },
                  ),
                ),
                Text(
                  '${foodEntry.servingSize.toInt()}${foodEntry.foodItem.unit}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientInfo(
                    '칼로리',
                    '${foodEntry.totalCalories.toInt()}',
                    'kcal',
                  ),
                  _buildNutrientInfo(
                    '탄수화물',
                    '${foodEntry.totalCarbs.toInt()}',
                    'g',
                  ),
                  _buildNutrientInfo(
                    '단백질',
                    '${foodEntry.totalProtein.toInt()}',
                    'g',
                  ),
                  _buildNutrientInfo(
                    '지방',
                    '${foodEntry.totalFat.toInt()}',
                    'g',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C3E50),
                ),
              ),
              TextSpan(
                text: ' $unit',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalNutrition() {
    double totalCalories = 0;
    double totalCarbs = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var food in _detectedFoods) {
      totalCalories += food.totalCalories;
      totalCarbs += food.totalCarbs;
      totalProtein += food.totalProtein;
      totalFat += food.totalFat;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            const Text(
              '총 영양 정보',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildTotalNutrientChip('${totalCalories.toInt()} kcal'),
                _buildTotalNutrientChip('탄 ${totalCarbs.toInt()}g'),
                _buildTotalNutrientChip('단 ${totalProtein.toInt()}g'),
                _buildTotalNutrientChip('지 ${totalFat.toInt()}g'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalNutrientChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
