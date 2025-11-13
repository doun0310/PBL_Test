class FoodRank {
  final String name;
  final int count;

  FoodRank({
    required this.name,
    required this.count,
  });

  factory FoodRank.fromJson(Map<String, dynamic> json) {
    return FoodRank(
      name: json['name'] as String,
      count: json['count'] as int,
    );
  }
}

class MealAnalytics {
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final Map<String, double> dailyCalories;
  final List<FoodRank> topFoods;

  MealAnalytics({
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
    required this.dailyCalories,
    required this.topFoods,
  });

  factory MealAnalytics.fromJson(Map<String, dynamic> json) {
    return MealAnalytics(
      totalCalories: (json['totalCalories'] as num).toDouble(),
      totalProtein: (json['totalProtein'] as num).toDouble(),
      totalCarbs: (json['totalCarbs'] as num).toDouble(),
      totalFat: (json['totalFat'] as num).toDouble(),
      dailyCalories: Map<String, double>.from(
        (json['dailyCalories'] as Map).map(
          (key, value) => MapEntry(key as String, (value as num).toDouble()),
        ),
      ),
      topFoods: (json['topFoods'] as List)
          .map((food) => FoodRank.fromJson(food))
          .toList(),
    );
  }
}
