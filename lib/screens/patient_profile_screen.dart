import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../models/patient_state.dart';

class PatientProfileScreen extends StatefulWidget {
  final PatientState state;
  final VoidCallback onStateChanged;

  const PatientProfileScreen({
    super.key,
    required this.state,
    required this.onStateChanged,
  });

  @override
  State<PatientProfileScreen> createState() => _PatientProfileScreenState();
}

class _PatientProfileScreenState extends State<PatientProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Profile'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileHeader(context, scheme),
            const SizedBox(height: 24),

            _buildSection(
              context: context,
              title: 'Personal Information',
              icon: Icons.person_outline,
              onEdit: () => _showEditPersonalInfo(context),
              children: [
                _buildInfoRow('Name', widget.state.fullName),
                _buildInfoRow('Age', '${widget.state.ageYears} years'),
                _buildInfoRow('Email', widget.state.email),
                _buildInfoRow('Phone', widget.state.phoneNumber),
              ],
            ),
            const SizedBox(height: 16),

            _buildSection(
              context: context,
              title: 'Medical Information',
              icon: Icons.medical_services_outlined,
              onEdit: () => _showEditMedicalInfo(context),
              children: [
                _buildInfoRow('Diagnosis', widget.state.diagnosis),
                _buildInfoRow('Stage', widget.state.stage),
                _buildInfoRow('Chemo Cycle', '${widget.state.chemoCycle}'),
                _buildInfoRow('ECOG Status', '${widget.state.ecog} - ${_getEcogDescription(widget.state.ecog)}'),
                const Divider(),
                _buildInfoRow('Height', '${widget.state.heightCm} cm'),
                _buildInfoRow('Weight', '${widget.state.weightKg} kg'),
                _buildInfoRow('BMI', widget.state.bmi.toStringAsFixed(1)),
                const Divider(),
                _buildInfoRow('Heart Rate', '${widget.state.heartRate} bpm'),
                _buildInfoRow('Blood Pressure',
                    '${widget.state.systolicBp}/${widget.state.diastolicBp} mmHg'),
                _buildInfoRow('Blood Sugar', '${widget.state.bloodSugar} mg/dL'),
                _buildInfoRow('White Cell Count', '${widget.state.whiteCellCount} x10⁹/L'),
              ],
            ),
            const SizedBox(height: 16),

            _buildCamiTestsCard(context, scheme),
            const SizedBox(height: 16),

            _buildDailySymptomsSection(context, scheme),
            const SizedBox(height: 16),

            _buildPreferencesSection(context, scheme),
            const SizedBox(height: 16),

            _buildDocumentsSection(context, scheme),
            const SizedBox(height: 16),

            _buildActivityHistorySection(context, scheme),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, ColorScheme scheme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [scheme.primary, scheme.primary.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 40, color: scheme.primary),
          ),
          const SizedBox(height: 16),
          Text(
            widget.state.fullName,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.state.diagnosis} - ${widget.state.stage}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withOpacity(0.9),
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required VoidCallback onEdit,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
              ],
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w500),
                textAlign: TextAlign.end),
          ),
        ],
      ),
    );
  }

  String _getEcogDescription(int ecog) {
    switch (ecog) {
      case 0:
        return 'Fully active';
      case 1:
        return 'Restricted but ambulatory';
      case 2:
        return 'Ambulatory, self-care';
      case 3:
        return 'Limited self-care';
      case 4:
        return 'Completely disabled';
      default:
        return 'Unknown';
    }
  }

  Widget _buildCamiTestsCard(BuildContext context, ColorScheme scheme) {
    return Card(
      child: InkWell(
        onTap: () => _showCamiTestsDialog(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.fitness_center, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CAMI Physical Tests',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'View results for T0, T1, T2, T3',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  void _showCamiTestsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600, maxHeight: 600),
          child: _CamiTestsView(
            camiT0: widget.state.camiT0,
            camiT1: widget.state.camiT1,
            camiT2: widget.state.camiT2,
            camiT3: widget.state.camiT3,
            onUpdate: (t0, t1, t2, t3) {
              setState(() {
                widget.state.camiT0 = t0;
                widget.state.camiT1 = t1;
                widget.state.camiT2 = t2;
                widget.state.camiT3 = t3;
              });
              widget.onStateChanged();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDailySymptomsSection(BuildContext context, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.mood_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Symptoms',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _showSymptomsHistory(context),
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('History'),
                ),
              ],
            ),
            const Divider(),
            _buildSliderInfo('Fatigue', widget.state.fatigue, Colors.orange),
            _buildSliderInfo('Pain', widget.state.pain, Colors.red),
            _buildSliderInfo('Mood', widget.state.mood, Colors.green),
            _buildInfoRow('Steps Today', '${widget.state.stepsToday}'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showEditSymptoms(context),
                    icon: const Icon(Icons.edit, size: 18),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _saveDailySymptoms(context),
                    icon: const Icon(Icons.save, size: 18),
                    label: const Text('Save Today'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSliderInfo(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              Text('${(value * 100).toInt()}%',
                  style: const TextStyle(fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation(color),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  void _saveDailySymptoms(BuildContext context) {
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Save Daily Symptoms'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Save current symptoms to history?',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'How are you feeling today?',
              ),
              maxLines: 2,
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
                widget.state.saveDailySymptoms(notes: notesController.text);
              });
              widget.onStateChanged();
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Daily symptoms saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSymptomsHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        final dateFormat = DateFormat('MMM d, yyyy - h:mm a');
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Symptoms History',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: widget.state.dailySymptomsHistory.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.history,
                                    size: 48, color: Colors.grey[400]),
                                const SizedBox(height: 8),
                                Text('No history yet',
                                    style: TextStyle(color: Colors.grey[600])),
                              ],
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: widget.state.dailySymptomsHistory.length,
                            itemBuilder: (context, index) {
                              final entry = widget.state.dailySymptomsHistory.reversed
                                  .toList()[index];
                              return Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        dateFormat.format(entry.date),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          _buildMiniChip('Fatigue',
                                              '${(entry.fatigue * 100).toInt()}%', Colors.orange),
                                          const SizedBox(width: 8),
                                          _buildMiniChip('Pain',
                                              '${(entry.pain * 100).toInt()}%', Colors.red),
                                          const SizedBox(width: 8),
                                          _buildMiniChip('Mood',
                                              '${(entry.mood * 100).toInt()}%', Colors.green),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text('Steps: ${entry.steps}',
                                          style: const TextStyle(fontSize: 12)),
                                      if (entry.notes.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          entry.notes,
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMiniChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('$label: $value',
          style: TextStyle(color: color, fontSize: 12)),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, ColorScheme scheme) {
    final prefs = widget.state.preferences;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tune_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Preferences',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => _showEditPreferences(context),
                  tooltip: 'Edit',
                ),
              ],
            ),
            const Divider(),
            _buildInfoRow('Preferred Activities',
                prefs.preferredActivities.map((a) => _activityTypeName(a)).join(', ')),
            _buildInfoRow('Environment', _environmentName(prefs.environmentPref)),
            _buildInfoRow('Max Distance', '${prefs.maxDistanceKm.toStringAsFixed(0)} km'),
            _buildInfoRow('Intensity', _intensityName(prefs.intensityPref)),
          ],
        ),
      ),
    );
  }

  String _activityTypeName(ActivityType type) {
    switch (type) {
      case ActivityType.walking: return 'Walking';
      case ActivityType.yoga: return 'Yoga';
      case ActivityType.strength: return 'Strength';
      case ActivityType.breathing: return 'Breathing';
      case ActivityType.cycling: return 'Cycling';
      case ActivityType.swimming: return 'Swimming';
      case ActivityType.stretching: return 'Stretching';
      case ActivityType.other: return 'Other';
    }
  }

  String _environmentName(EnvironmentPreference pref) {
    switch (pref) {
      case EnvironmentPreference.indoor: return 'Indoor';
      case EnvironmentPreference.outdoor: return 'Outdoor';
      case EnvironmentPreference.noPreference: return 'No preference';
    }
  }

  String _intensityName(IntensityPreference pref) {
    switch (pref) {
      case IntensityPreference.veryLight: return 'Very light';
      case IntensityPreference.light: return 'Light';
      case IntensityPreference.moderate: return 'Moderate';
      case IntensityPreference.high: return 'High';
    }
  }

  void _showEditPreferences(BuildContext context) {
    final prefs = widget.state.preferences;
    Set<ActivityType> selectedActivities = Set.from(prefs.preferredActivities);
    EnvironmentPreference envPref = prefs.environmentPref;
    double maxDist = prefs.maxDistanceKm;
    IntensityPreference intensityPref = prefs.intensityPref;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24, right: 24, top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Edit Preferences',
                            style: Theme.of(context).textTheme.titleLarge),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text('Preferred Activities',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ActivityType.values.map((type) {
                        final isSelected = selectedActivities.contains(type);
                        return FilterChip(
                          label: Text(_activityTypeName(type)),
                          selected: isSelected,
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedActivities.add(type);
                              } else {
                                selectedActivities.remove(type);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    Text('Environment',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<EnvironmentPreference>(
                      segments: const [
                        ButtonSegment(
                          value: EnvironmentPreference.indoor,
                          label: Text('Indoor'),
                          icon: Icon(Icons.home, size: 18),
                        ),
                        ButtonSegment(
                          value: EnvironmentPreference.outdoor,
                          label: Text('Outdoor'),
                          icon: Icon(Icons.park, size: 18),
                        ),
                        ButtonSegment(
                          value: EnvironmentPreference.noPreference,
                          label: Text('Any'),
                          icon: Icon(Icons.all_inclusive, size: 18),
                        ),
                      ],
                      selected: {envPref},
                      onSelectionChanged: (s) =>
                          setModalState(() => envPref = s.first),
                    ),
                    const SizedBox(height: 20),

                    Text('Max Distance: ${maxDist.toStringAsFixed(0)} km',
                        style: Theme.of(context).textTheme.titleSmall),
                    Slider(
                      value: maxDist,
                      min: 1,
                      max: 30,
                      divisions: 29,
                      label: '${maxDist.toStringAsFixed(0)} km',
                      onChanged: (v) => setModalState(() => maxDist = v),
                    ),
                    const SizedBox(height: 12),

                    Text('Preferred Intensity',
                        style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: 8),
                    SegmentedButton<IntensityPreference>(
                      segments: const [
                        ButtonSegment(
                          value: IntensityPreference.veryLight,
                          label: Text('V.Light'),
                        ),
                        ButtonSegment(
                          value: IntensityPreference.light,
                          label: Text('Light'),
                        ),
                        ButtonSegment(
                          value: IntensityPreference.moderate,
                          label: Text('Mod'),
                        ),
                        ButtonSegment(
                          value: IntensityPreference.high,
                          label: Text('High'),
                        ),
                      ],
                      selected: {intensityPref},
                      onSelectionChanged: (s) =>
                          setModalState(() => intensityPref = s.first),
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() {
                            widget.state.preferences = PatientPreferences(
                              preferredActivities: selectedActivities,
                              environmentPref: envPref,
                              maxDistanceKm: maxDist,
                              intensityPref: intensityPref,
                            );
                          });
                          widget.onStateChanged();
                          Navigator.pop(context);
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDocumentsSection(BuildContext context, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Documents',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _uploadDocument,
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Upload'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
            const Divider(),
            if (widget.state.documents.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.description_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No documents uploaded',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
              )
            else
              ...widget.state.documents.map((doc) => _buildDocumentItem(doc)),
          ],
        ),
      ),
    );
  }

  Widget _buildDocumentItem(PatientDocument doc) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _getDocTypeColor(doc.type).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(_getDocTypeIcon(doc.type), color: _getDocTypeColor(doc.type)),
      ),
      title: Text(doc.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('${doc.formattedSize} • ${dateFormat.format(doc.uploadDate)}'),
      trailing: IconButton(
        icon: const Icon(Icons.delete_outline, color: Colors.red),
        onPressed: () {
          setState(() {
            widget.state.removeDocument(doc.id);
          });
          widget.onStateChanged();
        },
      ),
    );
  }

  IconData _getDocTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getDocTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'pdf':
        return Colors.red;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _uploadDocument() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'doc', 'docx'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        final doc = PatientDocument(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: file.name,
          type: file.extension ?? 'unknown',
          uploadDate: DateTime.now(),
          path: file.path,
          sizeBytes: file.size,
        );
        setState(() {
          widget.state.addDocument(doc);
        });
        widget.onStateChanged();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading file: $e')),
        );
      }
    }
  }

  Widget _buildActivityHistorySection(BuildContext context, ColorScheme scheme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history_outlined, color: scheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Activity History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                Text(
                  '${widget.state.activityHistory.length} activities',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            const Divider(),

            if (widget.state.activityHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.directions_run_outlined,
                          size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text('No activities yet',
                          style: TextStyle(color: Colors.grey[600])),
                      const SizedBox(height: 4),
                      Text(
                        'Start activities from Recommendations',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...widget.state.activityHistory.reversed
                  .take(5)
                  .map((activity) => _buildActivityHistoryItem(context, activity)),

            if (widget.state.activityHistory.length > 5)
              TextButton(
                onPressed: () => _showAllActivities(context),
                child: const Text('View all activities'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHistoryItem(BuildContext context, ActivitySession activity) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final isCompleted = activity.status == ActivityStatus.completed;

    return InkWell(
      onTap: () => _showActivityDetails(context, activity),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(activity.typeIcon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  Text(
                    '${activity.center.name} • ${dateFormat.format(activity.date)}',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green.withOpacity(0.1)
                    : Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isCompleted ? 'Completed' : 'Started',
                style: TextStyle(
                  color: isCompleted ? Colors.green : Colors.blue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivityDetails(BuildContext context, ActivitySession activity) {
    final dateFormat = DateFormat('MMM d, yyyy h:mm a');
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(activity.typeIcon, style: const TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(activity.name,
                            style: Theme.of(context).textTheme.titleLarge),
                        Text(activity.typeName,
                            style: TextStyle(color: Colors.grey[600])),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24),
              _buildDetailRow('Date', dateFormat.format(activity.date)),
              _buildDetailRow('Duration', '${activity.durationMinutes} minutes'),
              _buildDetailRow('Status', activity.status == ActivityStatus.completed
                  ? 'Completed'
                  : 'Started'),
              const SizedBox(height: 16),
              Text('Center Information',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
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
                    Text(activity.center.name,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    _buildCenterRow(Icons.location_on_outlined, activity.center.address),
                    const SizedBox(height: 4),
                    _buildCenterRow(Icons.access_time_outlined, activity.center.openingHours),
                    const SizedBox(height: 4),
                    _buildCenterRow(Icons.phone_outlined, activity.center.phoneNumber),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: TextStyle(color: Colors.grey[600])),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildCenterRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
        ),
      ],
    );
  }

  void _showAllActivities(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _AllActivitiesScreen(
          activities: widget.state.activityHistory,
          onActivityTap: (a) {
            Navigator.pop(context);
            _showActivityDetails(context, a);
          },
        ),
      ),
    );
  }

  void _showEditPersonalInfo(BuildContext context) {
    final firstNameController = TextEditingController(text: widget.state.firstName);
    final lastNameController = TextEditingController(text: widget.state.lastName);
    final ageController = TextEditingController(text: widget.state.ageYears.toString());
    final emailController = TextEditingController(text: widget.state.email);
    final phoneController = TextEditingController(text: widget.state.phoneNumber);

    _showEditDialog(
      context: context,
      title: 'Edit Personal Information',
      fields: [
        _buildTextField(firstNameController, 'First Name'),
        _buildTextField(lastNameController, 'Last Name'),
        _buildTextField(ageController, 'Age', isNumber: true),
        _buildTextField(emailController, 'Email'),
        _buildTextField(phoneController, 'Phone'),
      ],
      onSave: () {
        setState(() {
          widget.state.firstName = firstNameController.text;
          widget.state.lastName = lastNameController.text;
          widget.state.ageYears = int.tryParse(ageController.text) ?? 0;
          widget.state.email = emailController.text;
          widget.state.phoneNumber = phoneController.text;
        });
        widget.onStateChanged();
      },
    );
  }

  void _showEditMedicalInfo(BuildContext context) {
    final diagnosisController = TextEditingController(text: widget.state.diagnosis);
    final stageController = TextEditingController(text: widget.state.stage);
    final chemoController = TextEditingController(text: widget.state.chemoCycle.toString());
    final ecogController = TextEditingController(text: widget.state.ecog.toString());
    final heightController = TextEditingController(text: widget.state.heightCm.toString());
    final weightController = TextEditingController(text: widget.state.weightKg.toString());
    final hrController = TextEditingController(text: widget.state.heartRate.toString());
    final sysController = TextEditingController(text: widget.state.systolicBp.toString());
    final diaController = TextEditingController(text: widget.state.diastolicBp.toString());
    final sugarController = TextEditingController(text: widget.state.bloodSugar.toString());
    final wbcController = TextEditingController(text: widget.state.whiteCellCount.toString());

    _showEditDialog(
      context: context,
      title: 'Edit Medical Information',
      fields: [
        _buildTextField(diagnosisController, 'Diagnosis'),
        _buildTextField(stageController, 'Stage'),
        _buildTextField(chemoController, 'Chemo Cycle', isNumber: true),
        _buildTextField(ecogController, 'ECOG Status (0-4)', isNumber: true),
        _buildTextField(heightController, 'Height (cm)', isNumber: true),
        _buildTextField(weightController, 'Weight (kg)', isNumber: true),
        _buildTextField(hrController, 'Heart Rate (bpm)', isNumber: true),
        _buildTextField(sysController, 'Systolic BP (mmHg)', isNumber: true),
        _buildTextField(diaController, 'Diastolic BP (mmHg)', isNumber: true),
        _buildTextField(sugarController, 'Blood Sugar (mg/dL)', isNumber: true),
        _buildTextField(wbcController, 'White Cell Count (x10⁹/L)', isNumber: true),
      ],
      onSave: () {
        setState(() {
          widget.state.diagnosis = diagnosisController.text;
          widget.state.stage = stageController.text;
          widget.state.chemoCycle = int.tryParse(chemoController.text) ?? 0;
          widget.state.ecog = int.tryParse(ecogController.text) ?? 0;
          widget.state.heightCm = double.tryParse(heightController.text) ?? 0;
          widget.state.weightKg = double.tryParse(weightController.text) ?? 0;
          widget.state.heartRate = int.tryParse(hrController.text) ?? 0;
          widget.state.systolicBp = int.tryParse(sysController.text) ?? 0;
          widget.state.diastolicBp = int.tryParse(diaController.text) ?? 0;
          widget.state.bloodSugar = double.tryParse(sugarController.text) ?? 0;
          widget.state.whiteCellCount = double.tryParse(wbcController.text) ?? 0;
        });
        widget.onStateChanged();
      },
    );
  }

  void _showEditSymptoms(BuildContext context) {
    double fatigue = widget.state.fatigue;
    double pain = widget.state.pain;
    double mood = widget.state.mood;
    final stepsController = TextEditingController(text: widget.state.stepsToday.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Edit Daily Symptoms',
                          style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSliderField('Fatigue', fatigue, Colors.orange,
                      (v) => setModalState(() => fatigue = v)),
                  const SizedBox(height: 16),
                  _buildSliderField('Pain', pain, Colors.red,
                      (v) => setModalState(() => pain = v)),
                  const SizedBox(height: 16),
                  _buildSliderField('Mood', mood, Colors.green,
                      (v) => setModalState(() => mood = v)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: stepsController,
                    decoration: const InputDecoration(labelText: 'Steps Today'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          widget.state.fatigue = fatigue;
                          widget.state.pain = pain;
                          widget.state.mood = mood;
                          widget.state.stepsToday = int.tryParse(stepsController.text) ?? 0;
                        });
                        widget.onStateChanged();
                        Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSliderField(
      String label, double value, Color color, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Text('${(value * 100).toInt()}%'),
          ],
        ),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: color,
          inactiveColor: color.withOpacity(0.2),
        ),
      ],
    );
  }

  void _showEditDialog({
    required BuildContext context,
    required String title,
    required List<Widget> fields,
    required VoidCallback onSave,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ...fields.map((f) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: f,
                    )),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      onSave();
                      Navigator.pop(context);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
    );
  }
}

class _CamiTestsView extends StatefulWidget {
  final CamiTestResults camiT0;
  final CamiTestResults camiT1;
  final CamiTestResults camiT2;
  final CamiTestResults camiT3;
  final Function(CamiTestResults, CamiTestResults, CamiTestResults, CamiTestResults) onUpdate;

  const _CamiTestsView({
    required this.camiT0,
    required this.camiT1,
    required this.camiT2,
    required this.camiT3,
    required this.onUpdate,
  });

  @override
  State<_CamiTestsView> createState() => _CamiTestsViewState();
}

class _CamiTestsViewState extends State<_CamiTestsView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late CamiTestResults _t0, _t1, _t2, _t3;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _t0 = widget.camiT0;
    _t1 = widget.camiT1;
    _t2 = widget.camiT2;
    _t3 = widget.camiT3;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.fitness_center, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'CAMI Physical Tests',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'T0'),
            Tab(text: 'T1'),
            Tab(text: 'T2'),
            Tab(text: 'T3'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildCamiTab(_t0, 'T0 - Baseline', (r) => setState(() => _t0 = r)),
              _buildCamiTab(_t1, 'T1 - 1st Follow-up', (r) => setState(() => _t1 = r)),
              _buildCamiTab(_t2, 'T2 - 2nd Follow-up', (r) => setState(() => _t2 = r)),
              _buildCamiTab(_t3, 'T3 - 3rd Follow-up', (r) => setState(() => _t3 = r)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                widget.onUpdate(_t0, _t1, _t2, _t3);
                Navigator.pop(context);
              },
              child: const Text('Save All Changes'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCamiTab(CamiTestResults results, String title, Function(CamiTestResults) onUpdate) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              if (results.testDate != null)
                Text(dateFormat.format(results.testDate!),
                    style: TextStyle(color: Colors.grey[600])),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: () => _editCamiResults(results, onUpdate),
              ),
            ],
          ),
          const Divider(),
          if (!results.hasData)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.add_circle_outline, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text('No data recorded', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () => _editCamiResults(results, onUpdate),
                      child: const Text('Add Data'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            _buildCamiSection('Body Composition', [
              _camiRow('Weight', '${results.weightKg} kg'),
              _camiRow('IMG (Fat Mass)', '${results.img}%'),
              _camiRow('IMM (Muscle Mass)', '${results.imm}%'),
            ]),
            _buildCamiSection('Strength Tests', [
              _camiRow('Chair Test', '${results.chairTestSeconds} s'),
              _camiRow('Plank Test', '${results.plankTestSeconds} s'),
              _camiRow('30s Chair Stand', '${results.chairStandTest30Sec} reps'),
              _camiRow('Dominant Hand Grip', '${results.dominantHandGripKg} kg'),
              _camiRow('Other Hand Grip', '${results.otherHandGripKg} kg'),
              _camiRow('Dominant Arm Curl', '${results.dominantArmCurlTest} reps'),
              _camiRow('Other Arm Curl', '${results.otherArmCurlTest} reps'),
            ]),
            _buildCamiSection('Cardio & Recovery', [
              _camiRow('Step Test (3min)', '${results.stepTestCount} steps'),
              _camiRow('Resting HR', '${results.restingHeartRate} bpm'),
              _camiRow('Exercise HR', '${results.exerciseHeartRate} bpm'),
              _camiRow('HR after 2min', '${results.heartRateAfter2Min} bpm'),
              _camiRow('Resting SpO2', '${results.restingSaturation}%'),
              _camiRow('Exercise SpO2', '${results.exerciseSaturation}%'),
            ]),
            _buildCamiSection('Effort Perception', [
              _camiRow('Exercise Intensity', '${results.exerciseIntensity}/10'),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildCamiSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary)),
        ),
        ...children,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _camiRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }

  void _editCamiResults(CamiTestResults results, Function(CamiTestResults) onUpdate) {
    final weightController = TextEditingController(text: results.weightKg.toString());
    final imgController = TextEditingController(text: results.img.toString());
    final immController = TextEditingController(text: results.imm.toString());
    final chairController = TextEditingController(text: results.chairTestSeconds.toString());
    final plankController = TextEditingController(text: results.plankTestSeconds.toString());
    final chairStandController = TextEditingController(text: results.chairStandTest30Sec.toString());
    final domGripController = TextEditingController(text: results.dominantHandGripKg.toString());
    final otherGripController = TextEditingController(text: results.otherHandGripKg.toString());
    final domCurlController = TextEditingController(text: results.dominantArmCurlTest.toString());
    final otherCurlController = TextEditingController(text: results.otherArmCurlTest.toString());
    final stepController = TextEditingController(text: results.stepTestCount.toString());
    final restHrController = TextEditingController(text: results.restingHeartRate.toString());
    final exHrController = TextEditingController(text: results.exerciseHeartRate.toString());
    final hr2minController = TextEditingController(text: results.heartRateAfter2Min.toString());
    final restO2Controller = TextEditingController(text: results.restingSaturation.toString());
    final exO2Controller = TextEditingController(text: results.exerciseSaturation.toString());
    final intensityController = TextEditingController(text: results.exerciseIntensity.toString());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Edit CAMI Results', style: Theme.of(ctx).textTheme.titleLarge),
                const SizedBox(height: 16),
                _field(weightController, 'Weight (kg)'),
                _field(imgController, 'IMG (%)'),
                _field(immController, 'IMM (%)'),
                _field(chairController, 'Chair Test (s)'),
                _field(plankController, 'Plank Test (s)'),
                _field(chairStandController, '30s Chair Stand (reps)'),
                _field(domGripController, 'Dominant Hand Grip (kg)'),
                _field(otherGripController, 'Other Hand Grip (kg)'),
                _field(domCurlController, 'Dominant Arm Curl (reps)'),
                _field(otherCurlController, 'Other Arm Curl (reps)'),
                _field(stepController, 'Step Test 3min (steps)'),
                _field(restHrController, 'Resting HR (bpm)'),
                _field(exHrController, 'Exercise HR (bpm)'),
                _field(hr2minController, 'HR after 2min (bpm)'),
                _field(restO2Controller, 'Resting SpO2 (%)'),
                _field(exO2Controller, 'Exercise SpO2 (%)'),
                _field(intensityController, 'Exercise Intensity (/10)'),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      final updated = CamiTestResults(
                        testDate: DateTime.now(),
                        weightKg: double.tryParse(weightController.text) ?? 0,
                        img: double.tryParse(imgController.text) ?? 0,
                        imm: double.tryParse(immController.text) ?? 0,
                        chairTestSeconds: double.tryParse(chairController.text) ?? 0,
                        plankTestSeconds: double.tryParse(plankController.text) ?? 0,
                        chairStandTest30Sec: int.tryParse(chairStandController.text) ?? 0,
                        dominantHandGripKg: double.tryParse(domGripController.text) ?? 0,
                        otherHandGripKg: double.tryParse(otherGripController.text) ?? 0,
                        dominantArmCurlTest: int.tryParse(domCurlController.text) ?? 0,
                        otherArmCurlTest: int.tryParse(otherCurlController.text) ?? 0,
                        stepTestCount: int.tryParse(stepController.text) ?? 0,
                        restingHeartRate: int.tryParse(restHrController.text) ?? 0,
                        exerciseHeartRate: int.tryParse(exHrController.text) ?? 0,
                        heartRateAfter2Min: int.tryParse(hr2minController.text) ?? 0,
                        restingSaturation: int.tryParse(restO2Controller.text) ?? 0,
                        exerciseSaturation: int.tryParse(exO2Controller.text) ?? 0,
                        exerciseIntensity: int.tryParse(intensityController.text) ?? 0,
                      );
                      onUpdate(updated);
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }
}

class _AllActivitiesScreen extends StatelessWidget {
  final List<ActivitySession> activities;
  final Function(ActivitySession) onActivityTap;

  const _AllActivitiesScreen({
    required this.activities,
    required this.onActivityTap,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    return Scaffold(
      appBar: AppBar(title: const Text('All Activities')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: activities.length,
        itemBuilder: (context, index) {
          final activity = activities.reversed.toList()[index];
          final isCompleted = activity.status == ActivityStatus.completed;
          return Card(
            child: ListTile(
              leading: Text(activity.typeIcon, style: const TextStyle(fontSize: 28)),
              title: Text(activity.name, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Text('${activity.center.name} • ${dateFormat.format(activity.date)}',
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              trailing: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.1)
                      : Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isCompleted ? 'Completed' : 'Started',
                  style: TextStyle(
                    color: isCompleted ? Colors.green : Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              onTap: () => onActivityTap(activity),
            ),
          );
        },
      ),
    );
  }
}
