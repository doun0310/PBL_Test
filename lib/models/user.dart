import 'nutrition_goals.dart';

class User {
  final int id;
  final String email;
  final String name;
  final List<String> allergies;
  final List<String> preferences;
  final NutritionGoals? nutritionGoals;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.allergies,
    required this.preferences,
    this.nutritionGoals,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      allergies: List<String>.from(json['allergies'] as List),
      preferences: List<String>.from(json['preferences'] as List),
      nutritionGoals: json['nutritionGoals'] != null
          ? NutritionGoals.fromJson(json['nutritionGoals'])
          : NutritionGoals.defaultGoals(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'allergies': allergies,
      'preferences': preferences,
      if (nutritionGoals != null) 'nutritionGoals': nutritionGoals!.toJson(),
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    List<String>? allergies,
    List<String>? preferences,
    NutritionGoals? nutritionGoals,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      allergies: allergies ?? this.allergies,
      preferences: preferences ?? this.preferences,
      nutritionGoals: nutritionGoals ?? this.nutritionGoals,
    );
  }
}
