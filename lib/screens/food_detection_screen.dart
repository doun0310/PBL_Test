import 'package:flutter/material.dart';
import '../services/food_detection_service.dart';

class FoodDetectionScreen extends StatefulWidget {
  const FoodDetectionScreen({super.key});

  @override
  State<FoodDetectionScreen> createState() => _FoodDetectionScreenState();
}

class _FoodDetectionScreenState extends State<FoodDetectionScreen> {
  final FoodDetectionService _detector = FoodDetectionService();
  List<Detection> _detections = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeModel();
  }

  Future<void> _initializeModel() async {
    setState(() => _isLoading = true);

    try {
      await _detector.loadModel();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('모델 로드 완료!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모델 로드 실패: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _detectFood(String imagePath) async {
    setState(() => _isLoading = true);

    try {
      final detections = await _detector.detectFood(imagePath);

      setState(() {
        _detections = detections;
      });

      print('✅ ${detections.length}개 음식 인식됨');
      for (final detection in detections) {
        print(
            '  - ${detection.className}: ${(detection.confidence * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      print('❌ 인식 실패: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _detector.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('음식 인식')),
      body: Column(
        children: [
          // TODO: 이미지 선택 및 _detectFood(imagePath) 호출 기능 구현 필요
          // 예: ElevatedButton(onPressed: () => _detectFood('path/to/image.jpg'), child: Text('이미지 선택')),
          if (_isLoading) const CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _detections.length,
              itemBuilder: (context, index) {
                final detection = _detections[index];
                return ListTile(
                  title: Text(detection.className),
                  subtitle: Text(
                      '신뢰도: ${(detection.confidence * 100).toStringAsFixed(1)}%'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
