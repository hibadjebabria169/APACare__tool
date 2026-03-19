import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/patient_state.dart';

class RecommendationService extends ChangeNotifier {
  final LLMRecommender _llmRecommender = LLMRecommender();
  final KGValidator _kgValidator = KGValidator();

  List<DynamicRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _lastError;

  Map<String, dynamic> _lastParameters = {};

  List<DynamicRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;

  Future<List<DynamicRecommendation>> generateRecommendations(PatientState patient) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {

      final parameters = _extractParameters(patient);

      final changedParams = _detectChangedParameters(parameters);

      final llmRecommendations = await _llmRecommender.generateRecommendations(
        patient: patient,
        changedParameters: changedParams,
        previousRecommendations: _recommendations,
      );

      final validatedRecommendations = await _kgValidator.validate(
        recommendations: llmRecommendations,
        patient: patient,
      );

      _recommendations = validatedRecommendations;
      _lastParameters = parameters;
      _isLoading = false;
      notifyListeners();

      return _recommendations;
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;
      notifyListeners();
      return _recommendations;
    }
  }

  Map<String, dynamic> _extractParameters(PatientState patient) {
    return {
      'fatigue': patient.fatigue,
      'pain': patient.pain,
      'mood': patient.mood,
      'ecog': patient.ecog,
      'heartRate': patient.heartRate,
      'systolicBp': patient.systolicBp,
      'diastolicBp': patient.diastolicBp,
      'bloodSugar': patient.bloodSugar,
      'whiteCellCount': patient.whiteCellCount,
      'chemoCycle': patient.chemoCycle,
      'stepsToday': patient.stepsToday,
      'bmi': patient.bmi,
      'diagnosis': patient.diagnosis,
      'stage': patient.stage,
      'preferredActivities': patient.preferences.preferredActivities.map((e) => e.name).toList(),
      'intensityPref': patient.preferences.intensityPref.name,
      'environmentPref': patient.preferences.environmentPref.name,
    };
  }

  List<ParameterChange> _detectChangedParameters(Map<String, dynamic> current) {
    final changes = <ParameterChange>[];

    for (final key in current.keys) {
      final currentValue = current[key];
      final lastValue = _lastParameters[key];

      if (lastValue == null) continue;

      final change = _calculateChange(key, lastValue, currentValue);
      if (change != null && change.isSignificant) {
        changes.add(change);
      }
    }

    return changes;
  }

  ParameterChange? _calculateChange(String key, dynamic oldValue, dynamic newValue) {
    if (oldValue == newValue) return null;

    if (oldValue is num && newValue is num) {
      final delta = (newValue - oldValue).abs();
      final percentChange = oldValue != 0 ? delta / oldValue.abs() : delta;

      final threshold = _getSignificanceThreshold(key);

      return ParameterChange(
        parameter: key,
        oldValue: oldValue,
        newValue: newValue,
        delta: delta.toDouble(),
        percentChange: percentChange.toDouble(),
        isSignificant: percentChange >= threshold,
        direction: newValue > oldValue ? ChangeDirection.increased : ChangeDirection.decreased,
      );
    }

    return ParameterChange(
      parameter: key,
      oldValue: oldValue,
      newValue: newValue,
      delta: 1,
      percentChange: 1,
      isSignificant: true,
      direction: ChangeDirection.changed,
    );
  }

  double _getSignificanceThreshold(String parameter) {

    const thresholds = {
      'fatigue': 0.1,
      'pain': 0.1,
      'mood': 0.15,
      'heartRate': 0.1,
      'systolicBp': 0.05,
      'diastolicBp': 0.05,
      'bloodSugar': 0.1,
      'whiteCellCount': 0.15,
      'stepsToday': 0.2,
      'bmi': 0.02,
      'ecog': 0.01,
    };
    return thresholds[parameter] ?? 0.1;
  }

  void clearRecommendations() {
    _recommendations = [];
    _lastParameters = {};
    notifyListeners();
  }
}

class LLMRecommender {

