# Flutter Integration Guide
Complete guide for integrating ML models with Flutter app

## 목차 (Table of Contents)
1. [YOLO v8 TFLite 통합](#1-yolo-v8-tflite-integration)
2. [EasyOCR REST API 통합](#2-easyocr-rest-api-integration)
3. [Collaborative Filtering REST API 통합](#3-collaborative-filtering-rest-api-integration)
4. [완전한 통합 예제](#4-complete-integration-example)

---

## 1. YOLO v8 TFLite Integration

### 1.1 모델 학습 및 변환

```bash
cd ml_training

# YOLO 모델 학습
python yolo_training.py --data data.yaml --epochs 100

# TFLite 모델은 자동으로 생성됩니다:
# runs/detect/train/weights/best.tflite
```

### 1.2 Flutter 프로젝트 설정

**pubspec.yaml** 수정:
```yaml
dependencies:
  flutter:
    sdk: flutter
  tflite_flutter: ^0.10.4
  tflite_flutter_helper: ^0.3.1
  image: ^4.0.17
  camera: ^0.10.5
  path_provider: ^2.1.1

flutter:
  assets:
    - assets/models/
    - assets/labels/
```

### 1.3 모델 파일 복사

```bash
# Flutter 프로젝트 루트에서 실행
mkdir -p assets/models assets/labels

# TFLite 모델 복사
cp ml_training/runs/detect/train/weights/best.tflite assets/models/

# 라벨 파일 생성 (data.yaml에서 추출)
cat > assets/labels/food_labels.txt << EOF
Bread
Dairy
Dessert
Egg
Fried food
Meat
Noodles-Pasta
Rice
Seafood
Soup
Vegetable-Fruit
EOF
```

### 1.4 FoodDetectionService 구현

**lib/services/food_detection_service.dart**:
```dart
import 'dart:io';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Detection {
  final String className;
  final double confidence;
  final Rect boundingBox;
  
  Detection({
    required this.className,
    required this.confidence,
    required this.boundingBox,
  });
}

class FoodDetectionService {
  Interpreter? _interpreter;
  List<String>? _labels;
  
  static const int inputSize = 640; // YOLO v8 input size
  static const double confidenceThreshold = 0.5;
  static const double iouThreshold = 0.45;
  
  /// 모델 초기화
  Future<void> loadModel() async {
    try {
      // TFLite 모델 로드
      _interpreter = await Interpreter.fromAsset('assets/models/best.tflite');
      
      // 라벨 로드
      final labelsData = await rootBundle.loadString('assets/labels/food_labels.txt');
      _labels = labelsData.split('\n').where((label) => label.isNotEmpty).toList();
      
      print('✅ YOLO 모델 로드 완료: ${_labels?.length} 클래스');
    } catch (e) {
      print('❌ 모델 로드 실패: $e');
      rethrow;
    }
  }
  
  /// 음식 인식 실행
  Future<List<Detection>> detectFood(String imagePath) async {
    if (_interpreter == null || _labels == null) {
      throw Exception('모델이 로드되지 않았습니다. loadModel()을 먼저 호출하세요.');
    }
    
    // 이미지 로드
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final image = img.decodeImage(imageBytes);
    
    if (image == null) {
      throw Exception('이미지 로드 실패');
    }
    
    // 이미지 전처리
    final inputImage = _preprocessImage(image);
    
    // 추론 실행
    final output = _runInference(inputImage);
    
    // 결과 후처리
    final detections = _postprocessOutput(output, image.width, image.height);
    
    return detections;
  }
  
  /// 이미지 전처리 (640x640 리사이즈 및 정규화)
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    // 640x640으로 리사이즈
    final resized = img.copyResize(image, width: inputSize, height: inputSize);
    
    // [1, 640, 640, 3] 형태로 변환
    final input = List.generate(
      1,
      (_) => List.generate(
        inputSize,
        (y) => List.generate(
          inputSize,
          (x) {
            final pixel = resized.getPixel(x, y);
            return [
              pixel.r / 255.0, // Red 정규화
              pixel.g / 255.0, // Green 정규화
              pixel.b / 255.0, // Blue 정규화
            ];
          },
        ),
      ),
    );
    
    return input;
  }
  
  /// 추론 실행
  List _runInference(List<List<List<List<double>>>> input) {
    // YOLO v8 출력 형태: [1, 84, 8400] or [1, 25200, 85]
    var output = List.filled(1 * 8400 * 85, 0.0).reshape([1, 8400, 85]);
    
    _interpreter!.run(input, output);
    
    return output;
  }
  
  /// 결과 후처리 (NMS 적용)
  List<Detection> _postprocessOutput(List output, int imageWidth, int imageHeight) {
    final detections = <Detection>[];
    
    // 출력에서 detection 추출
    for (int i = 0; i < output[0].length; i++) {
      final detection = output[0][i];
      
      // [x, y, w, h, confidence, class_scores...]
      final confidence = detection[4] as double;
      
      if (confidence < confidenceThreshold) continue;
      
      // 가장 높은 확률의 클래스 찾기
      int classId = 0;
      double maxScore = 0.0;
      
      for (int j = 5; j < detection.length; j++) {
        if (detection[j] > maxScore) {
          maxScore = detection[j] as double;
          classId = j - 5;
        }
      }
      
      final finalConfidence = confidence * maxScore;
      
      if (finalConfidence < confidenceThreshold) continue;
      
      // 바운딩 박스 계산
      final x = (detection[0] as double) * imageWidth / inputSize;
      final y = (detection[1] as double) * imageHeight / inputSize;
      final w = (detection[2] as double) * imageWidth / inputSize;
      final h = (detection[3] as double) * imageHeight / inputSize;
      
      detections.add(Detection(
        className: _labels![classId],
        confidence: finalConfidence,
        boundingBox: Rect.fromLTWH(
          x - w / 2,
          y - h / 2,
          w,
          h,
        ),
      ));
    }
    
    // NMS (Non-Maximum Suppression) 적용
    return _applyNMS(detections);
  }
  
  /// NMS 적용하여 중복 제거
  List<Detection> _applyNMS(List<Detection> detections) {
    // confidence로 정렬
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    
    final selected = <Detection>[];
    
    for (final detection in detections) {
      bool shouldSelect = true;
      
      for (final selectedDetection in selected) {
        final iou = _calculateIOU(detection.boundingBox, selectedDetection.boundingBox);
        
        if (iou > iouThreshold) {
          shouldSelect = false;
          break;
        }
      }
      
      if (shouldSelect) {
        selected.add(detection);
      }
    }
    
    return selected;
  }
  
  /// IOU (Intersection Over Union) 계산
  double _calculateIOU(Rect box1, Rect box2) {
    final x1 = max(box1.left, box2.left);
    final y1 = max(box1.top, box2.top);
    final x2 = min(box1.right, box2.right);
    final y2 = min(box1.bottom, box2.bottom);
    
    final intersection = max(0.0, x2 - x1) * max(0.0, y2 - y1);
    final union = box1.width * box1.height + box2.width * box2.height - intersection;
    
    return intersection / union;
  }
  
  /// 리소스 정리
  void dispose() {
    _interpreter?.close();
  }
}

class Rect {
  final double left;
  final double top;
  final double width;
  final double height;
  
  Rect.fromLTWH(this.left, this.top, this.width, this.height);
  
  double get right => left + width;
  double get bottom => top + height;
}
```

### 1.5 사용 예시

```dart
import 'package:flutter/material.dart';
import 'services/food_detection_service.dart';

class FoodDetectionScreen extends StatefulWidget {
  @override
  _FoodDetectionScreenState createState() => _FoodDetectionScreenState();
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모델 로드 완료!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('모델 로드 실패: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
        print('  - ${detection.className}: ${(detection.confidence * 100).toStringAsFixed(1)}%');
      }
    } catch (e) {
      print('❌ 인식 실패: $e');
    } finally {
      setState(() => _isLoading = false);
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
      appBar: AppBar(title: Text('음식 인식')),
      body: Column(
        children: [
          if (_isLoading) CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: _detections.length,
              itemBuilder: (context, index) {
                final detection = _detections[index];
                return ListTile(
                  title: Text(detection.className),
                  subtitle: Text('신뢰도: ${(detection.confidence * 100).toStringAsFixed(1)}%'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 2. EasyOCR REST API Integration

### 2.1 REST API 서버 시작

```bash
cd ml_training/api_servers

# 의존성 설치
pip install -r requirements.txt

# EasyOCR 서버 시작 (포트 5000)
python easyocr_server.py
```

### 2.2 OCRService 구현

**lib/services/ocr_service.dart**:
```dart
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NutritionInfo {
  final double? calories;
  final double? carbs;
  final double? protein;
  final double? fat;
  final String rawText;
  
  NutritionInfo({
    this.calories,
    this.carbs,
    this.protein,
    this.fat,
    required this.rawText,
  });
  
  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories']?.toDouble(),
      carbs: json['carbs']?.toDouble(),
      protein: json['protein']?.toDouble(),
      fat: json['fat']?.toDouble(),
      rawText: json['raw_text'] ?? '',
    );
  }
}

class OCRService {
  final String baseUrl;
  
  OCRService({this.baseUrl = 'http://localhost:5000'});
  
  /// 영양성분표 스캔
  Future<NutritionInfo> extractNutrition(String imagePath) async {
    try {
      final uri = Uri.parse('$baseUrl/extract_nutrition');
      
      var request = http.MultipartRequest('POST', uri);
      request.files.add(await http.MultipartFile.fromPath('image', imagePath));
      
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final json = jsonDecode(responseData);
        return NutritionInfo.fromJson(json);
      } else {
        throw Exception('OCR 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ OCR 오류: $e');
      rethrow;
    }
  }
  
  /// 헬스 체크
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

### 2.3 사용 예시

```dart
final ocrService = OCRService(baseUrl: 'http://192.168.1.100:5000');

// 서버 상태 확인
if (await ocrService.checkHealth()) {
  print('✅ OCR 서버 연결됨');
  
  // 영양성분표 스캔
  final nutrition = await ocrService.extractNutrition('/path/to/label.jpg');
  
  print('칼로리: ${nutrition.calories} kcal');
  print('탄수화물: ${nutrition.carbs}g');
  print('단백질: ${nutrition.protein}g');
  print('지방: ${nutrition.fat}g');
} else {
  print('❌ OCR 서버 연결 실패');
}
```

---

## 3. Collaborative Filtering REST API Integration

### 3.1 REST API 서버 시작

```bash
cd ml_training/api_servers

# 추천 서버 시작 (포트 5001)
python recommendation_server.py
```

### 3.2 RecommendationService 구현

**lib/services/recommendation_service.dart**:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodRecommendation {
  final String name;
  final double calories;
  final double carbs;
  final double protein;
  final double fat;
  final double score;
  
  FoodRecommendation({
    required this.name,
    required this.calories,
    required this.carbs,
    required this.protein,
    required this.fat,
    required this.score,
  });
  
  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      name: json['name'],
      calories: json['calories'].toDouble(),
      carbs: json['carbs'].toDouble(),
      protein: json['protein'].toDouble(),
      fat: json['fat'].toDouble(),
      score: json['score'].toDouble(),
    );
  }
}

class RecommendationService {
  final String baseUrl;
  
  RecommendationService({this.baseUrl = 'http://localhost:5001'});
  
  /// 영양 기반 추천
  Future<List<FoodRecommendation>> getNutritionRecommendations({
    required double targetCalories,
    required double targetCarbs,
    required double targetProtein,
    required double targetFat,
    int topN = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/recommend/nutrition');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'target_calories': targetCalories,
          'target_carbs': targetCarbs,
          'target_protein': targetProtein,
          'target_fat': targetFat,
          'top_n': topN,
        }),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final recommendations = (json['recommendations'] as List)
            .map((item) => FoodRecommendation.fromJson(item))
            .toList();
        
        return recommendations;
      } else {
        throw Exception('추천 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 추천 오류: $e');
      rethrow;
    }
  }
  
  /// 협업 필터링 추천
  Future<List<FoodRecommendation>> getCollaborativeRecommendations({
    required String userId,
    int topN = 10,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/recommend/collaborative');
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user_id': userId,
          'top_n': topN,
        }),
      );
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final recommendations = (json['recommendations'] as List)
            .map((item) => FoodRecommendation.fromJson(item))
            .toList();
        
        return recommendations;
      } else {
        throw Exception('추천 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 추천 오류: $e');
      rethrow;
    }
  }
  
  /// 인기 음식 추천
  Future<List<FoodRecommendation>> getPopularFoods({int topN = 10}) async {
    try {
      final uri = Uri.parse('$baseUrl/recommend/popular?top_n=$topN');
      
      final response = await http.get(uri);
      
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final recommendations = (json['recommendations'] as List)
            .map((item) => FoodRecommendation.fromJson(item))
            .toList();
        
        return recommendations;
      } else {
        throw Exception('추천 실패: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ 추천 오류: $e');
      rethrow;
    }
  }
  
  /// 헬스 체크
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
```

### 3.3 사용 예시

```dart
final recommendationService = RecommendationService(
  baseUrl: 'http://192.168.1.100:5001'
);

