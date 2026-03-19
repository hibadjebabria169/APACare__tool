import 'package:flutter/material.dart';
import '../models/patient_state.dart';

class RecommendationsScreen extends StatefulWidget {
  final PatientState state;

  const RecommendationsScreen({super.key, required this.state});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  late List<RecommendationItem> _recommendations;

  @override
  void initState() {
    super.initState();
    _recommendations = widget.state.generateRecommendations();
  }

  @override
  void didUpdateWidget(RecommendationsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _recommendations = widget.state.generateRecommendations();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendations'),
        centerTitle: true,
      ),
      body: _recommendations.isEmpty
          ? _buildEmptyState(context)
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSummaryCard(context, scheme, _recommendations.length),
                const SizedBox(height: 16),
                ..._recommendations.asMap().entries.map(
                      (entry) => _RecommendationCard(
                        index: entry.key + 1,
                        recommendation: entry.value,
                        onStarted: () {
                          setState(() {
                            entry.value.isStarted = true;
                            widget.state.addActivityFromRecommendation(entry.value);
                          });
                        },
                      ),
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
                    'Today\'s Recommendations',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$count personalized activities based on your health data',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final int index;
  final RecommendationItem recommendation;
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
        onTap: isStarted ? null : () => _showStartDialog(context),
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
                      _getIconForRecommendation(recommendation.text),
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
                            if (isStarted) ...[
                              const SizedBox(width: 8),
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
                          recommendation.text,
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: isStarted ? Colors.grey : null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),
              _buildSnomedBadge(
                context,
                recommendation.snomed ?? const LocalSnomedCoding(code: '000000', term: 'Test - No SNOMED assigned'),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              Container(
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
              ),

              if (!isStarted) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showStartDialog(context),
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

  Widget _buildSnomedBadge(BuildContext context, LocalSnomedCoding snomed) {
    return Container(
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
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${snomed.code} - ${snomed.term}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.teal[800],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showStartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(recommendation.text),
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
            const SizedBox(height: 16),
            Text(
              'Mark this activity as started?',
              style: TextStyle(color: Colors.grey[600]),
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
              onStarted();
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

  IconData _getIconForRecommendation(String rec) {
    if (rec.contains('walk') || rec.contains('steps')) return Icons.directions_walk;
    if (rec.contains('breathing') || rec.contains('mindfulness')) return Icons.self_improvement;
    if (rec.contains('rest') || rec.contains('Avoid')) return Icons.hotel;
    if (rec.contains('exercise') || rec.contains('cycling')) return Icons.fitness_center;
    if (rec.contains('heat') || rec.contains('ice') || rec.contains('Pain')) return Icons.healing;
    if (rec.contains('HR') || rec.contains('heart')) return Icons.favorite;
    if (rec.contains('BP') || rec.contains('provider')) return Icons.medical_services;
    if (rec.contains('home') || rec.contains('indoor')) return Icons.home;
    if (rec.contains('pool') || rec.contains('bike')) return Icons.pool;
    if (rec.contains('grip') || rec.contains('ball')) return Icons.back_hand;
    if (rec.contains('sit-to-stand') || rec.contains('leg')) return Icons.airline_seat_recline_normal;
    if (rec.contains('core') || rec.contains('plank')) return Icons.accessibility_new;
    return Icons.lightbulb_outline;
  }
}