  Future<List<DynamicRecommendation>> generateRecommendations({
    required PatientState patient,
    required List<ParameterChange> changedParameters,
    required List<DynamicRecommendation> previousRecommendations,
  }) async {
    final recommendations = <DynamicRecommendation>[];

    final context = _buildPatientContext(patient);

    final activityUtilities = _calculateActivityUtilities(patient, changedParameters);

    for (final entry in activityUtilities.entries) {
      if (entry.value.score > 0.3) {
        final recommendation = await _generateActivityRecommendation(
          activityType: entry.key,
          utility: entry.value,
          patient: patient,
          context: context,
          changedParameters: changedParameters,
        );
        if (recommendation != null) {
          recommendations.add(recommendation);
        }
      }
    }

    recommendations.sort((a, b) => b.utilityScore.compareTo(a.utilityScore));

    if (changedParameters.isNotEmpty) {
      _adaptRecommendations(recommendations, changedParameters, previousRecommendations);
    }

    return recommendations.take(6).toList();
  }

  PatientContext _buildPatientContext(PatientState patient) {
    return PatientContext(
      fatigueLevel: _categorizeFatigue(patient.fatigue),
      painLevel: _categorizePain(patient.pain),
      moodState: _categorizeMood(patient.mood),
      fitnessLevel: _assessFitnessLevel(patient),
      riskFactors: _identifyRiskFactors(patient),
      currentCapacity: _assessCurrentCapacity(patient),
    );
  }

  String _categorizeFatigue(double fatigue) {
    if (fatigue < 0.3) return 'none_mild';
    if (fatigue < 0.6) return 'moderate';
    return 'severe';
  }

  String _categorizePain(double pain) {
    if (pain < 0.3) return 'none_mild';
    if (pain < 0.6) return 'moderate';
    return 'severe';
  }

  String _categorizeMood(double mood) {
    if (mood < 0.3) return 'low';
    if (mood < 0.6) return 'moderate';
    return 'good';
  }

  FitnessLevel _assessFitnessLevel(PatientState patient) {

    if (patient.ecog >= 3) return FitnessLevel.veryLow;
    if (patient.ecog == 2) return FitnessLevel.low;

    if (patient.stepsToday < 2000) return FitnessLevel.low;
    if (patient.stepsToday < 5000) return FitnessLevel.moderate;
    return FitnessLevel.good;
  }

  List<String> _identifyRiskFactors(PatientState patient) {
    final risks = <String>[];

    if (patient.systolicBp >= 140 || patient.diastolicBp >= 90) {
      risks.add('hypertension');
    }
    if (patient.heartRate > 100) {
      risks.add('elevated_hr');
    }

    if (patient.whiteCellCount < 4.0) {
      risks.add('low_wbc');
    }

    if (patient.bloodSugar > 126) {
      risks.add('elevated_glucose');
    }
    if (patient.bmi >= 30) {
      risks.add('obesity');
    } else if (patient.bmi >= 25) {
      risks.add('overweight');
    }

    return risks;
  }

  CurrentCapacity _assessCurrentCapacity(PatientState patient) {

    final fatigueWeight = 0.4;
    final painWeight = 0.3;
    final ecogWeight = 0.3;

    final normalizedEcog = patient.ecog / 4.0;
    final capacityScore = 1.0 - (
      patient.fatigue * fatigueWeight +
      patient.pain * painWeight +
      normalizedEcog * ecogWeight
    );

    if (capacityScore < 0.3) return CurrentCapacity.veryLimited;
    if (capacityScore < 0.5) return CurrentCapacity.limited;
    if (capacityScore < 0.7) return CurrentCapacity.moderate;
    return CurrentCapacity.good;
  }

  Map<ActivityType, ActivityUtility> _calculateActivityUtilities(
    PatientState patient,
    List<ParameterChange> changes,
  ) {
    final utilities = <ActivityType, ActivityUtility>{};

    for (final activityType in ActivityType.values) {
      utilities[activityType] = _calculateSingleUtility(activityType, patient, changes);
    }

    return utilities;
  }

  ActivityUtility _calculateSingleUtility(
    ActivityType type,
    PatientState patient,
    List<ParameterChange> changes,
  ) {
    double baseScore = 0.5;
    final reasons = <String>[];
    final adaptations = <String>[];

    if (patient.preferences.preferredActivities.contains(type)) {
      baseScore += 0.15;
      reasons.add('Matches your activity preferences');
    }

    switch (type) {
      case ActivityType.walking:
        baseScore = _calculateWalkingUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.yoga:
        baseScore = _calculateYogaUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.swimming:
        baseScore = _calculateSwimmingUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.breathing:
        baseScore = _calculateBreathingUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.stretching:
        baseScore = _calculateStretchingUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.cycling:
        baseScore = _calculateCyclingUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.strength:
        baseScore = _calculateStrengthUtility(patient, changes, reasons, adaptations);
        break;
      case ActivityType.other:
        baseScore = 0.3;
        break;
    }

    for (final change in changes) {
      _applyChangeAdaptation(type, change, reasons, adaptations);
    }

    return ActivityUtility(
      score: baseScore.clamp(0.0, 1.0),
      reasons: reasons,
      adaptations: adaptations,
    );
  }

