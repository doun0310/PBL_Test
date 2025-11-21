import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import '../models/meal_entry.dart';
import '../models/food_item.dart';
import '../services/meal_tracking_service.dart';
import 'food_search_screen.dart';
import 'photo_analysis_screen.dart';
import 'ocr_scan_screen.dart';

class AddMealScreen extends StatefulWidget {
  final VoidCallback? onMealAdded;
  final DateTime? initialDate;

  const AddMealScreen({
    super.key, 
    this.onMealAdded,
    this.initialDate,
  });

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  MealType _selectedMealType = MealType.breakfast;
  final List<FoodItemEntry> _selectedFoods = [];
  String? _photoPath;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text(
          '식사 추가',
          style: TextStyle(color: Color(0xFF2C3E50)),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF2C3E50)),
        actions: [
          if (_selectedFoods.isNotEmpty)
            TextButton(
              onPressed: _saveMeal,
              child: const Text(
                '저장',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildDateSelector(),
            _buildMealTypeSelector(),
            Expanded(
              child: _selectedFoods.isEmpty
                  ? _buildAddOptions()
                  : _buildFoodsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealTypeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: MealType.values.map((type) {
          final isSelected = _selectedMealType == type;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedMealType = type),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF4CAF50) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  type.displayName,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDateSelector() {
    final isToday = _selectedDate.year == DateTime.now().year &&
        _selectedDate.month == DateTime.now().month &&
        _selectedDate.day == DateTime.now().day;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            isToday
                ? '오늘'
                : DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDate),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF2C3E50),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () {
                  setState(() {
                    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: _selectDate,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () {
                  if (!isToday) {
                    setState(() {
                      _selectedDate = _selectedDate.add(const Duration(days: 1));
                    });
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      locale: const Locale('ko', 'KR'),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildAddOptions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildOptionCard(
            icon: Icons.camera_alt,
            title: '사진으로 음식 분석',
            subtitle: '음식 사진을 찍어 자동으로 분석',
            color: const Color(0xFF4CAF50),
            onTap: () => _pickImageAndAnalyze(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            icon: Icons.photo_library,
            title: '갤러리에서 선택',
            subtitle: '기존 사진에서 음식 분석',
            color: const Color(0xFF2196F3),
            onTap: () => _pickImageAndAnalyze(ImageSource.gallery),
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            icon: Icons.qr_code_scanner,
            title: '영양성분표 스캔',
            subtitle: '제품의 영양 정보 자동 입력',
            color: const Color(0xFFFF9800),
            onTap: _scanNutritionLabel,
          ),
          const SizedBox(height: 16),
          _buildOptionCard(
            icon: Icons.search,
            title: '직접 검색',
            subtitle: '음식을 검색하여 추가',
            color: const Color(0xFF9C27B0),
            onTap: _searchFood,
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodsList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _selectedFoods.length,
            itemBuilder: (context, index) {
              final foodEntry = _selectedFoods[index];
              return _buildFoodItem(foodEntry, index);
            },
          ),
        ),
        _buildAddMoreButton(),
      ],
    );
  }

  Widget _buildFoodItem(FoodItemEntry foodEntry, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
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
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () {
                    setState(() => _selectedFoods.removeAt(index));
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('섭취량: '),
                Expanded(
                  child: Slider(
                    value: foodEntry.servingSize,
                    min: 10,
                    max: foodEntry.foodItem.servingSize * 3,
                    divisions: 20,
                    label: '${foodEntry.servingSize.toInt()}${foodEntry.foodItem.unit}',
                    onChanged: (value) {
                      setState(() {
                        _selectedFoods[index] = foodEntry.copyWith(
                          servingSize: value,
                        );
                      });
                    },
                  ),
                ),
                Text('${foodEntry.servingSize.toInt()}${foodEntry.foodItem.unit}'),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNutrientChip('${foodEntry.totalCalories.toInt()} kcal'),
                  _buildNutrientChip('탄 ${foodEntry.totalCarbs.toInt()}g'),
                  _buildNutrientChip('단 ${foodEntry.totalProtein.toInt()}g'),
                  _buildNutrientChip('지 ${foodEntry.totalFat.toInt()}g'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientChip(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    );
  }

  Widget _buildAddMoreButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _searchFood,
        icon: const Icon(Icons.add),
        label: const Text('음식 추가'),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImageAndAnalyze(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null && mounted) {
      final result = await Navigator.push<List<FoodItemEntry>>(
        context,
        MaterialPageRoute(
          builder: (context) => PhotoAnalysisScreen(
            imagePath: pickedFile.path,
          ),
        ),
      );

      if (result != null && result.isNotEmpty) {
        setState(() {
          _selectedFoods.addAll(result);
          _photoPath = pickedFile.path;
        });
      }
    }
  }

  Future<void> _scanNutritionLabel() async {
    final result = await Navigator.push<FoodItem>(
      context,
      MaterialPageRoute(
        builder: (context) => const OCRScanScreen(),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _selectedFoods.add(FoodItemEntry(
          foodItem: result,
          servingSize: result.servingSize,
        ));
      });
    }
  }

  Future<void> _searchFood() async {
    final result = await Navigator.push<List<FoodItemEntry>>(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodSearchScreen(),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _selectedFoods.addAll(result));
    }
  }

  Future<void> _saveMeal() async {
    if (_selectedFoods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('음식을 추가해주세요')),
      );
      return;
    }

    final meal = MealEntry(
      id: const Uuid().v4(),
      timestamp: DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        DateTime.now().hour,
        DateTime.now().minute,
      ),
      mealType: _selectedMealType,
      foodItems: _selectedFoods,
      photoPath: _photoPath,
    );

    try {
      await MealTrackingService.addMeal(meal);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('식사가 저장되었습니다')),
        );
        widget.onMealAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('저장 실패: $e')),
        );
      }
    }
  }
}
