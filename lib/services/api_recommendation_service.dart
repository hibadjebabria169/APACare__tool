import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/patient_state.dart';
import '../models/regional_center.dart';
import 'regional_centers_service.dart';

class ApiRecommendationService extends ChangeNotifier {
  static const String baseUrl = 'http://localhost:8000';

  List<LLMRecommendation> _recommendations = [];
  bool _isLoading = false;
  String? _lastError;
  String _llmExplanation = '';
  List<String> _matchedProfiles = [];
  List<String> _parameterChanges = [];

  Map<String, dynamic>? _previousParams;

  List<LLMRecommendation> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get lastError => _lastError;
  String get llmExplanation => _llmExplanation;
  List<String> get matchedProfiles => _matchedProfiles;
  List<String> get parameterChanges => _parameterChanges;

  Future<List<LLMRecommendation>> generateRecommendations(PatientState patient) async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {

      final requestBody = {
        'patient': _patientToJson(patient),
        'previous_params': _previousParams,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        _recommendations = (data['recommendations'] as List)
            .map((r) => LLMRecommendation.fromJson(r))
            .toList();

        _llmExplanation = data['llm_explanation'] ?? '';
        _matchedProfiles = List<String>.from(data['kg_matched_profiles'] ?? []);
        _parameterChanges = List<String>.from(data['parameter_changes'] ?? []);

        _previousParams = _patientToJson(patient);

        await _attachRegionalCenters(_recommendations);

        _isLoading = false;
        notifyListeners();
        return _recommendations;
      } else {
        throw Exception('API error: ${response.statusCode}');
      }
    } catch (e) {
      _lastError = e.toString();
      _isLoading = false;

      debugPrint('API call failed: $e. Using fallback.');
      _recommendations = _generateFallbackRecommendations(patient);

      await _attachRegionalCenters(_recommendations);

      notifyListeners();
      return _recommendations;
    }
  }

  Map<String, dynamic> _patientToJson(PatientState patient) {
    return {
      'disease': patient.diagnosis,
      'ecog': patient.ecog,
      'fatigue': patient.fatigue,
      'pain': patient.pain,
      'mood': patient.mood,
      'heart_rate': patient.heartRate,
      'systolic_bp': patient.systolicBp,
      'diastolic_bp': patient.diastolicBp,
      'blood_sugar': patient.bloodSugar,
      'white_cell_count': patient.whiteCellCount,
      'bmi': patient.bmi,
      'chemo_cycle': patient.chemoCycle,
      'steps_today': patient.stepsToday,
      'preferred_activities': patient.preferences.preferredActivities
          .map((a) => a.name)
          .toList(),
      'intensity_preference': patient.preferences.intensityPref.name,
      'environment_preference': patient.preferences.environmentPref.name,
    };
  }

  Future<void> _attachRegionalCenters(List<LLMRecommendation> recommendations) async {
    final centersService = RegionalCentersService();
    final futures = recommendations
        .map((r) => centersService.fetchCentersForActivity(r.activityType))
        .toList();
    final results = await Future.wait(futures);
    for (int i = 0; i < recommendations.length; i++) {
      if (results[i].isNotEmpty) {
        recommendations[i].regionalCenter = results[i].first;
      }
    }
  }

  List<LLMRecommendation> _generateFallbackRecommendations(PatientState patient) {
    final recommendations = <LLMRecommendation>[];

    if (patient.ecog <= 1 && patient.fatigue < 0.6) {
      recommendations.add(LLMRecommendation(
        id: 'fallback_walking',
        activityType: 'walking',
        title: 'Moderate Walking 30 min',
        description: 'Walking adapted to your current status',
        durationMinutes: 30,
        intensity: 'moderate',
        utilityScore: 0.85,
        kgValidationScore: 0.9,
        combinedScore: 0.87,
        reasons: ['Recommended by ACSM guidelines for cancer patients'],
        adaptations: [],
        kgEvidence: ['ACSM Guidelines 2019'],
        centerName: 'Jardin Botanique de Tours',
        centerAddress: '35 Boulevard Tonnellé, 37000 Tours',
        snomed: SnomedCoding(
          code: '129006008',
          term: 'Walking (observable entity)',
          uri: 'http://snomed.info/id/129006008',
        ),
      ));
    }

    if (patient.fatigue > 0.3) {
      recommendations.add(LLMRecommendation(
        id: 'fallback_yoga',
        activityType: 'yoga',
        title: 'Gentle Yoga 20-30 min',
        description: 'Yoga adapted for fatigue management',
        durationMinutes: 20,
        intensity: 'light',
        utilityScore: 0.82,
        kgValidationScore: 0.85,
        combinedScore: 0.83,
        reasons: ['Helps manage fatigue', 'Improves mood'],
        adaptations: patient.ecog >= 2 ? ['Chair yoga recommended'] : [],
        kgEvidence: ['Oncology Nursing Forum'],
        centerName: 'CAMI Sport & Cancer - CHU Tours',
        centerAddress: 'Hôpital Bretonneau, 2 Bd Tonnellé, 37000 Tours',
        snomed: SnomedCoding(
          code: '229294001',
          term: 'Yoga (regime/therapy)',
          uri: 'http://snomed.info/id/229294001',
        ),
      ));
    }

    recommendations.add(LLMRecommendation(
      id: 'fallback_breathing',
      activityType: 'breathing',
      title: 'Breathing Exercises 15 min',
      description: 'Relaxation and deep breathing',
      durationMinutes: 15,
      intensity: 'very_light',
      utilityScore: 0.88,
      kgValidationScore: 0.95,
      combinedScore: 0.91,
      reasons: ['Suitable for all fatigue levels', 'Reduces anxiety'],
      adaptations: [],
      kgEvidence: ['NCCN Fatigue Guidelines'],
      centerName: 'Espace Bien-être Touraine',
      centerAddress: '18 Rue Nationale, 37000 Tours',
      snomed: SnomedCoding(
        code: '304549008',
        term: 'Breathing exercise (regime/therapy)',
        uri: 'http://snomed.info/id/304549008',
      ),
    ));

    return recommendations;
  }

  Future<bool> checkBackendHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  void clearRecommendations() {
    _recommendations = [];
    _previousParams = null;
    notifyListeners();
  }
}

