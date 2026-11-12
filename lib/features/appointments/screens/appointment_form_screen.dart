import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../auth/models/user.dart';
import '../models/appointment.dart';
import '../models/appointment_status.dart';
import '../models/practitioner.dart';
import '../services/appointment_provider.dart';

const _kGreen = Color(0xFF0B6B5D);
const _kNavy = Color(0xFF0A2540);
const _kBackground = Color(0xFFF8F7FF);

class AppointmentFormScreen extends StatefulWidget {
  final User user;
  final Appointment? appointment;

  const AppointmentFormScreen({
    super.key,
    required this.user,
    this.appointment,
  });

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
  bool _requestedPractitioners = false;

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
      _selectedDate = DateTime(
        tomorrow.year,
        tomorrow.month,
        tomorrow.day,
        10,
        0,
      );
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_requestedPractitioners) {
      _requestedPractitioners = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<AppointmentProvider>().loadAll(user: widget.user);
        }
      });
    }
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

    final provider = context.read<AppointmentProvider>();
    if (_practitionerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a registered doctor')),
      );
      return;
    }
    Practitioner? selectedDoctor;
    for (final doctor in provider.practitioners) {
      if (doctor.id == _practitionerId) {
        selectedDoctor = doctor;
        break;
      }
    }
    if (selectedDoctor?.remoteUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This doctor account is no longer available'),
        ),
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

    final practitioners = provider.practitioners;
    final facilities = provider.facilities;

    final appointmentToSave = Appointment(
      id: widget.appointment?.id,
      remoteId: widget.appointment?.remoteId,
      practitionerId: _practitionerId!,
      doctorUserId: selectedDoctor!.remoteUserId,
      facilityId: _modality == 'presentiel' ? _facilityId : null,
      facilityName: _modality == 'presentiel'
          ? (provider.facilities.any((f) => f.id == _facilityId)
                ? provider.facilities
                      .firstWhere((f) => f.id == _facilityId)
                      .name
                : null)
          : null,
      facilityAddress: _modality == 'presentiel'
          ? (provider.facilities.any((f) => f.id == _facilityId)
                ? provider.facilities
                      .firstWhere((f) => f.id == _facilityId)
                      .fullAddress
                : null)
          : null,
      // En édition, on conserve le patient d'origine ; en création, c'est
      // l'utilisateur connecté qui réserve le rendez-vous.
      patientId: widget.appointment?.patientId ?? widget.user.id,
      patientName: widget.appointment?.patientName ?? widget.user.fullName,
      startDateTime: startDateTime,
      durationMinutes: _durationMinutes,
      reason: _reasonCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      modality: _modality,
      videoUrl:
          _modality == 'teleconsultation' &&
              _videoUrlCtrl.text.trim().isNotEmpty
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
      success = await provider.updateAppointment(
        appointmentToSave,
        user: widget.user,
      );
    } else {
      success = await provider.addAppointment(
        appointmentToSave,
        user: widget.user,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Appointment updated' : 'Appointment saved'),
          backgroundColor: _kGreen,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'An error occurred'),
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
    final practitioners = provider.practitioners
        .where((p) => p.remoteUserId != null && p.remoteUserId!.isNotEmpty)
        .toList();
    final facilities = provider.facilities;

    if (_practitionerId != null &&
        !practitioners.any((p) => p.id == _practitionerId)) {
      _practitionerId = null;
    }
    if (_practitionerId == null && practitioners.isNotEmpty) {
      _practitionerId = practitioners.first.id;
    }

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Text(
          _isEdit ? 'Edit appointment' : 'New appointment',
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
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
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
                    'Consultation modality',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
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
                                Text('In-person'),
                              ],
                            ),
                          ),
                          selected: _modality == 'presentiel',
                          selectedColor: _kGreen.withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: _modality == 'presentiel'
                                ? _kGreen
                                : Colors.grey.shade700,
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
                                Text('Teleconsultation'),
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
                            if (val) {
                              setState(() => _modality = 'teleconsultation');
                            }
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
                    'Practitioner',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    initialValue: _practitionerId,
                    isExpanded: true,
                    decoration:
                        _inputDeco(
                          'Select a doctor',
                          Icons.medical_services_outlined,
                        ).copyWith(
                          helperText: provider.isLoading
                              ? 'Loading registered doctors...'
                              : practitioners.isEmpty
                              ? provider.errorMessage == null
                                    ? 'No verified doctor accounts are available'
                                    : 'Could not load the doctor list'
                              : null,
                        ),
                    items: practitioners.map((p) {
                      return DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(
                          '${p.fullName} (${p.specialty})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: practitioners.isEmpty
                        ? null
                        : (val) => setState(() => _practitionerId = val),
                    validator: (val) =>
                        val == null ? 'Please choose a practitioner' : null,
                  ),
                  if (practitioners.isEmpty &&
                      !provider.isLoading &&
                      provider.errorMessage != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () => provider.loadAll(user: widget.user),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ---------------------------------------------------------------
                  // STRUCTURE / LIEU (si présentiel)
                  // ---------------------------------------------------------------
                  if (_modality == 'presentiel') ...[
                    const Text(
                      'Health facility (Location)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int?>(
                      initialValue: _facilityId,
                      isExpanded: true,
                      decoration: _inputDeco(
                        'Consultation location (optional)',
                        Icons.location_on_outlined,
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text(
                            'No specific location',
                            overflow: TextOverflow.ellipsis,
                          ),
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
                      'Video conference link',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _videoUrlCtrl,
                      decoration: _inputDeco(
                        'https://meet.jit.si/... or Zoom',
                        Icons.link_rounded,
                      ),
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ---------------------------------------------------------------
                  // DATE & HEURE
                  // ---------------------------------------------------------------
                  const Text(
                    'Date & Time',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.calendar_today_rounded,
                                  size: 20,
                                  color: _kGreen,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${_selectedDate.day.toString().padLeft(2, '0')}/${_selectedDate.month.toString().padLeft(2, '0')}/${_selectedDate.year}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _kNavy,
                                  ),
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
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.access_time_rounded,
                                  size: 20,
                                  color: _kGreen,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: _kNavy,
                                  ),
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
                    'Planned duration',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
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
                    'Appointment reason',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _reasonCtrl,
                    decoration: _inputDeco(
                      'E.g.: Follow-up consultation, Annual checkup...',
                      Icons.edit_note_rounded,
                    ),
                    validator: (val) {
                      if (val == null || val.trim().isEmpty) {
                        return 'Please enter the appointment reason';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // ---------------------------------------------------------------
                  // STATUT (uniquement en édition)
                  // ---------------------------------------------------------------
                  if (_isEdit && widget.user.isMedecin) ...[
                    const Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _kNavy,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<AppointmentStatus>(
                      initialValue: _status,
                      decoration: _inputDeco(
                        'Current status',
                        Icons.flag_outlined,
                      ),
                      items: AppointmentStatus.values.map((s) {
                        return DropdownMenuItem<AppointmentStatus>(
                          value: s,
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: s.color,
                                  shape: BoxShape.circle,
                                ),
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
                    'Notes & Instructions (optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _kNavy,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'E.g.: Fasting required, bring blood test results...',
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: _isSaving ? null : _save,
                      child: _isSaving
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : Text(
                              _isEdit
                                  ? 'Update appointment'
                                  : 'Save appointment',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
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
