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
          _isEditMode ? 'Edit Activity' : 'New Activity',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: kNavy,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFFF8F7FF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Type d'activité (Chips visuels)
                const Text(
                  'Activity type *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _activityTypes.map((t) {
                    final isSelected = _selectedType == t.$1;
                    return ChoiceChip(
                      avatar: Icon(
                        t.$2,
                        size: 18,
                        color: isSelected ? Colors.white : kPrimaryGreen,
                      ),
                      label: Text(t.$1),
                      selected: isSelected,
                      selectedColor: kPrimaryGreen,
                      backgroundColor: Colors.white,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : kNavy,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: isSelected ? kPrimaryGreen : Colors.grey.shade300,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) {
                          setState(() => _selectedType = t.$1);
                          _recomputeCaloriesEstimate();
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // 2. Date et Heure de l'activité
                const Text(
                  'Session date and time *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  color: kPrimaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                formattedDate,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: kNavy,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded,
                                  color: kPrimaryGreen, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                formattedTime,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  color: kNavy,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_drop_down, color: Colors.grey),
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
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: kPrimaryGreen.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: kPrimaryGreen.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_rounded,
                          color: kPrimaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Upcoming session: a notification will be sent 5 min before (${_selectedDate.subtract(const Duration(minutes: 5)).hour.toString().padLeft(2, '0')}:${_selectedDate.subtract(const Duration(minutes: 5)).minute.toString().padLeft(2, '0')}).',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: kNavy,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // 3. Durée et Intensité
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                return 'Duration is required';
                              }
                              final parsed = int.tryParse(value.trim());
                              if (parsed == null || parsed <= 0) {
                                return '> 0 min';
                              }
                              if (parsed > 1440) {
                                return 'Max 1440 min (24h)';
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
                            'Distance (optional)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: kNavy,
                            ),
                          ),
                          const SizedBox(height: 8),
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
                                return 'Invalid distance';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Intensité (ChoiceChips colorés)
                const Text(
                  'Effort intensity *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: _intensities.map((item) {
                    final isSelected = _selectedIntensity == item.$1;
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: Center(
                            child: Text(
                              item.$1,
                              style: TextStyle(
                                color: isSelected ? Colors.white : item.$2,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          selected: isSelected,
                          selectedColor: item.$2,
                          backgroundColor: item.$2.withValues(alpha: 0.08),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? item.$2 : item.$2.withValues(alpha: 0.3),
                            ),
                          ),
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
                const SizedBox(height: 20),

                // 5. Calories brûlées (avec suggestion auto)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Calories burned (kcal)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: kNavy,
                      ),
                    ),
                    if (_suggestedCalories != null)
                      TextButton.icon(
                        onPressed: _applySuggestedCalories,
                        icon: const Icon(Icons.auto_awesome, size: 14, color: Color(0xFFEF6C00)),
                        label: Text(
                          'Suggested: ~$_suggestedCalories kcal',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFEF6C00),
                          ),
                        ),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: _suggestedCalories != null ? 'e.g. $_suggestedCalories' : 'e.g. 250',
                    icon: Icons.local_fire_department_outlined,
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
                const SizedBox(height: 20),

                // 6. Notes
                const Text(
                  'Notes / Sensations (optional)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notesController,
                  maxLines: 3,
                  decoration: _inputDecoration(
                    hint: 'Feelings, route, breathing, effort...',
                    icon: Icons.edit_note_rounded,
                  ),
                ),
                const SizedBox(height: 30),

                // Boutons d'action
                ElevatedButton(
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 1,
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
                          _isEditMode ? 'Save changes' : 'Add activity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
        ),
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
      prefixIcon: Icon(icon, color: const Color(0xFF0B6B5D)),
      suffixText: suffixText,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0B6B5D), width: 1.8),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.2),
      ),
    );
  }
}
