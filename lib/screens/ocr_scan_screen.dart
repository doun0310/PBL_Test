import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

class OCRScanScreen extends StatefulWidget {
  const OCRScanScreen({super.key});

  @override
  State<OCRScanScreen> createState() => _OCRScanScreenState();
}

class _OCRScanScreenState extends State<OCRScanScreen> {
  String? _imagePath;
  bool _isScanning = false;
  Map<String, dynamic>? _scannedData;
  final _nameController = TextEditingController();

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _imagePath = pickedFile.path;
        _scannedData = null;
      });
      _scanNutritionLabel();
    }
  }

  Future<void> _scanNutritionLabel() async {
    if (_imagePath == null) return;

    setState(() => _isScanning = true);

    try {
      final nutritionInfo = await OCRService.scanNutritionLabel(_imagePath!);
      
      setState(() {
        _scannedData = nutritionInfo;
        _isScanning = false;
      });

      if (_scannedData != null && OCRService.validateNutritionInfo(_scannedData!)) {
        _showSuccessMessage();
      } else {
        _showErrorMessage('영양 정보를 찾을 수 없습니다. 수동으로 입력해주세요.');
      }
    } catch (e) {
      setState(() => _isScanning = false);
      _showErrorMessage('스캔 중 오류가 발생했습니다: $e');
    }
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('영양성분표 스캔 완료! ✓'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _saveFoodItem() {
    if (_nameController.text.isEmpty) {
      _showErrorMessage('음식 이름을 입력해주세요.');
      return;
    }

    if (_scannedData == null) {
      _showErrorMessage('영양 정보를 스캔해주세요.');
      return;
    }

    final cleanedData = OCRService.cleanNutritionInfo(_scannedData!);
    final foodItem = OCRService.createFoodItemFromScan(
      _nameController.text,
      cleanedData,
    );

    if (foodItem != null) {
      Navigator.pop(context, foodItem);
    } else {
      _showErrorMessage('음식 정보 생성에 실패했습니다.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('영양성분표 스캔'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildInstructionCard(),
            const SizedBox(height: 16),
            _buildImageSection(),
            const SizedBox(height: 16),
            if (_isScanning) _buildScanningIndicator(),
            if (_scannedData != null) _buildScannedDataSection(),
            const SizedBox(height: 24),
            if (_scannedData != null) _buildSaveButton(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomButtons(),
    );
  }

  Widget _buildInstructionCard() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                const Text(
                  '사용 방법',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('1. 영양성분표를 카메라로 촬영하거나 갤러리에서 선택'),
            const SizedBox(height: 4),
            const Text('2. 자동으로 영양 정보를 인식합니다'),
            const SizedBox(height: 4),
            const Text('3. 음식 이름을 입력하고 저장'),
            const SizedBox(height: 8),
            Text(
              '💡 팁: 영양성분표가 잘 보이도록 깨끗하게 촬영해주세요',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    if (_imagePath == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[400]!, width: 2, style: BorderStyle.solid),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.camera_alt, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                '영양성분표 사진을 추가하세요',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(_imagePath!),
        height: 300,
        fit: BoxFit.contain, // BoxFit.cover를 BoxFit.contain으로 변경
      ),
    );
  }

  Widget _buildScanningIndicator() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              '영양성분표를 분석하는 중...',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScannedDataSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    const Text(
                      '스캔 결과',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '음식 이름',
                    hintText: '예: 닭가슴살 샐러드',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                _buildNutritionRow('칼로리', _scannedData!['calories'], 'kcal'),
                _buildNutritionRow('단백질', _scannedData!['protein'], 'g'),
                _buildNutritionRow('탄수화물', _scannedData!['carbs'], 'g'),
                _buildNutritionRow('지방', _scannedData!['fat'], 'g'),
                _buildNutritionRow('1회 제공량', _scannedData!['servingSize'], 'g'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNutritionRow(String label, dynamic value, String unit) {
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
            '${value?.toStringAsFixed(1) ?? '0.0'} $unit',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return ElevatedButton.icon(
      onPressed: _saveFoodItem,
      icon: const Icon(Icons.save),
      label: const Text('음식 정보 저장'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        textStyle: const TextStyle(fontSize: 18),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickImage(ImageSource.gallery),
                icon: const Icon(Icons.photo_library),
                label: const Text('갤러리'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _pickImage(ImageSource.camera),
                icon: const Icon(Icons.camera_alt),
                label: const Text('카메라'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('도움말'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '영양성분표 스캔 가이드',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 12),
              Text('✓ 조명이 밝은 곳에서 촬영하세요'),
              SizedBox(height: 8),
              Text('✓ 영양성분표가 화면 중앙에 오도록 하세요'),
              SizedBox(height: 8),
              Text('✓ 글자가 선명하게 보이도록 초점을 맞추세요'),
              SizedBox(height: 8),
              Text('✓ 반사광이 없는 각도로 촬영하세요'),
              SizedBox(height: 12),
              Text(
                '인식되는 정보',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              SizedBox(height: 8),
              Text('• 칼로리 (열량)'),
              Text('• 단백질'),
              Text('• 탄수화물'),
              Text('• 지방'),
              Text('• 1회 제공량'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