  double _calculateWalkingUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.6;

    if (patient.ecog <= 1) {
      score += 0.2;
      reasons.add('Appropriate for your functional status (ECOG ${patient.ecog})');
    } else if (patient.ecog == 2) {
      score += 0.1;
      adaptations.add('Keep walks shorter and closer to home');
    } else {
      score -= 0.3;
      adaptations.add('Consider seated exercises instead');
    }

    if (patient.fatigue < 0.3) {
      score += 0.1;
    } else if (patient.fatigue > 0.6) {
      score -= 0.1;
      adaptations.add('Reduce walking duration due to fatigue');
    }

    if (patient.systolicBp >= 140) {
      adaptations.add('Keep pace gentle to manage blood pressure');
    } else {
      reasons.add('Blood pressure is within safe range for walking');
    }

    if (patient.preferences.environmentPref == EnvironmentPreference.outdoor) {
      score += 0.05;
      reasons.add('Matches your outdoor preference');
    }

    if (patient.whiteCellCount < 4.0) {
      adaptations.add('Prefer outdoor walks to avoid crowded indoor spaces');
    }

    return score;
  }

  double _calculateYogaUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.5;

    if (patient.fatigue > 0.4) {
      score += 0.2;
      reasons.add('Gentle yoga is beneficial for managing fatigue');
    }

    if (patient.mood < 0.5) {
      score += 0.15;
      reasons.add('Yoga can help improve mood and reduce stress');
    }

    if (patient.pain > 0.3 && patient.pain < 0.7) {
      score += 0.1;
      reasons.add('Gentle stretching may help with pain management');
      adaptations.add('Focus on restorative poses');
    } else if (patient.pain >= 0.7) {
      score -= 0.2;
      adaptations.add('Avoid poses that strain affected areas');
    }

    if (patient.ecog >= 2) {
      adaptations.add('Chair yoga recommended for your mobility level');
    }

    return score;
  }

  double _calculateSwimmingUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.4;

    if (patient.bmi >= 25) {
      score += 0.25;
      reasons.add('Low-impact exercise ideal for joint protection');
    }

    if (patient.whiteCellCount < 4.0) {
      score -= 0.3;
      adaptations.add('Avoid public pools during low white cell count');
    }

    if (patient.fatigue > 0.6) {
      score -= 0.15;
      adaptations.add('Pool walking instead of swimming laps');
    }

    if (patient.systolicBp >= 130) {
      score += 0.1;
      reasons.add('Swimming helps with blood pressure management');
    }

    return score;
  }

  double _calculateBreathingUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.5;

    if (patient.fatigue > 0.5 || patient.pain > 0.5) {
      score += 0.25;
      reasons.add('Breathing exercises help manage symptoms without physical strain');
    }

    if (patient.mood < 0.5) {
      score += 0.2;
      reasons.add('Deep breathing reduces anxiety and improves mood');
    }

    if (patient.ecog >= 2) {
      score += 0.2;
      reasons.add('Suitable for all mobility levels');
    }

    if (patient.heartRate > 90) {
      score += 0.1;
      reasons.add('Helps lower resting heart rate');
    }

    return score;
  }

  double _calculateStretchingUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.5;

    if (patient.fatigue > 0.3 && patient.fatigue < 0.7) {
      score += 0.15;
      reasons.add('Gentle activity appropriate for your energy level');
    }

    if (patient.pain > 0.2 && patient.pain < 0.6) {
      score += 0.1;
      reasons.add('May help with muscle tension and pain');
    }

    if (patient.ecog <= 2) {
      score += 0.1;
    }

    return score;
  }

  double _calculateCyclingUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.4;

    if (patient.ecog <= 1) {
      score += 0.2;
    } else {
      score -= 0.2;
      adaptations.add('Stationary bike recommended for safety');
    }

    if (patient.fatigue > 0.5) {
      score -= 0.15;
      adaptations.add('Keep duration short and intensity low');
    }

    if (patient.bmi >= 25) {
      score += 0.1;
      reasons.add('Good cardiovascular exercise with low joint impact');
    }

    if (patient.systolicBp >= 150) {
      score -= 0.2;
      adaptations.add('Consult doctor before cycling with elevated BP');
    }

    return score;
  }

  double _calculateStrengthUtility(
    PatientState patient,
    List<ParameterChange> changes,
    List<String> reasons,
    List<String> adaptations,
  ) {
    double score = 0.35;

    final latestCami = _getLatestCami(patient);
    if (latestCami != null && latestCami.dominantHandGripKg < 22) {
      score += 0.25;
      reasons.add('Strength training can help improve grip strength');
    }

    if (patient.ecog >= 2) {
      score -= 0.2;
      adaptations.add('Light resistance bands only');
    }

    if (patient.fatigue > 0.6) {
      score -= 0.15;
      adaptations.add('Focus on gentle resistance exercises');
    }

    if (patient.chemoCycle > 0 && patient.whiteCellCount < 4.5) {
      adaptations.add('Avoid shared gym equipment during treatment');
    }

    return score;
  }

  CamiTestResults? _getLatestCami(PatientState patient) {
    if (patient.camiT3.hasData) return patient.camiT3;
    if (patient.camiT2.hasData) return patient.camiT2;
    if (patient.camiT1.hasData) return patient.camiT1;
    if (patient.camiT0.hasData) return patient.camiT0;
    return null;
  }

  void _applyChangeAdaptation(
    ActivityType type,
    ParameterChange change,
    List<String> reasons,
    List<String> adaptations,
  ) {

    if (change.parameter == 'fatigue' && change.direction == ChangeDirection.increased) {
      adaptations.add('Fatigue has increased - reducing recommended intensity');
    }

    if (change.parameter == 'pain' && change.direction == ChangeDirection.increased) {
      adaptations.add('Pain level increased - focus on gentle movements');
    }

    if (change.parameter == 'mood' && change.direction == ChangeDirection.decreased) {
      if (type == ActivityType.breathing || type == ActivityType.yoga) {
        reasons.add('Recommended to help with mood changes');
      }
    }

    if (change.parameter == 'systolicBp' && change.direction == ChangeDirection.increased) {
      adaptations.add('Blood pressure elevated - keep intensity low');
    }

    if (change.parameter == 'stepsToday' && change.direction == ChangeDirection.decreased) {
      if (type == ActivityType.walking) {
        reasons.add('Help increase your daily step count');
      }
    }
  }

  Future<DynamicRecommendation?> _generateActivityRecommendation({
    required ActivityType activityType,
    required ActivityUtility utility,
    required PatientState patient,
    required PatientContext context,
    required List<ParameterChange> changedParameters,
  }) async {

    final params = _generateActivityParameters(activityType, patient, context);

    if (params == null) return null;

    final center = _selectBestCenter(activityType, patient);

    return DynamicRecommendation(
      id: '${activityType.name}_${DateTime.now().millisecondsSinceEpoch}',
      activityType: activityType,
      title: params.title,
      description: params.description,
      durationMinutes: params.duration,
      intensity: params.intensity,
      utilityScore: utility.score,
      reasons: utility.reasons,
      adaptations: utility.adaptations,
      center: center,
      generatedAt: DateTime.now(),
      triggeredByChanges: changedParameters.map((c) => c.parameter).toList(),
    );
  }

  ActivityParameters? _generateActivityParameters(
    ActivityType type,
    PatientState patient,
    PatientContext context,
  ) {

    int baseDuration;
    String intensity;

    switch (context.currentCapacity) {
      case CurrentCapacity.veryLimited:
        baseDuration = 10;
        intensity = 'very_light';
        break;
      case CurrentCapacity.limited:
        baseDuration = 15;
        intensity = 'light';
        break;
      case CurrentCapacity.moderate:
        baseDuration = 20;
        intensity = 'light_moderate';
        break;
      case CurrentCapacity.good:
        baseDuration = 30;
        intensity = 'moderate';
        break;
    }

    if (patient.preferences.intensityPref == IntensityPreference.veryLight) {
      baseDuration = (baseDuration * 0.7).round();
      intensity = 'very_light';
    }

    switch (type) {
      case ActivityType.walking:
        return ActivityParameters(
          title: 'Marche adaptee $baseDuration min',
          description: _getWalkingDescription(patient, baseDuration, intensity),
          duration: baseDuration,
          intensity: intensity,
        );
      case ActivityType.yoga:
        return ActivityParameters(
          title: 'Yoga doux $baseDuration min',
          description: _getYogaDescription(patient, baseDuration, context),
          duration: baseDuration,
          intensity: intensity,
        );
      case ActivityType.swimming:
        return ActivityParameters(
          title: 'Aquagym douce $baseDuration min',
          description: 'Exercices en piscine adaptes - faible impact sur les articulations',
          duration: baseDuration,
          intensity: intensity,
        );
      case ActivityType.breathing:
        return ActivityParameters(
          title: 'Exercices de respiration 15 min',
          description: 'Relaxation et respiration profonde pour gerer le stress et la fatigue',
          duration: 15,
          intensity: 'very_light',
        );
      case ActivityType.stretching:
        return ActivityParameters(
          title: 'Etirements doux $baseDuration min',
          description: 'Mobilite articulaire et etirements legers',
          duration: baseDuration,
          intensity: intensity,
        );
      case ActivityType.cycling:
        return ActivityParameters(
          title: 'Velo stationnaire $baseDuration min',
          description: 'Cardio leger sur velo stationnaire a votre rythme',
          duration: baseDuration,
          intensity: intensity,
        );
      case ActivityType.strength:
        return ActivityParameters(
          title: 'Renforcement leger 15 min',
          description: 'Exercices de renforcement avec bandes elastiques ou poids legers',
          duration: 15,
          intensity: 'light',
        );
      case ActivityType.other:
        return null;
    }
  }

  String _getWalkingDescription(PatientState patient, int duration, String intensity) {
    final buffer = StringBuffer('Marche ');

    if (intensity == 'very_light') {
      buffer.write('tres douce ');
    } else if (intensity == 'light') {
      buffer.write('douce ');
    } else {
      buffer.write('moderee ');
    }

    if (patient.whiteCellCount < 4.0) {
      buffer.write('en plein air (eviter les espaces confines) ');
    }

    if (patient.fatigue > 0.5) {
      buffer.write('- prevoir des pauses si necessaire');
    }

    return buffer.toString();
  }

  String _getYogaDescription(PatientState patient, int duration, PatientContext context) {
    if (patient.ecog >= 2) {
      return 'Yoga sur chaise - poses adaptees pour votre confort';
    }
    if (context.fatigueLevel == 'severe') {
      return 'Yoga restauratif - poses de relaxation et respiration';
    }
    return 'Yoga doux - enchainements legers et etirements';
  }

  ActivityCenter _selectBestCenter(ActivityType type, PatientState patient) {

    switch (type) {
      case ActivityType.walking:

        if (patient.preferences.environmentPref == EnvironmentPreference.outdoor) {
          return ActivityCenter.toursCenters[4];
        }
        return ActivityCenter.toursCenters[0];
      case ActivityType.yoga:
      case ActivityType.strength:
        return ActivityCenter.toursCenters[1];
      case ActivityType.swimming:
        return ActivityCenter.toursCenters[2];
      case ActivityType.breathing:
      case ActivityType.stretching:
        return ActivityCenter.toursCenters[3];
      case ActivityType.cycling:
        return ActivityCenter.toursCenters[5];
      default:
        return ActivityCenter.toursCenters[5];
    }
  }

  void _adaptRecommendations(
    List<DynamicRecommendation> recommendations,
    List<ParameterChange> changes,
    List<DynamicRecommendation> previous,
  ) {

    for (final rec in recommendations) {
      if (rec.triggeredByChanges.isNotEmpty) {

        rec.adaptations.add(
          'Adapte suite aux changements: ${rec.triggeredByChanges.join(", ")}'
        );
      }
    }
  }
}

