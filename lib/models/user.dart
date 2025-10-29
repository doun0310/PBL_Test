class User {
  final int id;
  final String email;
  final String name;
  final List<String> allergies;
  final List<String> preferences;

  User({
    required this.id,
    required this.email,
    required this.name,
    required this.allergies,
    required this.preferences,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      allergies: List<String>.from(json['allergies'] as List),
      preferences: List<String>.from(json['preferences'] as List),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'allergies': allergies,
      'preferences': preferences,
    };
  }

  User copyWith({
    int? id,
    String? email,
    String? name,
    List<String>? allergies,
    List<String>? preferences,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      allergies: allergies ?? this.allergies,
      preferences: preferences ?? this.preferences,
    );
  }
}
