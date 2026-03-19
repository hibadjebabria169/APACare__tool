class PatientState {

  String firstName;
  String lastName;
  int ageYears;
  String email;
  String phoneNumber;
  String diagnosis;
  String stage;
  double heightCm;
  double weightKg;
  int chemoCycle;

  int heartRate;
  int systolicBp;
  int diastolicBp;
  double bloodSugar;
  double whiteCellCount;
  int ecog;

  double fatigue;
  double pain;
  double mood;
  int stepsToday;

  CamiTestResults camiT0;
  CamiTestResults camiT1;
  CamiTestResults camiT2;
  CamiTestResults camiT3;

  List<PatientDocument> documents = [];

  List<ActivitySession> activityHistory = [];

  List<DailySymptomEntry> dailySymptomsHistory = [];

  PatientPreferences preferences = PatientPreferences();

  PatientState({

    this.firstName = 'Marie',
    this.lastName = 'Dupont',
    this.ageYears = 54,
    this.email = 'marie.dupont@gmail.com',
    this.phoneNumber = '+33 6 12 34 56 78',
    this.diagnosis = 'Breast cancer',
    this.stage = 'Stage II',
    this.heightCm = 162,
    this.weightKg = 71,
    this.chemoCycle = 3,

    this.heartRate = 76,
    this.systolicBp = 138,
    this.diastolicBp = 85,
    this.bloodSugar = 102.0,
    this.whiteCellCount = 4.2,

    this.ecog = 1,

    this.fatigue = 0.45,
    this.pain = 0.25,
    this.mood = 0.55,
    this.stepsToday = 3200,
    CamiTestResults? camiT0,
    CamiTestResults? camiT1,
    CamiTestResults? camiT2,
    CamiTestResults? camiT3,
  })  : camiT0 = camiT0 ?? CamiTestResults.realisticT0(),
        camiT1 = camiT1 ?? CamiTestResults.realisticT1(),
        camiT2 = camiT2 ?? CamiTestResults.realisticT2(),
        camiT3 = camiT3 ?? CamiTestResults.empty() {

    activityHistory = [];

    dailySymptomsHistory = [
      DailySymptomEntry(
        date: DateTime.now().subtract(const Duration(days: 14)),
        fatigue: 0.3,
        pain: 0.2,
        mood: 0.65,
        steps: 4500,
        notes: 'Bonne journée, avant la chimio',
      ),
      DailySymptomEntry(
        date: DateTime.now().subtract(const Duration(days: 12)),
        fatigue: 0.7,
        pain: 0.4,
        mood: 0.35,
        steps: 1200,
        notes: 'Lendemain de chimio, très fatiguée',
      ),
      DailySymptomEntry(
        date: DateTime.now().subtract(const Duration(days: 10)),
        fatigue: 0.55,
        pain: 0.3,
        mood: 0.45,
        steps: 2100,
        notes: 'Récupération progressive',
      ),
      DailySymptomEntry(
        date: DateTime.now().subtract(const Duration(days: 7)),
        fatigue: 0.4,
        pain: 0.2,
        mood: 0.6,
        steps: 3800,
        notes: 'Mieux, yoga ce matin',
      ),
      DailySymptomEntry(
        date: DateTime.now().subtract(const Duration(days: 3)),
        fatigue: 0.35,
        pain: 0.15,
        mood: 0.7,
        steps: 4200,
        notes: 'En forme, aquagym était agréable',
      ),
      DailySymptomEntry(
        date: DateTime.now().subtract(const Duration(days: 1)),
        fatigue: 0.45,
        pain: 0.25,
        mood: 0.55,
        steps: 3200,
        notes: 'Préparation prochaine chimio',
      ),
    ];
  }

  String get fullName => '$firstName $lastName';
  double get bmi => weightKg / ((heightCm / 100) * (heightCm / 100));

  String get fatigueLevel {
    if (fatigue < 0.3) return 'none_mild';
    if (fatigue < 0.6) return 'moderate';
    return 'severe';
  }

  int get ecogStatus => ecog;

  List<RecommendationItem> generateRecommendations() {
    final List<RecommendationItem> recos = [];

    if (diagnosis.toLowerCase().contains('breast') && ecogStatus <= 1) {
      if (fatigueLevel == 'moderate') {

        recos.add(RecommendationItem(
          text: 'Séance de yoga adapté 30 min - Exercices doux recommandés pour votre niveau de fatigue modéré',
          center: ActivityCenter.toursCenters[1],
          snomed: const LocalSnomedCoding(code: '229294001', term: 'Yoga (regime/therapy)'),
        ));
        recos.add(RecommendationItem(
          text: 'Étirements légers 15 min - Mobilité articulaire et relaxation',
          center: ActivityCenter.toursCenters[3],
          snomed: const LocalSnomedCoding(code: '229070002', term: 'Stretching exercises'),
        ));
      } else if (fatigueLevel == 'none_mild') {

        recos.add(RecommendationItem(
          text: 'Marche modérée 30 min - Activité cardiovasculaire adaptée à votre condition',
          center: ActivityCenter.toursCenters[0],
          snomed: const LocalSnomedCoding(code: '129006008', term: 'Walking (observable entity)'),
        ));
      }
    }

    if (systolicBp >= 130 && systolicBp < 160) {

      recos.add(RecommendationItem(
        text: 'Marche douce 20 min au bord de la Loire - Bénéfique pour votre tension artérielle',
        center: ActivityCenter.toursCenters[4],
        snomed: const LocalSnomedCoding(code: '129006008', term: 'Walking (observable entity)'),
      ));
    }

    if (bmi >= 25 && bmi < 30) {

      recos.add(RecommendationItem(
        text: 'Aquagym douce 30 min - Activité portée idéale, faible impact articulaire',
        center: ActivityCenter.toursCenters[2],
        snomed: const LocalSnomedCoding(code: '20461001', term: 'Swimming (observable entity)'),
      ));
    }

    if (chemoCycle > 0 && whiteCellCount < 5.0) {

      recos.add(RecommendationItem(
        text: 'Marche en plein air 15-20 min - Préférable pendant la chimiothérapie pour éviter les espaces confinés',
        center: ActivityCenter.toursCenters[0],
        snomed: const LocalSnomedCoding(code: '129006008', term: 'Walking (observable entity)'),
      ));
    }

    if (mood < 0.6) {
      recos.add(RecommendationItem(
        text: 'Séance de relaxation guidée 15 min - Soutien du bien-être émotionnel',
        center: ActivityCenter.toursCenters[5],
        snomed: const LocalSnomedCoding(code: '228557008', term: 'Cognitive and behavioral therapy'),
      ));
    }

    if (stepsToday < 4000) {
      recos.add(RecommendationItem(
        text: 'Objectif +1000 pas aujourd\'hui - Fractionner en courtes périodes de 10 minutes',
        center: ActivityCenter.toursCenters[4],
        snomed: const LocalSnomedCoding(code: '129006008', term: 'Walking (observable entity)'),
      ));
    }

    final latestCami = _getLatestCamiResults();
    if (latestCami != null && latestCami.dominantHandGripKg < 22) {
      recos.add(RecommendationItem(
        text: 'Renforcement préhension avec balle souple - Améliorer la force de grip',
        center: ActivityCenter.toursCenters[1],
        snomed: const LocalSnomedCoding(code: '229065009', term: 'Exercise therapy'),
      ));
    }

    return recos;
  }

  CamiTestResults? _getLatestCamiResults() {
    if (camiT3.hasData) return camiT3;
    if (camiT2.hasData) return camiT2;
    if (camiT1.hasData) return camiT1;
    if (camiT0.hasData) return camiT0;
    return null;
  }

  void saveDailySymptoms({String notes = ''}) {
    dailySymptomsHistory.add(DailySymptomEntry(
      date: DateTime.now(),
      fatigue: fatigue,
      pain: pain,
      mood: mood,
      steps: stepsToday,
      notes: notes,
    ));
  }

  void addDocument(PatientDocument doc) {
    documents.add(doc);
  }

  void removeDocument(String id) {
    documents.removeWhere((d) => d.id == id);
  }

  void addActivityFromRecommendation(RecommendationItem recommendation) {
    activityHistory.add(ActivitySession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: recommendation.text.length > 50
          ? '${recommendation.text.substring(0, 50)}...'
          : recommendation.text,
      type: _getActivityTypeFromText(recommendation.text),
      date: DateTime.now(),
      durationMinutes: _getDurationFromText(recommendation.text),
      center: recommendation.center,
      status: ActivityStatus.started,
    ));
  }

  int _getDurationFromText(String text) {
    final regex = RegExp(r'(\d+)\s*min');
    final match = regex.firstMatch(text);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 20;
    }
    return 20;
  }

  ActivityType _getActivityTypeFromText(String text) {
    final lowerText = text.toLowerCase();
    if (lowerText.contains('marche') || lowerText.contains('pas')) return ActivityType.walking;
    if (lowerText.contains('yoga')) return ActivityType.yoga;
    if (lowerText.contains('respiration') || lowerText.contains('relaxation')) return ActivityType.breathing;
    if (lowerText.contains('vélo') || lowerText.contains('cycling')) return ActivityType.cycling;
    if (lowerText.contains('aqua') || lowerText.contains('piscine') || lowerText.contains('nage')) return ActivityType.swimming;
    if (lowerText.contains('étirement') || lowerText.contains('stretch')) return ActivityType.stretching;
    if (lowerText.contains('renforcement') || lowerText.contains('force')) return ActivityType.strength;
    return ActivityType.other;
  }
}

