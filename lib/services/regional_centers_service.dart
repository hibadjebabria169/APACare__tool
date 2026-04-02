import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/regional_center.dart';

class RegionalCentersService {
  static const String baseUrl = 'https://regionalcenters.onrender.com';

  static const Map<String, String> _activityKeywords = {
    'walking': 'Marche',
    'yoga': 'Yoga',
    'strength': 'Condition Physique',
    'breathing': 'Gymnastique',
    'cycling': 'Cyclisme',
    'swimming': 'Natation',
    'stretching': 'Activités',
    'other': 'Sport',
  };

  Future<List<RegionalCenter>> fetchCentersForActivity(String activityType) async {
    final keyword = _activityKeywords[activityType] ?? 'Sport';

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/discipline?name=${Uri.encodeComponent(keyword)}'),
      ).timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final centers = data.map((c) => RegionalCenter.fromJson(c)).toList();

        // Keep only centers that explicitly handle cancer patients
        final cancerCenters = centers
            .where((c) => c.pathologies.any(
                  (p) => p.toLowerCase().contains('cancer'),
                ))
            .toList();

        return cancerCenters.take(3).toList();
      }
    } catch (e) {
      debugPrint('RegionalCentersService: failed for $activityType — $e');
    }
    return [];
  }
}