class KGValidator {

  Future<List<DynamicRecommendation>> validate({
    required List<DynamicRecommendation> recommendations,
    required PatientState patient,
  }) async {
    final validated = <DynamicRecommendation>[];

    for (final rec in recommendations) {
      final validationResult = _validateSingleRecommendation(rec, patient);

      if (validationResult.isValid) {

        if (validationResult.modifications.isNotEmpty) {
          rec.adaptations.addAll(validationResult.modifications);
        }
        rec.validationStatus = ValidationStatus.validated;
        validated.add(rec);
      } else {

        debugPrint('Recommendation rejected: ${rec.title} - ${validationResult.reason}');
      }
    }

    return validated;
  }

  ValidationResult _validateSingleRecommendation(
    DynamicRecommendation rec,
    PatientState patient,
  ) {
    final modifications = <String>[];

    if (patient.ecog >= 3 && _isHighIntensityActivity(rec.activityType)) {
      return ValidationResult(
        isValid: false,
        reason: 'Activity too intense for ECOG ${patient.ecog}',
      );
    }

    if (patient.fatigue >= 0.8 && rec.durationMinutes > 15) {
      modifications.add('Duration limited due to severe fatigue');
      rec.durationMinutes = 15;
    }

    if (patient.systolicBp >= 180 || patient.diastolicBp >= 110) {
      if (_isCardioActivity(rec.activityType)) {
        return ValidationResult(
          isValid: false,
          reason: 'Blood pressure too high for cardiovascular activity',
        );
      }
    }

    if (patient.whiteCellCount < 3.0) {
      if (rec.activityType == ActivityType.swimming) {
        return ValidationResult(
          isValid: false,
          reason: 'Avoid pools with very low white cell count',
        );
      }
      modifications.add('Avoid crowded indoor facilities');
    }

    if (patient.pain >= 0.8) {
      if (_isPhysicalActivity(rec.activityType)) {
        modifications.add('Consider resting - consult healthcare provider if pain persists');
        rec.durationMinutes = 10;
      }
    }

    if (patient.diagnosis.toLowerCase().contains('breast')) {

      if (rec.activityType == ActivityType.strength) {
        modifications.add('Avoid exercises that strain the affected side');
      }
    }

    return ValidationResult(
      isValid: true,
      modifications: modifications,
    );
  }