class LocalSnomedCoding {
  final String code;
  final String term;

  const LocalSnomedCoding({required this.code, required this.term});

  String get uri => 'http://snomed.info/id/$code';
}

class RecommendationItem {
  final String text;
  final ActivityCenter center;
  final LocalSnomedCoding? snomed;
  bool isStarted;

  RecommendationItem({
    required this.text,
    required this.center,
    this.snomed,
    this.isStarted = false,
  });
}

class ActivityCenter {
  final String name;
  final String address;
  final String openingHours;
  final String phoneNumber;

  ActivityCenter({
    required this.name,
    required this.address,
    required this.openingHours,
    required this.phoneNumber,
  });

  static List<ActivityCenter> toursCenters = [
    ActivityCenter(
      name: 'Jardin Botanique de Tours',
      address: '35 Boulevard Tonnellé, 37000 Tours',
      openingHours: 'Lun-Dim: 7h45-20h00 (été), 7h45-17h30 (hiver)',
      phoneNumber: '+33 2 47 21 62 67',
    ),
    ActivityCenter(
      name: 'CAMI Sport & Cancer - CHU Tours',
      address: 'Hôpital Bretonneau, 2 Bd Tonnellé, 37000 Tours',
      openingHours: 'Mar-Jeu: 10h00-12h00, 14h00-17h00',
      phoneNumber: '+33 2 47 47 47 47',
    ),
    ActivityCenter(
      name: 'Centre Aquatique du Lac',
      address: '111 Avenue du Lac, 37200 Tours',
      openingHours: 'Lun-Ven: 9h00-21h00, Sam-Dim: 9h00-19h00',
      phoneNumber: '+33 2 47 80 78 10',
    ),
    ActivityCenter(
      name: 'Espace Bien-être Touraine',
      address: '18 Rue Nationale, 37000 Tours',
      openingHours: 'Lun-Sam: 9h00-19h00',
      phoneNumber: '+33 2 47 05 68 42',
    ),
    ActivityCenter(
      name: 'Promenade des Bords de Loire',
      address: 'Quai du Pont Neuf, 37000 Tours',
      openingHours: 'Accès libre 24h/24',
      phoneNumber: 'N/A - Espace public',
    ),
    ActivityCenter(
      name: 'Maison Sport Santé Tours',
      address: '60 Rue du Plat d\'Étain, 37000 Tours',
      openingHours: 'Lun-Ven: 8h30-18h30',
      phoneNumber: '+33 2 47 31 45 67',
    ),
  ];
}

