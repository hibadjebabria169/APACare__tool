import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'screens/patient_profile_screen.dart';
import 'screens/llm_recommendations_screen.dart';
import 'models/patient_state.dart';
import 'services/api_recommendation_service.dart';

void main() {
  runApp(const APACareApp());
}

class APACareApp extends StatelessWidget {
  const APACareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'APACare',
      theme: AppTheme.light(),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  final PatientState _patientState = PatientState();
  final ApiRecommendationService _recommendationService = ApiRecommendationService();

  late Map<String, dynamic> _previousValues;

  @override
  void initState() {
    super.initState();
    _previousValues = _captureCurrentValues();
  }

  Map<String, dynamic> _captureCurrentValues() {
    return {
      'fatigue': _patientState.fatigue,
      'pain': _patientState.pain,
      'mood': _patientState.mood,
      'ecog': _patientState.ecog,
      'heartRate': _patientState.heartRate,
      'systolicBp': _patientState.systolicBp,
      'stepsToday': _patientState.stepsToday,
    };
  }

  void _onPatientStateChanged() {
    final currentValues = _captureCurrentValues();

    bool hasSignificantChange = false;
    for (final key in currentValues.keys) {
      final current = currentValues[key];
      final previous = _previousValues[key];
      if (current != previous) {
        hasSignificantChange = true;
        debugPrint('Parameter changed: $key: $previous -> $current');
      }
    }

    _previousValues = currentValues;

    setState(() {});

    if (hasSignificantChange && _currentIndex == 1) {

      _recommendationService.generateRecommendations(_patientState);
    }
  }

  @override
  void dispose() {
    _recommendationService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          PatientProfileScreen(
            state: _patientState,
            onStateChanged: _onPatientStateChanged,
          ),
          LLMRecommendationsScreen(
            state: _patientState,
            recommendationService: _recommendationService,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);

          if (index == 1) {
            _recommendationService.generateRecommendations(_patientState);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          NavigationDestination(
            icon: Icon(Icons.recommend_outlined),
            selectedIcon: Icon(Icons.recommend),
            label: 'Recommendations',
          ),
        ],
      ),
    );
  }
}