  bool _isHighIntensityActivity(ActivityType type) {
    return type == ActivityType.cycling || type == ActivityType.strength;
  }

  bool _isCardioActivity(ActivityType type) {
    return type == ActivityType.walking ||
           type == ActivityType.cycling ||
           type == ActivityType.swimming;
  }

  bool _isPhysicalActivity(ActivityType type) {
    return type != ActivityType.breathing;
  }
}

class DynamicRecommendation {
  final String id;
  final ActivityType activityType;
  String title;
  String description;
  int durationMinutes;
  String intensity;
  double utilityScore;
  List<String> reasons;
  List<String> adaptations;
  ActivityCenter center;
  DateTime generatedAt;
  List<String> triggeredByChanges;
  ValidationStatus validationStatus;
  bool isStarted;

  DynamicRecommendation({
    required this.id,
    required this.activityType,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.intensity,
    required this.utilityScore,
    required this.reasons,
    required this.adaptations,
    required this.center,
    required this.generatedAt,
    this.triggeredByChanges = const [],
    this.validationStatus = ValidationStatus.pending,
    this.isStarted = false,
  });

  RecommendationItem toRecommendationItem() {
    return RecommendationItem(
      text: '$title - $description',
      center: center,
      isStarted: isStarted,
    );
  }
}