// 영양 기반 추천
final nutritionRecs = await recommendationService.getNutritionRecommendations(
  targetCalories: 500,
  targetCarbs: 60,
  targetProtein: 30,
  targetFat: 15,
  topN: 5,
);

print('📊 영양 기반 추천:');
for (final rec in nutritionRecs) {
  print('  ${rec.name} (적합도: ${(rec.score * 100).toStringAsFixed(1)}%)');
}

// 협업 필터링 추천
final userRecs = await recommendationService.getCollaborativeRecommendations(
  userId: 'user123',
  topN: 5,
);

print('👥 사용자 맞춤 추천:');
for (final rec in userRecs) {
  print('  ${rec.name}');
}

// 인기 음식 추천
final popularFoods = await recommendationService.getPopularFoods(topN: 5);

print('🔥 인기 음식:');
for (final food in popularFoods) {
  print('  ${food.name}');
}
```

---

## 4. Complete Integration Example

### 4.1 통합 서비스 클래스

**lib/services/ml_service.dart**:
```dart
import 'food_detection_service.dart';
import 'ocr_service.dart';
import 'recommendation_service.dart';

class MLService {
  final FoodDetectionService foodDetector = FoodDetectionService();
  final OCRService ocrService;
  final RecommendationService recommendationService;
  
