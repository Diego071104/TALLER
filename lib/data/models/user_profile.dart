enum Sex { male, female, other }

enum ActivityLevel {
  sedentary, // <30 min walking/week
  moderate, // light exercise 3x/week
  active, // structured training 4-5x/week
  athlete, // competitive training
}

extension ActivityLevelLabel on ActivityLevel {
  String get label {
    switch (this) {
      case ActivityLevel.sedentary:
        return 'Sedentario';
      case ActivityLevel.moderate:
        return 'Moderado';
      case ActivityLevel.active:
        return 'Activo';
      case ActivityLevel.athlete:
        return 'Atleta';
    }
  }

  /// Resting HR baseline used in Karvonen formula. Defaults that match
  /// typical adult population by activity tier.
  int get defaultRestingHr {
    switch (this) {
      case ActivityLevel.sedentary:
        return 75;
      case ActivityLevel.moderate:
        return 68;
      case ActivityLevel.active:
        return 60;
      case ActivityLevel.athlete:
        return 50;
    }
  }
}

extension SexLabel on Sex {
  String get label {
    switch (this) {
      case Sex.male:
        return 'Masculino';
      case Sex.female:
        return 'Femenino';
      case Sex.other:
        return 'Otro';
    }
  }
}

class UserProfile {
  final int ageYears;
  final double weightKg;
  final double heightCm;
  final Sex sex;
  final ActivityLevel activity;

  const UserProfile({
    required this.ageYears,
    required this.weightKg,
    required this.heightCm,
    required this.sex,
    required this.activity,
  });

  /// Body Mass Index, kg / m^2.
  double get bmi {
    final m = heightCm / 100.0;
    return weightKg / (m * m);
  }

  /// Theoretical maximum HR via Tanaka formula (208 - 0.7*age),
  /// more accurate than the classic 220-age across the adult range.
  int get maxHr => (208 - 0.7 * ageYears).round();

  int get restingHr => activity.defaultRestingHr;

  UserProfile copyWith({
    int? ageYears,
    double? weightKg,
    double? heightCm,
    Sex? sex,
    ActivityLevel? activity,
  }) {
    return UserProfile(
      ageYears: ageYears ?? this.ageYears,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      sex: sex ?? this.sex,
      activity: activity ?? this.activity,
    );
  }
}
