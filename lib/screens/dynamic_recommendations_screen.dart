import 'package:flutter/material.dart';
import '../models/patient_state.dart';
import '../services/recommendation_service.dart';

class DynamicRecommendationsScreen extends StatefulWidget {
  final PatientState state;
  final RecommendationService recommendationService;

  const DynamicRecommendationsScreen({
    super.key,
    required this.state,
    required this.recommendationService,
  });

  @override
  State<DynamicRecommendationsScreen> createState() => _DynamicRecommendationsScreenState();
}

class _DynamicRecommendationsScreenState extends State<DynamicRecommendationsScreen> {
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
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didUpdateWidget(DynamicRecommendationsScreen oldWidget) {
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
    final recommendations = widget.recommendationService.recommendations;
    final isLoading = widget.recommendationService.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Smart Recommendations'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _loadRecommendations,
            tooltip: 'Refresh recommendations',
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
                      _buildSummaryCard(context, scheme, recommendations),
                      const SizedBox(height: 8),
                      if (isLoading)
                        const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      _buildParameterSummary(context, scheme),
                      const SizedBox(height: 16),
                      ...recommendations.asMap().entries.map(
                            (entry) => _DynamicRecommendationCard(
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
            'Analyzing your health data...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Generating personalized recommendations',
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
          Icon(Icons.check_circle_outline, size: 80, color: Colors.green.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text('Looking Good!', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'No specific recommendations at this time.\nKeep up the great work!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: _loadRecommendations,
            icon: const Icon(Icons.refresh),
            label: const Text('Check Again'),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, ColorScheme scheme, List<DynamicRecommendation> recs) {

    final adaptedCount = recs.where((r) => r.triggeredByChanges.isNotEmpty).length;

    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: scheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.psychology, color: scheme.onPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI-Powered Recommendations',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${recs.length} personalized activities',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (adaptedCount > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.sync, color: Colors.orange, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$adaptedCount recommendation${adaptedCount > 1 ? 's' : ''} adapted to your changes',
                        style: const TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildParameterSummary(BuildContext context, ColorScheme scheme) {
    final state = widget.state;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_outlined, color: scheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Current Parameters',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildParameterChip('Fatigue', '${(state.fatigue * 100).toInt()}%',
                    _getParameterColor(state.fatigue)),
                _buildParameterChip('Pain', '${(state.pain * 100).toInt()}%',
                    _getParameterColor(state.pain)),
                _buildParameterChip('Mood', '${(state.mood * 100).toInt()}%',
                    _getParameterColor(1 - state.mood)),
                _buildParameterChip('ECOG', '${state.ecog}',
                    _getEcogColor(state.ecog)),
                _buildParameterChip('Steps', '${state.stepsToday}',
                    state.stepsToday >= 5000 ? Colors.green : Colors.orange),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Recommendations adapt automatically when these values change',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParameterChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getParameterColor(double value) {
    if (value < 0.3) return Colors.green;
    if (value < 0.6) return Colors.orange;
    return Colors.red;
  }

  Color _getEcogColor(int ecog) {
    if (ecog <= 1) return Colors.green;
    if (ecog == 2) return Colors.orange;
    return Colors.red;
  }

  void _startActivity(DynamicRecommendation recommendation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.title,
                style: const TextStyle(fontWeight: FontWeight.bold)),
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
                  Text(
                    recommendation.center.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    recommendation.center.address,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                recommendation.isStarted = true;
                widget.state.addActivityFromRecommendation(
                  recommendation.toRecommendationItem(),
                );
              });
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Activity started! Added to your history.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }
}

class _DynamicRecommendationCard extends StatelessWidget {
  final int index;
  final DynamicRecommendation recommendation;
  final VoidCallback onStarted;

  const _DynamicRecommendationCard({
    required this.index,
    required this.recommendation,
    required this.onStarted,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isStarted = recommendation.isStarted;
    final isAdapted = recommendation.triggeredByChanges.isNotEmpty;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isStarted
                          ? Colors.green.withOpacity(0.1)
                          : scheme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getIconForActivity(recommendation.activityType),
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
                            Text(
                              'Activity $index',
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                            const SizedBox(width: 8),
                            _buildUtilityBadge(recommendation.utilityScore),
                            if (isAdapted) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.sync, size: 10, color: Colors.orange),
                                    SizedBox(width: 2),
                                    Text(
                                      'Adapted',
                                      style: TextStyle(
                                        color: Colors.orange,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            if (isStarted) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'Started',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          recommendation.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: isStarted ? Colors.grey : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recommendation.description,
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (recommendation.reasons.isNotEmpty) ...[
                const SizedBox(height: 12),
                _buildReasonsSection(recommendation.reasons),
              ],

              if (recommendation.adaptations.isNotEmpty) ...[
                const SizedBox(height: 8),
                _buildAdaptationsSection(recommendation.adaptations),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              _buildCenterInfo(scheme),

              if (!isStarted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onStarted,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Tap to start this activity'),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUtilityBadge(double score) {
    Color color;

    if (score >= 0.7) {
      color = Colors.green;
    } else if (score >= 0.5) {
      color = Colors.blue;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 10, color: color),
          const SizedBox(width: 2),
          Text(
            '${(score * 100).toInt()}%',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReasonsSection(List<String> reasons) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, size: 14, color: Colors.green[700]),
              const SizedBox(width: 4),
              Text(
                'Why this is recommended:',
                style: TextStyle(
                  color: Colors.green[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...reasons.take(3).map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  ',
                        style: TextStyle(color: Colors.green[600], fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        reason,
                        style: TextStyle(color: Colors.green[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildAdaptationsSection(List<String> adaptations) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.tune, size: 14, color: Colors.orange[700]),
              const SizedBox(width: 4),
              Text(
                'Adaptations:',
                style: TextStyle(
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...adaptations.take(3).map((adaptation) => Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('  ',
                        style: TextStyle(color: Colors.orange[600], fontSize: 12)),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        adaptation,
                        style: TextStyle(color: Colors.orange[800], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildCenterInfo(ColorScheme scheme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_city, size: 16, color: scheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.center.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCenterInfoRow(
            Icons.location_on_outlined,
            recommendation.center.address,
          ),
          const SizedBox(height: 4),
          _buildCenterInfoRow(
            Icons.access_time_outlined,
            recommendation.center.openingHours,
          ),
          const SizedBox(height: 4),
          _buildCenterInfoRow(
            Icons.phone_outlined,
            recommendation.center.phoneNumber,
          ),
        ],
      ),
    );
  }

  Widget _buildCenterInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
          ),
        ),
      ],
    );
  }

  IconData _getIconForActivity(ActivityType type) {
    switch (type) {
      case ActivityType.walking:
        return Icons.directions_walk;
      case ActivityType.yoga:
        return Icons.self_improvement;
      case ActivityType.breathing:
        return Icons.air;
      case ActivityType.swimming:
        return Icons.pool;
      case ActivityType.cycling:
        return Icons.pedal_bike;
      case ActivityType.stretching:
        return Icons.accessibility_new;
      case ActivityType.strength:
        return Icons.fitness_center;
      case ActivityType.other:
        return Icons.star;
    }
  }
}