class SnomedCoding {
  final String code;
  final String term;
  final String uri;

  SnomedCoding({
    required this.code,
    required this.term,
    required this.uri,
  });

  factory SnomedCoding.fromJson(Map<String, dynamic> json) {
    return SnomedCoding(
      code: json['code'] ?? '',
      term: json['term'] ?? '',
      uri: json['uri'] ?? '',
    );
  }
}

class LLMRecommendation {
  final String id;
  final String activityType;
  final String title;
  final String description;
  final int durationMinutes;
  final String intensity;
  final double utilityScore;
  final double kgValidationScore;
  final double combinedScore;
  final List<String> reasons;
  final List<String> adaptations;
  final List<String> kgEvidence;
  final String centerName;
  final String centerAddress;
  final SnomedCoding? snomed;
  bool isStarted;
  RegionalCenter? regionalCenter;

  LLMRecommendation({
    required this.id,
    required this.activityType,
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.intensity,
    required this.utilityScore,
    required this.kgValidationScore,
    required this.combinedScore,
    required this.reasons,
    required this.adaptations,
    required this.kgEvidence,
    required this.centerName,
    required this.centerAddress,
    this.snomed,
    this.isStarted = false,
  });

  factory LLMRecommendation.fromJson(Map<String, dynamic> json) {
    return LLMRecommendation(
      id: json['id'] ?? '',
      activityType: json['activity_type'] ?? 'other',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      durationMinutes: json['duration_minutes'] ?? 20,
      intensity: json['intensity'] ?? 'light',
      utilityScore: (json['utility_score'] ?? 0.5).toDouble(),
      kgValidationScore: (json['kg_validation_score'] ?? 0.5).toDouble(),
      combinedScore: (json['combined_score'] ?? 0.5).toDouble(),
      reasons: List<String>.from(json['reasons'] ?? []),
      adaptations: List<String>.from(json['adaptations'] ?? []),
      kgEvidence: List<String>.from(json['kg_evidence'] ?? []),
      centerName: json['center_name'] ?? '',
      centerAddress: json['center_address'] ?? '',
      snomed: json['snomed'] != null
          ? SnomedCoding.fromJson(json['snomed'])
          : null,
    );
  }

  RecommendationItem toRecommendationItem() {
    return RecommendationItem(
      text: '$title - $description',
      center: ActivityCenter(
        name: centerName,
        address: centerAddress,
        openingHours: 'Contact for hours',
        phoneNumber: 'Contact center',
      ),
      isStarted: isStarted,
    );
  }
}
