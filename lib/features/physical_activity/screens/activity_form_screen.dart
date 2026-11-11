import 'package:flutter/material.dart';
import '../models/physical_activity.dart';
import '../services/activity_service.dart';

class ActivityFormScreen extends StatefulWidget {
  final PhysicalActivity? activityToEdit;
  final int? userId;

  const ActivityFormScreen({
    super.key,
    this.activityToEdit,
    this.userId,
  });

  @override
  State<ActivityFormScreen> createState() => _ActivityFormScreenState();
}

class _ActivityFormScreenState extends State<ActivityFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _activityService = ActivityService();

  late String _selectedType;
  late String _selectedIntensity;
  late DateTime _selectedDate;

  final _durationController = TextEditingController();
  final _distanceController = TextEditingController();
  final _notesController = TextEditingController();
  final _caloriesController = TextEditingController();

  bool _isSaving = false;

  final List<String> _activityTypes = const [
    'Walking',
    'Running',
    'Cycling',
    'Swimming',
    'Other',
  ];

  final List<String> _intensities = const [
    'Low',
    'Moderate',
    'High',
  ];

  bool get _isEditMode => widget.activityToEdit != null;

  @override
  void initState() {
    super.initState();
    final item = widget.activityToEdit;

    if (item != null) {
      _selectedType = _activityTypes.contains(item.type) ? item.type : 'Other';
      _selectedIntensity = _intensities.contains(item.intensity)
          ? item.intensity
          : 'Moderate';
      _selectedDate = item.activityDate;
      _durationController.text = item.durationMinutes.toString();
      _distanceController.text =
          item.distanceKm != null ? item.distanceKm.toString() : '';
      _notesController.text = item.notes ?? '';
      _caloriesController.text =
          item.caloriesBurned != null ? item.caloriesBurned.toString() : '';
    } else {
      _selectedType = 'Running';
      _selectedIntensity = 'Moderate';
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _distanceController.dispose();
    _notesController.dispose();
    _caloriesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
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
      final int? calories =
          caloriesText.isNotEmpty ? int.tryParse(caloriesText) : null;

      final activity = PhysicalActivity(
        id: widget.activityToEdit?.id,
        userId: widget.userId ?? widget.activityToEdit?.userId,
        type: _selectedType,
        durationMinutes: duration,
        distanceKm: distance,
        intensity: _selectedIntensity,
        activityDate: _selectedDate,
        notes: notesText.isNotEmpty ? notesText : null,
        caloriesBurned: calories,
      );

      if (_isEditMode) {
        await _activityService.update(activity);
      } else {
        await _activityService.create(activity);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditMode
              ? 'Activity updated successfully'
              : 'Activity added successfully'),
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
          content: Text('Error while saving: $e'),
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
        '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Edit activity' : 'New activity',
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
                // 1. Type d'activité (obligatoire)
                const Text(
                  'Activity type *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedType,
                  decoration: _inputDecoration(
                    hint: 'Select an activity',
                    icon: Icons.sports_score_rounded,
                  ),
                  items: _activityTypes.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
                const SizedBox(height: 18),

                // 2. Date de l'activité (obligatoire)
                const Text(
                  'Activity date *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            color: kPrimaryGreen, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 15,
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
                const SizedBox(height: 18),

                // 3. Durée en minutes (obligatoire, entier > 0)
                const Text(
                  'Duration (in minutes) *',
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
                    hint: 'E.g.: 45',
                    icon: Icons.timer_outlined,
                    suffixText: 'min',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Duration is required';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed <= 0) {
                      return 'Please enter an integer greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 4. Distance en kilomètres (facultative)
                const Text(
                  'Distance (in km) — Optional',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _distanceController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: _inputDecoration(
                    hint: 'E.g.: 5.5',
                    icon: Icons.route_outlined,
                    suffixText: 'km',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed =
                        double.tryParse(value.trim().replaceAll(',', '.'));
                    if (parsed == null || parsed < 0) {
                      return 'Please enter a valid positive distance';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 5. Intensité (obligatoire : Faible, Modérée, Élevée)
                const Text(
                  'Intensity *',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedIntensity,
                  decoration: _inputDecoration(
                    hint: 'Select an intensity',
                    icon: Icons.speed_rounded,
                  ),
                  items: _intensities.map((intensity) {
                    return DropdownMenuItem(
                      value: intensity,
                      child: Text(intensity),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedIntensity = val);
                    }
                  },
                ),
                const SizedBox(height: 18),

                // 6. Calories (facultatif, saisie libre par l'utilisateur)
                const Text(
                  'Calories burned (kcal) — Optional',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kNavy,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _caloriesController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    hint: 'E.g.: 250',
                    icon: Icons.local_fire_department_outlined,
                    suffixText: 'kcal',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) return null;
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null || parsed < 0) {
                      return 'Please enter a valid integer number of calories';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // 7. Notes (facultatives)
                const Text(
                  'Notes / Remarks — Optional',
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
                    hint: 'Feelings, weather, route...',
                    icon: Icons.edit_note_rounded,
                  ),
                ),
                const SizedBox(height: 30),

                // Boutons d'action : Enregistrer et Annuler
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
                          _isEditMode
                              ? 'Save changes'
                              : 'Add activity',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed:
                      _isSaving ? null : () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 15),
                  ),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
