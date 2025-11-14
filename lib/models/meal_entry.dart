import 'food_item.dart';

enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return '아침';
      case MealType.lunch:
        return '점심';
      case MealType.dinner:
        return '저녁';
      case MealType.snack:
        return '간식';
    }
  }
}

class MealEntry {
  final String id;
  final DateTime timestamp;
  final MealType mealType;
  final List<FoodItemEntry> foodItems;
  final String? photoPath;
  final String? notes;

  MealEntry({
    required this.id,
    required this.timestamp,
    required this.mealType,
    required this.foodItems,
    this.photoPath,
    this.notes,
  });

  double get totalCalories =>
      foodItems.fold(0, (sum, item) => sum + item.totalCalories);

  double get totalProtein =>
      foodItems.fold(0, (sum, item) => sum + item.totalProtein);

  double get totalCarbs =>
      foodItems.fold(0, (sum, item) => sum + item.totalCarbs);

  double get totalFat =>
      foodItems.fold(0, (sum, item) => sum + item.totalFat);

  factory MealEntry.fromJson(Map<String, dynamic> json) {
    return MealEntry(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      mealType: MealType.values.firstWhere(
        (e) => e.name == json['mealType'],
        orElse: () => MealType.snack,
      ),
      foodItems: (json['foodItems'] as List)
          .map((item) => FoodItemEntry.fromJson(item))
          .toList(),
      photoPath: json['photoPath'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': timestamp.toIso8601String(),
      'mealType': mealType.name,
      'foodItems': foodItems.map((item) => item.toJson()).toList(),
      'photoPath': photoPath,
      'notes': notes,
    };
  }
}

class FoodItemEntry {
  final FoodItem foodItem;
  final double quantity; // 수량 (배수)
  final double servingSize; // 실제 섭취량

  FoodItemEntry({
    required this.foodItem,
    this.quantity = 1.0,
    double? servingSize,
  }) : servingSize = servingSize ?? foodItem.servingSize;

  double get totalCalories => foodItem.calories * (servingSize / foodItem.servingSize);
  double get totalProtein => foodItem.protein * (servingSize / foodItem.servingSize);
  double get totalCarbs => foodItem.carbs * (servingSize / foodItem.servingSize);
  double get totalFat => foodItem.fat * (servingSize / foodItem.servingSize);

  factory FoodItemEntry.fromJson(Map<String, dynamic> json) {
    return FoodItemEntry(
      foodItem: FoodItem.fromJson(json['foodItem']),
      quantity: (json['quantity'] as num).toDouble(),
      servingSize: json['servingSize'] != null
          ? (json['servingSize'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodItem': foodItem.toJson(),
      'quantity': quantity,
      'servingSize': servingSize,
    };
  }

  FoodItemEntry copyWith({
    FoodItem? foodItem,
    double? quantity,
    double? servingSize,
  }) {
    return FoodItemEntry(
      foodItem: foodItem ?? this.foodItem,
      quantity: quantity ?? this.quantity,
      servingSize: servingSize ?? this.servingSize,
    );
  }
}
