import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../services/appointment_provider.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);
const _kBackground = Color(0xFFF8F7FF);

class AppointmentFormScreen extends StatefulWidget {
  final Appointment? appointment;

  const AppointmentFormScreen({super.key, this.appointment});

  @override
  State<AppointmentFormScreen> createState() => _AppointmentFormScreenState();
}

class _AppointmentFormScreenState extends State<AppointmentFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late int? _practitionerId;
  late int? _facilityId;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late int _durationMinutes;
  late String _modality;
  late AppointmentStatus _status;

  final _reasonCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _videoUrlCtrl = TextEditingController();
  final _scrollController = ScrollController();

  bool _isSaving = false;

  bool get _isEdit => widget.appointment != null;

  @override
  void initState() {
    super.initState();
    final a = widget.appointment;
    if (a != null) {
      _practitionerId = a.practitionerId;
      _facilityId = a.facilityId;
      _selectedDate = a.startDateTime;
      _selectedTime = TimeOfDay.fromDateTime(a.startDateTime);
      _durationMinutes = a.durationMinutes;
      _modality = a.modality;
      _status = a.status;
      _reasonCtrl.text = a.reason;
      _notesCtrl.text = a.notes ?? '';
      _videoUrlCtrl.text = a.videoUrl ?? '';
    } else {
      _practitionerId = null;
      _facilityId = null;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      _selectedDate = DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 10, 0);
      _selectedTime = const TimeOfDay(hour: 10, minute: 0);
      _durationMinutes = 30;
      _modality = 'presentiel';
      _status = AppointmentStatus.SCHEDULED;
    }
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _notesCtrl.dispose();
    _videoUrlCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_practitionerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner un praticien')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final startDateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );

    final provider = context.read<AppointmentProvider>();
    final practitioners = provider.practitioners;
    final facilities = provider.facilities;

    final appointmentToSave = Appointment(
      id: widget.appointment?.id,
      practitionerId: _practitionerId!,
      facilityId: _modality == 'presentiel' ? _facilityId : null,
      startDateTime: startDateTime,
      durationMinutes: _durationMinutes,
      reason: _reasonCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      modality: _modality,
      videoUrl: _modality == 'teleconsultation' && _videoUrlCtrl.text.trim().isNotEmpty
          ? _videoUrlCtrl.text.trim()
          : null,
      status: _status,
      practitioner: practitioners.isNotEmpty
          ? practitioners.firstWhere(
              (p) => p.id == _practitionerId,
              orElse: () => practitioners.first,
            )
          : null,
      facility: _facilityId != null && facilities.isNotEmpty
          ? facilities.firstWhere(
              (f) => f.id == _facilityId,
              orElse: () => facilities.first,
            )
          : null,
    );

    bool success;
    if (_isEdit) {
      success = await provider.updateAppointment(appointmentToSave);
    } else {
      success = await provider.addAppointment(appointmentToSave);
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Rendez-vous mis à jour' : 'Rendez-vous enregistré'),
          backgroundColor: _kGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Une erreur est survenue'),
          backgroundColor: const Color(0xFFD32F2F),
        ),
      );
    }
  }

  InputDecoration _inputDeco(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _kGreen),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _kGreen, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppointmentProvider>();
    final practitioners = provider.practitioners;
    final facilities = provider.facilities;

    // Définir praticien par défaut si non sélectionné et liste non vide
    if (_practitionerId == null && practitioners.isNotEmpty) {
      _practitionerId = practitioners.first.id;
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Modifier le rendez-vous' : 'Nouveau rendez-vous',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: _kNavy,
        elevation: 0,
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          thumbVisibility: true,
          interactive: true,
          thickness: 6,
          radius: const Radius.circular(8),
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------------------------------------------------------
                  // MODALITÉ : Présentiel vs Téléconsultation
                  // ---------------------------------------------------------------
                  const Text(
                    'Modalité de consultation',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ChoiceChip(
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.person_outline, size: 18),
                                SizedBox(width: 6),
                                Text('Présentiel'),
                              ],
                            ),
                          ),
                          selected: _modality == 'presentiel',
                          selectedColor: _kGreen.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: _modality == 'presentiel' ? _kGreen : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _modality = 'presentiel');
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ChoiceChip(
                          label: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.videocam_outlined, size: 18),
                                SizedBox(width: 6),
                                Text('Téléconsultation'),
                              ],
                            ),
                          ),
                          selected: _modality == 'teleconsultation',
                          selectedColor: Colors.purple.shade50,
                          labelStyle: TextStyle(
                            color: _modality == 'teleconsultation'
                                ? Colors.purple.shade800
                                : Colors.grey.shade700,
                          ),
                          onSelected: (val) {
                            if (val) setState(() => _modality = 'teleconsultation');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ---------------------------------------------------------------
                  // PRATICIEN
                  // ---------------------------------------------------------------
                  const Text(
                    'Praticien',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _practitionerId,
                    isExpanded: true,
                    decoration: _inputDeco('Sélectionner un médecin', Icons.medical_services_outlined),
                    items: practitioners.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(
                          '${p.fullName} (${p.specialty})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _practitionerId = val),
                    validator: (val) => val == null ? 'Veuillez choisir un praticien' : null,
                  ),
                  const SizedBox(height: 20),

                  // ---------------------------------------------------------------
                  // STRUCTURE / LIEU (si présentiel)
                  // ---------------------------------------------------------------
                  if (_modality == 'presentiel') ...[
                    const Text(
                      'Structure de santé (Lieu)',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: _facilityId,
                      isExpanded: true,
                      decoration: _inputDeco('Lieu de consultation (optionnel)', Icons.location_on_outlined),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Aucun lieu spécifique', overflow: TextOverflow.ellipsis),
                        ),
                        ...facilities.map((f) {
                          return DropdownMenuItem<int?>(
                            value: f.id,
                            child: Text(
                              '${f.name} - ${f.type}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }),
                      ],
                      onChanged: (val) => setState(() => _facilityId = val),
                    ),
                    const SizedBox(height: 20),
                  ],

              // ---------------------------------------------------------------
              // LIEN VISIO (si téléconsultation)
              // ---------------------------------------------------------------
              if (_modality == 'teleconsultation') ...[
                const Text(
                  'Lien de la visioconférence',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _videoUrlCtrl,
                  decoration: _inputDeco('https://meet.jit.si/... ou Zoom', Icons.link_rounded),
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 20),
              ],

              // ---------------------------------------------------------------
              // DATE & HEURE
              // ---------------------------------------------------------------
              const Text(
                'Date & Heure',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 20, color: _kGreen),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: _kNavy),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InkWell(
                      onTap: _pickTime,
                      borderRadius: BorderRadius.circular(14),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.access_time_rounded, size: 20, color: _kGreen),
                            const SizedBox(width: 10),
                            Text(
                              '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                              style: const TextStyle(fontWeight: FontWeight.w600, color: _kNavy),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // DURÉE
              // ---------------------------------------------------------------
              const Text(
                'Durée prévue',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: [15, 30, 45, 60].map((dur) {
                  final isSelected = _durationMinutes == dur;
                  return ChoiceChip(
                    label: Text('$dur min'),
                    selected: isSelected,
                    selectedColor: _kGreen.withValues(alpha: 0.15),
                    labelStyle: TextStyle(
                      color: isSelected ? _kGreen : Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _durationMinutes = dur);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // MOTIF DU RENDEZ-VOUS
              // ---------------------------------------------------------------
              const Text(
                'Motif du rendez-vous',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _reasonCtrl,
                decoration: _inputDeco('Ex : Consultation de suivi, Bilan annuel...', Icons.edit_note_rounded),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Veuillez renseigner le motif du rendez-vous';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ---------------------------------------------------------------
              // STATUT (uniquement en édition)
              // ---------------------------------------------------------------
              if (_isEdit) ...[
                const Text(
                  'Statut',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<AppointmentStatus>(
                  initialValue: _status,
                  decoration: _inputDeco('Statut actuel', Icons.flag_outlined),
                  items: AppointmentStatus.values.map((s) {
                    return DropdownMenuItem<AppointmentStatus>(
                      value: s,
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 8),
                          Text(s.labelFr),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _status = val);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // ---------------------------------------------------------------
              // NOTES COMPLÉMENTAIRES
              // ---------------------------------------------------------------
              const Text(
                'Notes & Instructions (optionnel)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _kNavy),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Ex : Être à jeun, apporter les analyses sanguines...',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.grey.shade200),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _kGreen, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ---------------------------------------------------------------
              // BOUTON ENREGISTRER
              // ---------------------------------------------------------------
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _kGreen,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(
                          _isEdit ? 'Mettre à jour le rendez-vous' : 'Enregistrer le rendez-vous',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    ),
  ),
);
}
}