  MLService({
    String ocrBaseUrl = 'http://localhost:5000',
    String recommendationBaseUrl = 'http://localhost:5001',
  })  : ocrService = OCRService(baseUrl: ocrBaseUrl),
        recommendationService = RecommendationService(baseUrl: recommendationBaseUrl);
  
  /// 모든 ML 서비스 초기화
  Future<void> initialize() async {
    await foodDetector.loadModel();
    
    final ocrHealthy = await ocrService.checkHealth();
    final recHealthy = await recommendationService.checkHealth();
    
    print('✅ YOLO: 로드됨');
    print('${ocrHealthy ? "✅" : "❌"} EasyOCR: ${ocrHealthy ? "연결됨" : "연결 실패"}');
    print('${recHealthy ? "✅" : "❌"} 추천 시스템: ${recHealthy ? "연결됨" : "연결 실패"}');
  }
  
  /// 리소스 정리
  void dispose() {
    foodDetector.dispose();
  }
}
```

### 4.2 완전한 사용 예시

**lib/screens/food_analysis_screen.dart**:
```dart
import 'package:flutter/material.dart';
import '../services/ml_service.dart';

class FoodAnalysisScreen extends StatefulWidget {
  @override
  _FoodAnalysisScreenState createState() => _FoodAnalysisScreenState();
}