class ParameterChange {
  final String parameter;
  final dynamic oldValue;
  final dynamic newValue;
  final double delta;
  final double percentChange;
  final bool isSignificant;
  final ChangeDirection direction;

  ParameterChange({
    required this.parameter,
    required this.oldValue,
    required this.newValue,
    required this.delta,
    required this.percentChange,
    required this.isSignificant,
    required this.direction,
  });
}

enum ChangeDirection { increased, decreased, changed }

class ActivityUtility {
  final double score;
  final List<String> reasons;
  final List<String> adaptations;

  ActivityUtility({
    required this.score,
    required this.reasons,
    required this.adaptations,
  });
}

class PatientContext {
  final String fatigueLevel;
  final String painLevel;
  final String moodState;
  final FitnessLevel fitnessLevel;
  final List<String> riskFactors;
  final CurrentCapacity currentCapacity;

  PatientContext({
    required this.fatigueLevel,
    required this.painLevel,
    required this.moodState,
    required this.fitnessLevel,
    required this.riskFactors,
    required this.currentCapacity,
  });
}

enum FitnessLevel { veryLow, low, moderate, good }
enum CurrentCapacity { veryLimited, limited, moderate, good }
enum ValidationStatus { pending, validated, rejected }

class ValidationResult {
  final bool isValid;
  final String? reason;
  final List<String> modifications;

  ValidationResult({
    required this.isValid,
    this.reason,
    this.modifications = const [],
  });
}

class ActivityParameters {
  final String title;
  final String description;
  final int duration;
  final String intensity;

  ActivityParameters({
    required this.title,
    required this.description,
    required this.duration,
    required this.intensity,
  });
}