class CamiTestResults {
  DateTime? testDate;
  double weightKg;
  double img;
  double imm;
  double chairTestSeconds;
  double dominantArmWeightTestSeconds;
  double otherArmWeightTestSeconds;
  double dominantHandGripKg;
  double otherHandGripKg;
  double plankTestSeconds;
  double dominantLegReachCm;
  double otherLegReachCm;
  double dominantArmGoniometer;
  double otherArmGoniometer;
  double dominantFootBalanceSeconds;
  double otherFootBalanceSeconds;
  int stepTestCount;
  int chairStandTest30Sec;
  int dominantArmCurlTest;
  int otherArmCurlTest;
  int restingHeartRate;
  int restingSaturation;
  int exerciseHeartRate;
  int exerciseSaturation;
  int heartRateAfter2Min;
  int exerciseIntensity;

  CamiTestResults({
    this.testDate,
    this.weightKg = 0,
    this.img = 0,
    this.imm = 0,
    this.chairTestSeconds = 0,
    this.dominantArmWeightTestSeconds = 0,
    this.otherArmWeightTestSeconds = 0,
    this.dominantHandGripKg = 0,
    this.otherHandGripKg = 0,
    this.plankTestSeconds = 0,
    this.dominantLegReachCm = 0,
    this.otherLegReachCm = 0,
    this.dominantArmGoniometer = 0,
    this.otherArmGoniometer = 0,
    this.dominantFootBalanceSeconds = 0,
    this.otherFootBalanceSeconds = 0,
    this.stepTestCount = 0,
    this.chairStandTest30Sec = 0,
    this.dominantArmCurlTest = 0,
    this.otherArmCurlTest = 0,
    this.restingHeartRate = 0,
    this.restingSaturation = 0,
    this.exerciseHeartRate = 0,
    this.exerciseSaturation = 0,
    this.heartRateAfter2Min = 0,
    this.exerciseIntensity = 0,
  });

