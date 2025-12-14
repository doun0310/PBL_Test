import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart'; // Rect 클래스 사용을 위해 추가
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import '../models/food_item.dart';
import 'food_database_service.dart';

/// YOLO v8 기반 음식 인식 서비스
class AIFoodRecognitionService {
  static Interpreter? _interpreter;
  static List<String>? _labels;
  static bool _isModelLoaded = false;

  // YOLO v8 모델 설정
  static const int _inputSize = 640;
  static const double _confidenceThreshold = 0.5;
  static const double _iouThreshold = 0.45;

  /// YOLO v8 모델 초기화
  static Future<void> initializeModel() async {
    if (_isModelLoaded) return;

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/best_float32.tflite');
      final labelsData = await rootBundle.loadString('assets/labels/food_labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      _isModelLoaded = true;
      print('✅ YOLOv8 모델 및 라벨 로드 완료: ${_labels?.length} 클래스');
    } catch (e) {
      _isModelLoaded = false;
      print('❌ 모델 로드 실패: $e');
    }
  }

  /// YOLO v8을 사용한 음식 인식
  static Future<List<FoodItem>> recognizeFood(String imagePath) async {
    try {
      if (!_isModelLoaded) {
        await initializeModel();
      }

      if (_interpreter != null && _isModelLoaded) {
        return await _runYoloInference(imagePath);
      }

      return _simulateYoloRecognition(imagePath);
    } catch (e) {
      print('❌ 음식 인식 중 에러 발생: $e');
      return _simulateYoloRecognition(imagePath);
    }
  }

  /// YOLO v8 추론 실행
  static Future<List<FoodItem>> _runYoloInference(String imagePath) async {
    final originalImage = img.decodeImage(await File(imagePath).readAsBytes())!;
    final originalWidth = originalImage.width;
    final originalHeight = originalImage.height;

    final input = await _preprocessImage(imagePath);

    // YOLOv8 출력 형태: [1, 84, 8400] (84 = 4(box) + 80(classes))
    final output = List.filled(1 * (_labels!.length + 4) * 8400, 0.0)
        .reshape([1, _labels!.length + 4, 8400]);

    _interpreter!.run(input, output);

    final detections = _postprocessYoloOutput(output, originalWidth, originalHeight);
    return _detectionsToFoodItems(detections);
  }

  /// 이미지 전처리 (YOLO v8 입력 형식)
  static Future<List<List<List<List<double>>>>> _preprocessImage(String imagePath) async {
    final imageData = await File(imagePath).readAsBytes();
    final image = img.decodeImage(imageData)!;
    final resizedImage = img.copyResize(image, width: _inputSize, height: _inputSize);

    final imageMatrix = List.generate(
      _inputSize,
          (y) => List.generate(
        _inputSize,
            (x) {
          final pixel = resizedImage.getPixel(x, y);
          return [pixel.r / 255.0, pixel.g / 255.0, pixel.b / 255.0];
        },
      ),
    );

    return [imageMatrix];
  }

  /// YOLO v8 출력 후처리
  static List<Map<String, dynamic>> _postprocessYoloOutput(
      List<dynamic> output,
      int originalWidth,
      int originalHeight,
      ) {
    final List<Rect> boxes = [];
    final List<double> confidences = [];
    final List<int> classIndexes = [];

    final List<List<double>> transposedOutput = _transpose(output[0]);

    for (final row in transposedOutput) {
      final classScores = row.sublist(4);
      double maxScore = 0.0;
      int maxScoreIndex = -1;

      for (int i = 0; i < classScores.length; i++) {
        if (classScores[i] > maxScore) {
          maxScore = classScores[i];
          maxScoreIndex = i;
        }
      }

      if (maxScore > _confidenceThreshold) {
        final cx = row[0];
        final cy = row[1];
        final w = row[2];
        final h = row[3];

        final scaleX = originalWidth / _inputSize;
        final scaleY = originalHeight / _inputSize;

        final left = (cx - w / 2) * scaleX;
        final top = (cy - h / 2) * scaleY;
        final width = w * scaleX;
        final height = h * scaleY;

        boxes.add(Rect.fromLTWH(left, top, width, height));
        confidences.add(maxScore);
        classIndexes.add(maxScoreIndex);
      }
    }

    final nmsIndexes = _applyNMS(boxes, confidences);
    final List<Map<String, dynamic>> detections = [];
    for (final index in nmsIndexes) {
      detections.add({
        'class': _labels![classIndexes[index]],
        'confidence': confidences[index],
        'bbox': boxes[index],
      });
    }
    return detections;
  }

