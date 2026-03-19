import 'package:flutter/material.dart';
import '../models/patient_state.dart';
import '../services/api_recommendation_service.dart';

class LLMRecommendationsScreen extends StatefulWidget {
  final PatientState state;
  final ApiRecommendationService recommendationService;

  const LLMRecommendationsScreen({
    super.key,
    required this.state,
    required this.recommendationService,
  });

  @override
  State<LLMRecommendationsScreen> createState() => _LLMRecommendationsScreenState();
}

class _LLMRecommendationsScreenState extends State<LLMRecommendationsScreen> {
  bool _isFirstLoad = true;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    widget.recommendationService.addListener(_onServiceUpdate);
  }

  @override
  void dispose() {
    widget.recommendationService.removeListener(_onServiceUpdate);
    super.dispose();
  }

  void _onServiceUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(LLMRecommendationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    await widget.recommendationService.generateRecommendations(widget.state);
    _isFirstLoad = false;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final service = widget.recommendationService;
    final recommendations = service.recommendations;
    final isLoading = service.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadRecommendations,
          ),
        ],
      ),
      body: isLoading && _isFirstLoad
          ? _buildLoadingState(context)
          : recommendations.isEmpty
              ? _buildEmptyState(context)
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(context, scheme, recommendations.length),
                      if (isLoading) const LinearProgressIndicator(),
                      if (service.parameterChanges.isNotEmpty)
                        _buildChangesCard(context, scheme),
                      const SizedBox(height: 16),
                      ...recommendations.asMap().entries.map(
                            (entry) => _RecommendationCard(
                              index: entry.key + 1,
                              recommendation: entry.value,
                              onStarted: () => _startActivity(entry.value),
                            ),
                          ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Generating recommendations...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Analyzing your health data',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.healing, size: 80, color: Colors.orange.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Rest Recommended', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Based on your current health status,\nno physical activities are recommended.\nPlease consult your healthcare provider.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ColorScheme scheme, int count) {
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.recommend, color: scheme.onPrimary, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Today's Recommendations",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count personalized activities based on your health data',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChangesCard(BuildContext context, ColorScheme scheme) {
    final changes = widget.recommendationService.parameterChanges;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Card(
        color: Colors.orange.withOpacity(0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.sync, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recommendations Adapted',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      changes.join(' | '),
                      style: TextStyle(color: Colors.orange[700], fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startActivity(LLMRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(recommendation.description),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(recommendation.centerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(recommendation.centerAddress, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              setState(() {
                recommendation.isStarted = true;
                widget.state.addActivityFromRecommendation(recommendation.toRecommendationItem());
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Activity started!'), backgroundColor: Colors.green),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final int index;
  final LLMRecommendation recommendation;
  final VoidCallback onStarted;

  const _RecommendationCard({
    required this.index,
    required this.recommendation,
    required this.onStarted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStarted = recommendation.isStarted;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: isStarted ? null : onStarted,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isStarted ? Colors.green.withOpacity(0.1) : scheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getActivityIcon(recommendation.activityType),
                      color: isStarted ? Colors.green : scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Activity $index', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            const SizedBox(width: 8),
                            _buildScoreBadge(recommendation.utilityScore),
                            if (isStarted) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('Started', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(recommendation.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isStarted ? Colors.grey : null)),
                        Text(recommendation.description, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Icon(Icons.timer_outlined, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text('${recommendation.durationMinutes} min', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(recommendation.intensity, style: const TextStyle(fontSize: 11)),
                  ),
                ],
              ),

              if (recommendation.snomed != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.teal.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.teal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.medical_information, size: 16, color: Colors.teal[700]),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SNOMED-CT',
                              style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.teal[700]),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${recommendation.snomed!.code} - ${recommendation.snomed!.term}',
                              style: TextStyle(fontSize: 11, color: Colors.teal[800]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildSection('Why recommended', recommendation.reasons, Colors.green, Icons.lightbulb_outline),
              ],

              if (recommendation.adaptations.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildSection('Adaptations', recommendation.adaptations, Colors.orange, Icons.tune),
              ],

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(recommendation.centerName, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                          Text(recommendation.centerAddress, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              if (!isStarted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onStarted,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Activity'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreBadge(double score) {
    final color = score >= 0.8 ? Colors.green : score >= 0.6 ? Colors.blue : Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: color),
          const SizedBox(width: 2),
          Text('${(score * 100).toInt()}%', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<String> items, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: color),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ...items.take(2).map((item) => Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text('• $item', style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
          )),
        ],
      ),
    );
  }

  IconData _getActivityIcon(String type) {
    switch (type) {
      case 'walking': return Icons.directions_walk;
      case 'yoga': return Icons.self_improvement;
      case 'breathing': return Icons.air;
      case 'swimming': return Icons.pool;
      case 'cycling': return Icons.pedal_bike;
      case 'stretching': return Icons.accessibility_new;
      case 'strength': return Icons.fitness_center;
      default: return Icons.sports;
    }
  }
}
