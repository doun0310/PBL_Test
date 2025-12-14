/// Food Recommendation Model
/// Represents a food recommendation from the collaborative filtering system
class FoodRecommendation {
  final String foodId;
  final String name;
  final double? score;
  final double? predictedRating;
  final double? avgRating;
  final FoodNutrition nutrition;

  FoodRecommendation({
    required this.foodId,
    required this.name,
    this.score,
    this.predictedRating,
    this.avgRating,
    required this.nutrition,
  });

  factory FoodRecommendation.fromJson(Map<String, dynamic> json) {
    return FoodRecommendation(
      foodId: json['food_id'] as String,
      name: json['name'] as String,
      score: json['score'] != null ? (json['score'] as num).toDouble() : null,
      predictedRating: json['predicted_rating'] != null
          ? (json['predicted_rating'] as num).toDouble()
          : null,
      avgRating: json['avg_rating'] != null
          ? (json['avg_rating'] as num).toDouble()
          : null,
      nutrition: FoodNutrition.fromJson(json['nutrition'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'food_id': foodId,
      'name': name,
      if (score != null) 'score': score,
      if (predictedRating != null) 'predicted_rating': predictedRating,
      if (avgRating != null) 'avg_rating': avgRating,
      'nutrition': nutrition.toJson(),
    };
  }
}

/// Food Nutrition Information
class FoodNutrition {
  final double calories;
  final double carbohydrates;
  final double protein;
  final double fat;

  FoodNutrition({
    required this.calories,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    return FoodNutrition(
      calories: (json['calories'] as num).toDouble(),
      carbohydrates: (json['carbohydrates'] as num).toDouble(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'carbohydrates': carbohydrates,
      'protein': protein,
      'fat': fat,
    };
  }
}

/// Nutrition Targets for recommendation
class NutritionTargets {
  final double calories;
  final double carbohydrates;
  final double protein;
  final double fat;

  NutritionTargets({
    required this.calories,
    required this.carbohydrates,
    required this.protein,
    required this.fat,
  });

  Map<String, dynamic> toJson() {
    return {
      'target_calories': calories,
      'target_carbs': carbohydrates,
      'target_protein': protein,
      'target_fat': fat,
    };
  }
}