  /// 2D 리스트를 전치(transpose)합니다. [M, N] -> [N, M]
  static List<List<double>> _transpose(List<List<double>> matrix) {
    if (matrix.isEmpty) return [];
    final rows = matrix.length;
    final cols = matrix[0].length;
    final transposed = List.generate(cols, (_) => List<double>.filled(rows, 0.0));
    for (var i = 0; i < rows; i++) {
      for (var j = 0; j < cols; j++) {
        transposed[j][i] = matrix[i][j];
      }
    }
    return transposed;
  }

  /// Non-Maximum Suppression 적용
  static List<int> _applyNMS(List<Rect> boxes, List<double> scores) {
    var indices = List<int>.generate(scores.length, (i) => i);
    indices.sort((a, b) => scores[b].compareTo(scores[a]));

    final List<int> keep = [];
    while (indices.isNotEmpty) {
      final i = indices.removeAt(0);
      keep.add(i);
      indices = indices.where((j) {
        final iou = _calculateIoU(boxes[i], boxes[j]);
        return iou <= _iouThreshold;
      }).toList();
    }
    return keep;
  }

  /// IoU (Intersection over Union) 계산
  static double _calculateIoU(Rect box1, Rect box2) {
    final intersectionLeft = max(box1.left, box2.left);
    final intersectionTop = max(box1.top, box2.top);
    final intersectionRight = min(box1.right, box2.right);
    final intersectionBottom = min(box1.bottom, box2.bottom);

    final intersectionArea = max(0, intersectionRight - intersectionLeft) *
        max(0, intersectionBottom - intersectionTop);

    final box1Area = box1.width * box1.height;
    final box2Area = box2.width * box2.height;
    final unionArea = box1Area + box2Area - intersectionArea;

    return unionArea > 0 ? intersectionArea / unionArea : 0;
  }

  /// 감지 결과를 FoodItem으로 변환
  static List<FoodItem> _detectionsToFoodItems(List<Map<String, dynamic>> detections) {
    final recognizedFoods = <FoodItem>[];
    final allFoods = FoodDatabaseService.getAllFoods();

    for (var detection in detections) {
      final className = detection['class'] as String;
      final matchedFood = _findMatchingFood(className, allFoods);

      if (matchedFood != null && !recognizedFoods.any((f) => f.name == matchedFood.name)) {
        recognizedFoods.add(matchedFood);
      }
    }

    if (recognizedFoods.isEmpty) {
      recognizedFoods.addAll(_getSuggestedFoods(allFoods, 3));
    }

    return recognizedFoods;
  }

  /// YOLO 시뮬레이션 (모델 없을 때)
  static List<FoodItem> _simulateYoloRecognition(String imagePath) {
    final allFoods = FoodDatabaseService.getAllFoods();
    final random = Random();
    final detectedCount = random.nextInt(3) + 1;
    final shuffled = List<FoodItem>.from(allFoods)..shuffle();
    return shuffled.take(detectedCount).toList();
  }

  // 라벨과 음식 매칭
  static FoodItem? _findMatchingFood(String label, List<FoodItem> foods) {
    final labelLower = label.toLowerCase();
    for (var food in foods) {
      if (food.name.toLowerCase().contains(labelLower) ||
          labelLower.contains(food.name.toLowerCase())) {
        return food;
      }
    }
    return null;
  }

  // 추천 음식 제공
  static List<FoodItem> _getSuggestedFoods(List<FoodItem> allFoods, int count) {
    final shuffled = List<FoodItem>.from(allFoods)..shuffle();
    return shuffled.take(min(count, allFoods.length)).toList();
  }

  // 리소스 정리
  static Future<void> dispose() async {
    _interpreter?.close();
    _interpreter = null;
    _labels = null;
    _isModelLoaded = false;
  }

// (이하 다른 헬퍼 함수들은 기존 코드와 동일하게 유지)
// ...
}