class _FoodAnalysisScreenState extends State<FoodAnalysisScreen> {
  final MLService _mlService = MLService(
    ocrBaseUrl: 'http://192.168.1.100:5000',
    recommendationBaseUrl: 'http://192.168.1.100:5001',
  );
  
  @override
  void initState() {
    super.initState();
    _initializeServices();
  }
  
  Future<void> _initializeServices() async {
    try {
      await _mlService.initialize();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ML 서비스 초기화 완료!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('초기화 실패: $e')),
      );
    }
  }
  
  Future<void> _analyzeFoodImage(String imagePath) async {
    // 1. YOLO로 음식 인식
    final detections = await _mlService.foodDetector.detectFood(imagePath);
    
    print('인식된 음식: ${detections.map((d) => d.className).join(", ")}');
    
    // 2. 영양 기반 추천
    if (detections.isNotEmpty) {
      final recommendations = await _mlService.recommendationService
          .getNutritionRecommendations(
        targetCalories: 500,
        targetCarbs: 60,
        targetProtein: 30,
        targetFat: 15,
      );
      
      print('추천 음식: ${recommendations.map((r) => r.name).join(", ")}');
    }
  }
  
  Future<void> _scanNutritionLabel(String imagePath) async {
    // EasyOCR로 영양성분표 스캔
    final nutrition = await _mlService.ocrService.extractNutrition(imagePath);
    
    print('스캔 결과:');
    print('  칼로리: ${nutrition.calories} kcal');
    print('  탄수화물: ${nutrition.carbs}g');
    print('  단백질: ${nutrition.protein}g');
    print('  지방: ${nutrition.fat}g');
  }
  
  @override
  void dispose() {
    _mlService.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('음식 분석')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _analyzeFoodImage('/path/to/food.jpg'),
              child: Text('음식 사진 분석'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _scanNutritionLabel('/path/to/label.jpg'),
              child: Text('영양성분표 스캔'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. 배포 및 프로덕션

### 5.1 REST API 서버 배포 (Gunicorn)

```bash
# 프로덕션 환경에서 실행
cd ml_training/api_servers

# EasyOCR 서버 (4개 워커)
gunicorn -w 4 -b 0.0.0.0:5000 easyocr_server:app

# 추천 서버 (4개 워커)
gunicorn -w 4 -b 0.0.0.0:5001 recommendation_server:app
```

### 5.2 환경 설정 (Flutter)

**lib/config/api_config.dart**:
```dart
class ApiConfig {
  static const String ocrBaseUrl = String.fromEnvironment(
    'OCR_BASE_URL',
    defaultValue: 'http://localhost:5000',
  );
  
  static const String recommendationBaseUrl = String.fromEnvironment(
    'RECOMMENDATION_BASE_URL',
    defaultValue: 'http://localhost:5001',
  );
}
```

빌드 시 환경변수 설정:
```bash
flutter build apk --dart-define=OCR_BASE_URL=https://api.yourserver.com/ocr \
                  --dart-define=RECOMMENDATION_BASE_URL=https://api.yourserver.com/recommend
```

### 5.3 Docker Compose (선택사항)

**docker-compose.yml**:
```yaml
version: '3.8'

services:
  easyocr:
    build: ./ml_training/api_servers
    command: gunicorn -w 4 -b 0.0.0.0:5000 easyocr_server:app
    ports:
      - "5000:5000"
    environment:
      - PYTHONUNBUFFERED=1
    volumes:
      - ./ml_training:/app
    
  recommendation:
    build: ./ml_training/api_servers
    command: gunicorn -w 4 -b 0.0.0.0:5001 recommendation_server:app
    ports:
      - "5001:5001"
    environment:
      - PYTHONUNBUFFERED=1
    volumes:
      - ./ml_training:/app
```

실행:
```bash
docker-compose up -d
```

---

## 6. 문제 해결

### 6.1 TFLite 모델 로드 실패

**문제:** `Failed to load model from asset`

**해결:**
```bash
# pubspec.yaml에 assets 경로 확인
flutter clean
flutter pub get
flutter run
```

### 6.2 REST API 연결 실패

**문제:** `Connection refused`

**해결:**
```bash
# 1. 서버 상태 확인
curl http://localhost:5000/health
curl http://localhost:5001/health

# 2. 방화벽 확인
# 3. Android: localhost 대신 10.0.2.2 사용
# 4. iOS: localhost 사용 가능
```

### 6.3 메모리 부족

**문제:** `Out of memory`

**해결:**
- 이미지 크기를 640x640보다 작게 리사이즈
- 배치 추론 대신 단일 이미지 추론
- 모델 경량화 (quantization)

---

## 7. 추가 리소스

- **YOLO v8 문서**: https://docs.ultralytics.com
- **TFLite Flutter**: https://pub.dev/packages/tflite_flutter
- **EasyOCR**: https://github.com/JaidedAI/EasyOCR
- **Flask 문서**: https://flask.palletsprojects.com

---

**문의 및 지원:**
- 이슈 제기: GitHub Issues
- 가이드 업데이트: Pull Requests 환영

**버전:**
- YOLO v8: Ultralytics 8.0+
- EasyOCR: 1.7+
- Flutter: 3.0+
- TFLite: 2.12+
