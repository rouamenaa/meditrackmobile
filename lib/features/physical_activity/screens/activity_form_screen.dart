import 'package:flutter/material.dart';
import '../../auth/services/session.dart';
import '../models/physical_activity.dart';
import '../services/activity_reminder_service.dart';
import '../services/activity_service.dart';

class ActivityFormScreen extends StatefulWidget {
  final PhysicalActivity? activityToEdit;
  final String? userId;
  final DateTime? initialDate;
  final String? initialType;
  final int? initialDuration;
  final String? initialIntensity;
  final String? initialNotes;

  const ActivityFormScreen({
    super.key,
    this.activityToEdit,
    this.userId,
    this.initialDate,
    this.initialType,
    this.initialDuration,
    this.initialIntensity,
    this.initialNotes,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityService = ActivityService();
  final _reminderService = ActivityReminderService();

  late String _selectedType;
  late String _selectedIntensity;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();
  final _caloriesController = TextEditingController();

  bool _isSaving = false;
  int? _suggestedCalories;

  final List<(String, IconData)> _activityTypes = const [
    ('Walking', Icons.directions_walk_rounded),
    ('Running', Icons.directions_run_rounded),
    ('Cycling', Icons.directions_bike_rounded),
    ('Swimming', Icons.pool_rounded),
    ('Other', Icons.fitness_center_rounded),
  ];

  final List<(String, Color)> _intensities = const [
    ('Low', Color(0xFF2E7D32)),
    ('Moderate', Color(0xFFEF6C00)),
    ('High', Color(0xFFC62828)),
  ];

  bool get _isEditMode => widget.activityToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.activityToEdit;

    if (item != null) {
      final t = item.typeLabel;
      _selectedType = _activityTypes.any((x) => x.$1 == t) ? t : 'Other';
      final i = item.intensityLabel;
      _selectedIntensity = _intensities.any((x) => x.$1 == i) ? i : 'Moderate';
      _selectedDate = item.activityDate;
      _selectedTime = TimeOfDay.fromDateTime(item.activityDate);
      _durationController.text = item.durationMinutes.toString();
      _distanceController.text =
          item.distanceKm != null ? item.distanceKm.toString() : '';
      _notesController.text = item.notes ?? '';
      _caloriesController.text =
          item.caloriesBurned != null ? item.caloriesBurned.toString() : '';
    } else {
      String initT = widget.initialType ?? 'Walking';
      switch (initT.trim().toLowerCase()) {
        case 'marche':
        case 'walking':
          initT = 'Walking';
          break;
        case 'course':
        case 'running':
          initT = 'Running';
          break;
        case 'vélo':
        case 'velo':
        case 'cycling':
          initT = 'Cycling';
          break;
        case 'natation':
        case 'swimming':
          initT = 'Swimming';
          break;
        default:
          initT = 'Other';
      }
      _selectedType = initT;

      String initI = widget.initialIntensity ?? 'Moderate';
      switch (initI.trim().toLowerCase()) {
        case 'faible':
        case 'low':
          initI = 'Low';
          break;
        case 'élevée':
        case 'elevee':
        case 'high':
          initI = 'High';
          break;
        default:
          initI = 'Moderate';
      }
      _selectedIntensity = initI;

      _selectedDate = widget.initialDate ?? DateTime.now();
      _selectedTime = widget.initialDate != null
          ? TimeOfDay.fromDateTime(widget.initialDate!)
          : TimeOfDay.now();
      _durationController.text = (widget.initialDuration ?? 30).toString();
      if (widget.initialNotes != null) {
        _notesController.text = widget.initialNotes!;
      }
    }

    _recomputeCaloriesEstimate();
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  void _recomputeCaloriesEstimate() {
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration > 0) {
      final estimate = PhysicalActivity.calculateEstimatedCalories(
        type: _selectedType,
        durationMinutes: duration,
        intensity: _selectedIntensity,
      );
      setState(() {
        _suggestedCalories = estimate;
      });
    } else {
      setState(() {
        _suggestedCalories = null;
      });
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5), // Permet de programmer des séances futures
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }

  void _applySuggestedCalories() {
    if (_suggestedCalories != null) {
      setState(() {
        _caloriesController.text = _suggestedCalories.toString();
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final duration = int.parse(_durationController.text.trim());
      final distanceText = _distanceController.text.trim();
      final double? distance = distanceText.isNotEmpty
          ? double.tryParse(distanceText.replaceAll(',', '.'))
          : null;
      final notesText = _notesController.text.trim();
      final caloriesText = _caloriesController.text.trim();
      final int? calories = caloriesText.isNotEmpty
          ? int.tryParse(caloriesText)
          : _suggestedCalories;

      // Résolution du userId effectif
      final effectiveUserId = widget.userId ??
          widget.activityToEdit?.userId ??
          Session.instance.user?.id;

      final activity = PhysicalActivity(
        id: widget.activityToEdit?.id,
        userId: effectiveUserId,
        type: _selectedType,
        durationMinutes: duration,
        distanceKm: distance,
        intensity: _selectedIntensity,
        activityDate: _selectedDate,
        notes: notesText.isNotEmpty ? notesText : null,
        caloriesBurned: calories,
      );

      bool reminderScheduled = false;

      if (_isEditMode) {
        await _activityService.update(activity);
        if (activity.id != null) {
          // Annule l'ancienne notification et replanifie si la séance est toujours dans le futur
          await _reminderService.cancelReminderForActivity(activity.id!);
          reminderScheduled =
              await _reminderService.scheduleReminderForActivity(activity);
        }
      } else {
        final created = await _activityService.create(activity);
        // Programme automatiquement un rappel 5 minutes avant la séance si elle est dans le futur
        reminderScheduled =
            await _reminderService.scheduleReminderForActivity(created);
      }

      if (!mounted) return;

      final String message;
      if (_isEditMode) {
        message = reminderScheduled
            ? 'Activity updated. Reminder set 5 min before!'
            : 'Activity updated successfully';
      } else {
        message = reminderScheduled
            ? 'Activity saved. Reminder set 5 min before!'
            : 'Activity saved successfully';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              if (reminderScheduled) ...[
                const Icon(Icons.notifications_active_rounded,
                    color: Colors.white, size: 20),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: const Color(0xFF0B6B5D),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving activity: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const kPrimaryGreen = Color(0xFF0B6B5D);
    const kNavy = Color(0xFF0A2540);

    final formattedDate =
        '${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.year}';
    final formattedTime =
        '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit Activity' : 'New Workout',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.2,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: const Color(0xFFE2E8F0),
            height: 1,
          ),
        ),
      ),
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // SECTION 1 : Type d'activité & Planification
                _buildFormCard(
                  title: 'Activity & Schedule',
                  icon: Icons.directions_run_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Activity type *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _activityTypes.map((t) {
                          final isSelected = _selectedType == t.$1;
                          return ChoiceChip(
                            avatar: Icon(
                              t.$2,
                              size: 17,
                              color: isSelected ? Colors.white : kPrimaryGreen,
                            ),
                            label: Text(t.$1),
                            selected: isSelected,
                            selectedColor: kPrimaryGreen,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : kNavy,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 12.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: isSelected ? kPrimaryGreen : const Color(0xFFCBD5E1),
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (val) {
                              if (val) {
                                setState(() => _selectedType = t.$1);
                                _recomputeCaloriesEstimate();
                              }
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Date and time *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: InkWell(
                              onTap: _pickDate,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded,
                                        color: kPrimaryGreen, size: 17),
                                    const SizedBox(width: 8),
                                    Text(
                                      formattedDate,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: kNavy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 2,
                            child: InkWell(
                              onTap: _pickTime,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFCBD5E1)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.access_time_rounded,
                                        color: kPrimaryGreen, size: 17),
                                    const SizedBox(width: 6),
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(
                                        fontSize: 13.5,
                                        color: kNavy,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const Spacer(),
                                    Icon(Icons.arrow_drop_down, color: Colors.grey.shade600),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (_selectedDate.isAfter(DateTime.now())) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                          decoration: BoxDecoration(
                            color: kPrimaryGreen.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: kPrimaryGreen.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.notifications_active_rounded,
                                color: kPrimaryGreen,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Smart Reminder: notification 5 min before (${_selectedDate.subtract(const Duration(minutes: 5)).hour.toString().padLeft(2, '0')}:${_selectedDate.subtract(const Duration(minutes: 5)).minute.toString().padLeft(2, '0')}).',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: kNavy,
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

                const SizedBox(height: 16),

                // SECTION 2 : Métriques & Effort
                _buildFormCard(
                  title: 'Workout Metrics',
                  icon: Icons.speed_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Duration *',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _durationController,
                                  keyboardType: TextInputType.number,
                                  decoration: _inputDecoration(
                                    hint: 'e.g. 45',
                                    icon: Icons.timer_outlined,
                                    suffixText: 'min',
                                  ),
                                  onChanged: (_) => _recomputeCaloriesEstimate(),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = int.tryParse(value.trim());
                                    if (parsed == null || parsed <= 0) {
                                      return '> 0 min';
                                    }
                                    if (parsed > 1440) {
                                      return 'Max 24h';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Distance',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: kNavy,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                TextFormField(
                                  controller: _distanceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: _inputDecoration(
                                    hint: 'e.g. 5.5',
                                    icon: Icons.route_outlined,
                                    suffixText: 'km',
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) return null;
                                    final parsed = double.tryParse(value.trim().replaceAll(',', '.'));
                                    if (parsed == null || parsed < 0) {
                                      return 'Invalid';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Effort intensity *',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: kNavy,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _intensities.map((item) {
                          final isSelected = _selectedIntensity == item.$1;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 3),
                              child: ChoiceChip(
                                label: Center(
                                  child: Text(
                                    item.$1,
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : item.$2,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: item.$2,
                                backgroundColor: item.$2.withValues(alpha: 0.08),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  side: BorderSide(
                                    color: isSelected ? item.$2 : item.$2.withValues(alpha: 0.25),
                                  ),
                                ),
                                showCheckmark: false,
                                onSelected: (val) {
                                  if (val) {
                                    setState(() => _selectedIntensity = item.$1);
                                    _recomputeCaloriesEstimate();
                                  }
                                },
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Calories burned',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kNavy,
                            ),
                          ),
                          if (_suggestedCalories != null)
                            InkWell(
                              borderRadius: BorderRadius.circular(6),
                              onTap: _applySuggestedCalories,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.auto_awesome_rounded,
                                        size: 13, color: Color(0xFFEA580C)),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Suggested: ~$_suggestedCalories kcal',
                                      style: const TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFEA580C),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        decoration: _inputDecoration(
                          hint: _suggestedCalories != null
                              ? 'e.g. $_suggestedCalories'
                              : 'e.g. 250',
                          icon: Icons.local_fire_department_rounded,
                          suffixText: 'kcal',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) return null;
                          final parsed = int.tryParse(value.trim());
                          if (parsed == null || parsed < 0) {
                            return 'Invalid calorie amount';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // SECTION 3 : Notes / Sensations
                _buildFormCard(
                  title: 'Notes & Sensations',
                  icon: Icons.notes_rounded,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _notesController,
                        maxLines: 3,
                        decoration: _inputDecoration(
                          hint: 'Feelings, route, breathing, effort...',
                          icon: Icons.edit_note_rounded,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Boutons d'action
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditMode ? 'Save changes' : 'Log workout',
                          style: const TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 14)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    const kNavy = Color(0xFF0A2540);
    const kPrimaryGreen = Color(0xFF0B6B5D);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: kPrimaryGreen),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: kNavy,
                  letterSpacing: -0.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    String? suffixText,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.5),
      prefixIcon: Icon(icon, color: const Color(0xFF0B6B5D), size: 20),
      suffixText: suffixText,
      suffixStyle: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Color(0xFF0A2540),
        fontSize: 13,
      ),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B6B5D), width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }
}
