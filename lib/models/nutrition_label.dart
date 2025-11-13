class NutritionLabel {
  final String? productName;
  final double calories;
  final double carbohydrate;
  final double sugars;
  final double protein;
  final double fat;
  final double saturatedFat;
  final double transFat;
  final double cholesterol;
  final double sodium;

  NutritionLabel({
    this.productName,
    required this.calories,
    required this.carbohydrate,
    required this.sugars,
    required this.protein,
    required this.fat,
    required this.saturatedFat,
    required this.transFat,
    required this.cholesterol,
    required this.sodium,
  });

  factory NutritionLabel.fromJson(Map<String, dynamic> json) {
    return NutritionLabel(
      productName: json['productName'] as String?,
      calories: (json['calories'] as num?)?.toDouble() ?? 0.0,
      carbohydrate: (json['carbohydrate'] as num?)?.toDouble() ?? 0.0,
      sugars: (json['sugars'] as num?)?.toDouble() ?? 0.0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0.0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0.0,
      saturatedFat: (json['saturatedFat'] as num?)?.toDouble() ?? 0.0,
      transFat: (json['transFat'] as num?)?.toDouble() ?? 0.0,
      cholesterol: (json['cholesterol'] as num?)?.toDouble() ?? 0.0,
      sodium: (json['sodium'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productName': productName,
      'calories': calories,
      'carbohydrate': carbohydrate,
      'sugars': sugars,
      'protein': protein,
      'fat': fat,
      'saturatedFat': saturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'sodium': sodium,
    };
  }
}