  bool get hasData => testDate != null || weightKg > 0 || chairTestSeconds > 0;

  factory CamiTestResults.empty() => CamiTestResults();

  factory CamiTestResults.realisticT0() => CamiTestResults(
        testDate: DateTime.now().subtract(const Duration(days: 90)),
        weightKg: 73,
        img: 34.0,
        imm: 27.5,
        chairTestSeconds: 16.5,
        dominantArmWeightTestSeconds: 35.0,
        otherArmWeightTestSeconds: 32.0,
        dominantHandGripKg: 18.0,
        otherHandGripKg: 15.0,
        plankTestSeconds: 18.0,
        dominantLegReachCm: 2.0,
        otherLegReachCm: 1.5,
        dominantArmGoniometer: 140.0,
        otherArmGoniometer: 135.0,
        dominantFootBalanceSeconds: 8.0,
        otherFootBalanceSeconds: 6.0,
        stepTestCount: 55,
        chairStandTest30Sec: 8,
        dominantArmCurlTest: 10,
        otherArmCurlTest: 8,
        restingHeartRate: 82,
        restingSaturation: 95,
        exerciseHeartRate: 125,
        exerciseSaturation: 92,
        heartRateAfter2Min: 100,
        exerciseIntensity: 7,
      );

  factory CamiTestResults.realisticT1() => CamiTestResults(
        testDate: DateTime.now().subtract(const Duration(days: 60)),
        weightKg: 72,
        img: 33.0,
        imm: 28.0,
        chairTestSeconds: 14.5,
        dominantArmWeightTestSeconds: 38.0,
        otherArmWeightTestSeconds: 35.0,
        dominantHandGripKg: 19.5,
        otherHandGripKg: 16.5,
        plankTestSeconds: 22.0,
        dominantLegReachCm: 3.0,
        otherLegReachCm: 2.5,
        dominantArmGoniometer: 145.0,
        otherArmGoniometer: 140.0,
        dominantFootBalanceSeconds: 10.0,
        otherFootBalanceSeconds: 8.0,
        stepTestCount: 62,
        chairStandTest30Sec: 9,
        dominantArmCurlTest: 11,
        otherArmCurlTest: 9,
        restingHeartRate: 78,
        restingSaturation: 96,
        exerciseHeartRate: 118,
        exerciseSaturation: 94,
        heartRateAfter2Min: 92,
        exerciseIntensity: 6,
      );

