import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../services/ocr_service.dart';
import '../models/nutrition_label.dart';

class NutritionLabelScanScreen extends StatefulWidget {
  const NutritionLabelScanScreen({Key? key}) : super(key: key);

  @override
  State<NutritionLabelScanScreen> createState() => _NutritionLabelScanScreenState();
}

class _NutritionLabelScanScreenState extends State<NutritionLabelScanScreen> {
  File? _imageFile;
  NutritionLabel? _nutritionData;
  bool _isProcessing = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _nutritionData = null;
        });
        _processImage();
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

  Future<void> _processImage() async {
    if (_imageFile == null) return;

    setState(() => _isProcessing = true);

    try {
      final nutrition = await OCRService.extractNutritionLabel(_imageFile!);
      setState(() {
        _nutritionData = nutrition;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() => _isProcessing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('성분표 인식 오류: ${e.toString()}'),
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

  void _saveNutritionData() {
    if (_nutritionData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('저장할 영양 정보가 없습니다'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // 실제 구현에서는 API 호출하여 서버에 저장
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('영양 정보가 저장되었습니다'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, _nutritionData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영양성분표 인식'),
        actions: [
          if (_nutritionData != null)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveNutritionData,
              tooltip: '저장',
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showImageSourceSelector,
        icon: const Icon(Icons.camera_alt),
        label: const Text('사진 촬영'),
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
              Icons.qr_code_scanner,
              size: 100,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              '가공 식품의 영양성분표를\n촬영해주세요',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _showImageSourceSelector,
              icon: const Icon(Icons.camera_alt),
              label: const Text('사진 촬영하기'),
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
          // 촬영한 이미지
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

          // 처리 중 표시
          if (_isProcessing)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('영양성분표를 인식하는 중...'),
                  ],
                ),
              ),
            ),

          // 인식된 영양 정보
          if (!_isProcessing && _nutritionData != null) ...[
            Text(
              '인식된 영양 정보',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildNutritionCard(_nutritionData!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveNutritionData,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text(
                '저장하기',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNutritionCard(NutritionLabel nutrition) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (nutrition.productName != null) ...[
              Text(
                nutrition.productName!,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(height: 24),
            ],
            _buildNutrientRow('칼로리', '${nutrition.calories} kcal'),
            _buildNutrientRow('탄수화물', '${nutrition.carbohydrate} g'),
            _buildNutrientRow('당류', '${nutrition.sugars} g'),
            _buildNutrientRow('단백질', '${nutrition.protein} g'),
            _buildNutrientRow('지방', '${nutrition.fat} g'),
            _buildNutrientRow('포화지방', '${nutrition.saturatedFat} g'),
            _buildNutrientRow('트랜스지방', '${nutrition.transFat} g'),
            _buildNutrientRow('콜레스테롤', '${nutrition.cholesterol} mg'),
            _buildNutrientRow('나트륨', '${nutrition.sodium} mg'),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
