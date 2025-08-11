class UserProfile {
  final int? id;
  final String name;
  final int age;
  final String gender; // 'male' or 'female'
  final double height; // in cm
  final double weight; // in kg
  final String activityLevel;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserProfile({
    this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Calculate BMR (Basal Metabolic Rate)
  double calculateBMR() {
    if (gender.toLowerCase() == 'male') {
      // Male BMR formula
      return 10 * weight + 6.25 * height - 5 * age + 5;
    } else {
      // Female BMR formula
      return 10 * weight + 6.25 * height - 5 * age - 161;
    }
  }

  // Calculate TDEE (Total Daily Energy Expenditure)
  double calculateTDEE() {
    double bmr = calculateBMR();
    double activityMultiplier = _getActivityMultiplier();
    return bmr * activityMultiplier;
  }

  double _getActivityMultiplier() {
    switch (activityLevel.toLowerCase()) {
      case 'sedentary':
        return 1.2; // Sedentary
      case 'light':
        return 1.375; // Light activity
      case 'moderate':
        return 1.55; // Moderate activity
      case 'active':
        return 1.725; // High activity
      case 'very_active':
        return 1.9; // Very high activity
      default:
        return 1.2;
    }
  }

  // Copy method for updating user information
  UserProfile copyWith({
    int? id,
    String? name,
    int? age,
    String? gender,
    double? height,
    double? weight,
    String? activityLevel,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      activityLevel: activityLevel ?? this.activityLevel,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  // Convert to Map (for database storage)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
      'activityLevel': activityLevel,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  // Create UserProfile from Map
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      name: map['name'],
      age: map['age'],
      gender: map['gender'],
      height: map['height'],
      weight: map['weight'],
      activityLevel: map['activityLevel'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updatedAt']),
    );
  }
}