  factory CamiTestResults.realisticT2() => CamiTestResults(
        testDate: DateTime.now().subtract(const Duration(days: 30)),
        weightKg: 71,
        img: 32.5,
        imm: 28.8,
        chairTestSeconds: 13.0,
        dominantArmWeightTestSeconds: 42.0,
        otherArmWeightTestSeconds: 38.0,
        dominantHandGripKg: 21.0,
        otherHandGripKg: 18.0,
        plankTestSeconds: 26.0,
        dominantLegReachCm: 4.0,
        otherLegReachCm: 3.5,
        dominantArmGoniometer: 148.0,
        otherArmGoniometer: 143.0,
        dominantFootBalanceSeconds: 12.0,
        otherFootBalanceSeconds: 10.0,
        stepTestCount: 70,
        chairStandTest30Sec: 10,
        dominantArmCurlTest: 12,
        otherArmCurlTest: 10,
        restingHeartRate: 76,
        restingSaturation: 96,
        exerciseHeartRate: 112,
        exerciseSaturation: 95,
        heartRateAfter2Min: 88,
        exerciseIntensity: 5,
      );
}

class DailySymptomEntry {
  final DateTime date;
  final double fatigue;
  final double pain;
  final double mood;
  final int steps;
  final String notes;

  DailySymptomEntry({
    required this.date,
    required this.fatigue,
    required this.pain,
    required this.mood,
    required this.steps,
    this.notes = '',
  });
}

class PatientDocument {
  final String id;
  final String name;
  final String type;
  final DateTime uploadDate;
  final String? path;
  final int sizeBytes;

  PatientDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadDate,
    this.path,
    this.sizeBytes = 0,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

enum ActivityType {
  walking,
  yoga,
  strength,
  breathing,
  cycling,
  swimming,
  stretching,
  other,
}

enum ActivityStatus {
  started,
  completed,
}

class ActivitySession {
  final String id;
  final String name;
  final ActivityType type;
  final DateTime date;
  final int durationMinutes;
  final ActivityCenter center;
  final ActivityStatus status;

  ActivitySession({
    required this.id,
    required this.name,
    required this.type,
    required this.date,
    this.durationMinutes = 0,
    required this.center,
    this.status = ActivityStatus.started,
  });

  String get typeIcon {
    switch (type) {
      case ActivityType.walking:
        return '🚶';
      case ActivityType.yoga:
        return '🧘';
      case ActivityType.strength:
        return '💪';
      case ActivityType.breathing:
        return '🌬️';
      case ActivityType.cycling:
        return '🚴';
      case ActivityType.swimming:
        return '🏊';
      case ActivityType.stretching:
        return '🤸';
      case ActivityType.other:
        return '⭐';
    }
  }

  String get typeName {
    switch (type) {
      case ActivityType.walking:
        return 'Marche';
      case ActivityType.yoga:
        return 'Yoga';
      case ActivityType.strength:
        return 'Renforcement';
      case ActivityType.breathing:
        return 'Respiration';
      case ActivityType.cycling:
        return 'Vélo';
      case ActivityType.swimming:
        return 'Natation';
      case ActivityType.stretching:
        return 'Étirements';
      case ActivityType.other:
        return 'Autre';
    }
  }
}

class PatientPreferences {

  Set<ActivityType> preferredActivities;

  EnvironmentPreference environmentPref;

  double maxDistanceKm;

  IntensityPreference intensityPref;

  PatientPreferences({
    Set<ActivityType>? preferredActivities,
    this.environmentPref = EnvironmentPreference.noPreference,
    this.maxDistanceKm = 10.0,
    this.intensityPref = IntensityPreference.light,
  }) : preferredActivities = preferredActivities ?? {
         ActivityType.walking,
         ActivityType.yoga,
         ActivityType.breathing,
       };
}

enum EnvironmentPreference {
  indoor,
  outdoor,
  noPreference,
}

enum IntensityPreference {
  veryLight,
  light,
  moderate,
  high,
}
