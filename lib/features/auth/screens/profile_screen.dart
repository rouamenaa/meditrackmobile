import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:meditrackmobile/features/profile/services/medical_report_service.dart';
import '../../appointments/models/appointment.dart';
import '../../appointments/services/appointment_provider.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import 'edit_profile_screen.dart';
import 'login_screen.dart';

const _kCardBg = Color(0xFFEDEFFD);
const _kFieldBg = Color(0xFFEEF0FC);
const _kEmergencyBg = Color(0xFFFFE3E0);
const _kEmergencyText = Color(0xFFB3261E);
const _kShadow = Color(0x12000000);

const _months = [
  'January', 'February', 'March', 'April', 'May', 'June', 'July',
  'August', 'September', 'October', 'November', 'December'
];

class ProfileScreen extends StatefulWidget {
  final User user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _repo = UserRepository();

  late User _user;
  bool _loading = true;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
    _load();
  }

  // Recharge le profil depuis le serveur (copie locale si hors ligne)
  Future<void> _load() async {
    try {
      final fresh = await _repo.fetchProfile();
      if (!mounted) return;
      setState(() {
        _user = fresh;
        _loading = false;
      });
    } on ApiException {
      await _repo.invalidateSession();
      await _returnToLogin();
    }
  }

  Future<void> _logout() async {
    await _repo.logout();
    await _returnToLogin();
  }

  Future<void> _returnToLogin() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // Change la photo de profil : sélection dans la galerie puis upload serveur.
  Future<void> _changePhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1080,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final updated = await _repo.uploadPhoto(picked.path);
      if (!mounted) return;
      setState(() {
        _user = updated;
        _uploadingPhoto = false;
      });
      _snack('Photo updated');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      _snack(e.message);
    }
  }

  // Édition du profil : renvoie l'utilisateur mis à jour.
  Future<void> _editProfile() async {
    final updated = await Navigator.of(context).push<User>(
      MaterialPageRoute(builder: (_) => EditProfileScreen(user: _user)),
    );
    if (updated != null && mounted) {
      setState(() => _user = updated);
    }
  }

  // Export PDF du dossier médical.
  Future<void> _exportPdf() async {
    try {
      await MedicalReportService.exportPdf(_user);
    } catch (e) {
      if (!mounted) return;
      _snack('Export failed: $e');
    }
  }

  String _formatDate(User u) {
    final d = DateTime.tryParse(u.dateNaissance ?? '');
    if (d == null) return 'Not set';
    return '${_months[d.month - 1]} ${d.day}, ${d.year} (${u.age} yrs)';
  }

  String _initials(User u) {
    final p = u.prenom.isNotEmpty ? u.prenom[0] : '';
    final n = u.nom.isNotEmpty ? u.nom[0] : '';
    return (p + n).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final u = _user;
    final isMedecin = u.isMedecin;
    final doctorAppointments = isMedecin
        ? context.watch<AppointmentProvider>().appointmentsForDoctor(u)
        : const <Appointment>[];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: kNavy,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: kGreen, borderRadius: BorderRadius.circular(8)),
              child: const Icon(Icons.add, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            16 + MediaQuery.of(context).padding.bottom + 24,
          ),
          children: [
            _buildHeader(u),
            const SizedBox(height: 16),
            if (isMedecin) ...[
              _buildProfessionalInfo(u),
              const SizedBox(height: 16),
              _buildDoctorContact(u),
              const SizedBox(height: 16),
              _buildPracticeStats(doctorAppointments),
            ] else ...[
              _buildPersonalDetails(u),
              const SizedBox(height: 16),
              _buildCare(u),
            ],
            const SizedBox(height: 20),
            _buildButtons(u),
          ],
        ),
      ),
    );
  }

  // ---------------- En-tête : photo, nom, ID, groupe sanguin ----------------
  Widget _buildHeader(User u) {
    final hasPhoto = u.photoUrl != null;
    final health = [
      if (u.groupeSanguin != null && u.groupeSanguin!.isNotEmpty)
        u.groupeSanguin!,
      if (u.conditionMedicale != null && u.conditionMedicale!.isNotEmpty)
        u.conditionMedicale!,
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
          color: _kCardBg, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 46,
                backgroundColor: const Color(0xFFD5E7E4),
                backgroundImage:
                hasPhoto ? NetworkImage(u.photoUrl!) : null,
                child: hasPhoto
                    ? null
                    : Text(_initials(u),
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: kGreen)),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: GestureDetector(
                  onTap: _uploadingPhoto ? null : _changePhoto,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: kGreen,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2)),
                    child: _uploadingPhoto
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Icon(Icons.photo_camera,
                            size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(u.fullName,
              style: const TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, color: kNavy)),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              // Rôle de l'utilisateur
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: u.isMedecin
                        ? const Color(0xFFD5E7E4)
                        : const Color(0xFFE6E9FB),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                        u.isMedecin
                            ? Icons.medical_services_outlined
                            : Icons.personal_injury_outlined,
                        size: 15,
                        color: kGreen),
                    const SizedBox(width: 6),
                    Text(u.roleLabel,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: kGreen)),
                  ],
                ),
              ),
              // Identifiant MediTrack
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: const Color(0xFFD9E3F5),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_user_outlined,
                        size: 15, color: Color(0xFF3B4A6B)),
                    const SizedBox(width: 6),
                    Text('MediTrack ID: ${u.meditrackId}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF3B4A6B))),
                  ],
                ),
              ),
            ],
          ),
          if (health.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                  color: const Color(0xFFFFD9D5),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emergency,
                      size: 15, color: _kEmergencyText),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(health,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: _kEmergencyText)),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ---------------- Personal Details ----------------
  Widget _buildPersonalDetails(User u) {
    final hasEmergency = (u.contactUrgenceNom ?? '').isNotEmpty;
    final emergencyName = hasEmergency
        ? '${u.contactUrgenceNom}'
        '${(u.contactUrgenceLien ?? '').isNotEmpty ? ' (${u.contactUrgenceLien})' : ''}'
        : 'Not set';

    return _SectionCard(
      title: 'Personal Details',
      icon: Icons.assignment_ind_outlined,
      iconColor: kGreen,
      children: [
        _Field(
            label: 'Full Name', icon: Icons.person_outline, value: u.fullName),
        _Field(
          label: 'Email Address',
          icon: Icons.mail_outline,
          value: u.email,
          trailing:
          const Icon(Icons.check_circle_outline, color: kGreen, size: 22),
        ),
        _Field(
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          value: (u.telephone ?? '').isEmpty ? 'Not set' : u.telephone!,
        ),
        _Field(
          label: 'Date of Birth',
          icon: Icons.calendar_today_outlined,
          value: _formatDate(u),
        ),
        const Text('Emergency Contact',
            style: TextStyle(
                color: _kEmergencyText,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _kEmergencyBg, borderRadius: BorderRadius.circular(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.contact_phone_outlined,
                  color: _kEmergencyText, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(emergencyName,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    if ((u.contactUrgenceTel ?? '').isNotEmpty)
                      Text(u.contactUrgenceTel!,
                          style: const TextStyle(fontSize: 16)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Care & Coverage ----------------
  Widget _buildCare(User u) {
    final hasInsurance = (u.assuranceNom ?? '').isNotEmpty;

    return _SectionCard(
      title: 'Care & Coverage',
      icon: Icons.health_and_safety,
      iconColor: const Color(0xFF1B4FBF),
      children: [
        _InfoTile(
          icon: Icons.account_balance_outlined,
          iconBg: const Color(0xFFD9E3F5),
          iconColor: const Color(0xFF1B4FBF),
          small: 'Insurance Provider',
          lines: hasInsurance
              ? [
            _Line(u.assuranceNom!, bold: true),
            if ((u.assurancePolice ?? '').isNotEmpty)
              _Line('Policy #${u.assurancePolice}'),
          ]
              : [_Line('Not set', bold: true)],
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.medical_services_outlined,
          iconBg: const Color(0xFFD5E7E4),
          iconColor: kGreen,
          small: 'Primary Care Physicians',
          lines: u.medecins.isEmpty
              ? [_Line('Not set', bold: true)]
              : [
            for (final m in u.medecins) ...[
              _Line(m.nom, bold: true),
              _Line(m.specialite),
            ]
          ],
        ),
      ],
    );
  }

  // ---------------- Professional Information (médecin) ----------------
  Widget _buildProfessionalInfo(User u) {
    String orNotSet(String? value) =>
        (value == null || value.trim().isEmpty) ? 'Not set' : value.trim();

    return _SectionCard(
      title: 'Professional Information',
      icon: Icons.medical_services_outlined,
      iconColor: kGreen,
      children: [
        _InfoTile(
          icon: Icons.local_hospital_outlined,
          iconBg: const Color(0xFFD5E7E4),
          iconColor: kGreen,
          small: 'Specialty',
          lines: [_Line(orNotSet(u.specialite), bold: true)],
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.badge_outlined,
          iconBg: const Color(0xFFD9E3F5),
          iconColor: const Color(0xFF1B4FBF),
          small: 'RPPS / ADELI Number',
          lines: [_Line(orNotSet(u.rppsAdeli), bold: true)],
        ),
        const SizedBox(height: 12),
        _InfoTile(
          icon: Icons.apartment_outlined,
          iconBg: const Color(0xFFE6E9FB),
          iconColor: const Color(0xFF3B4A6B),
          small: 'Practice / Establishment',
          lines: [_Line(orNotSet(u.etablissement), bold: true)],
        ),
      ],
    );
  }

  // ---------------- Contact & Availability (médecin) ----------------
  Widget _buildDoctorContact(User u) {
    final hours = (u.horairesConsultation ?? '').trim();
    return _SectionCard(
      title: 'Contact & Availability',
      icon: Icons.contact_mail_outlined,
      iconColor: const Color(0xFF1B4FBF),
      children: [
        _Field(
          label: 'Email Address',
          icon: Icons.mail_outline,
          value: u.email,
          trailing:
              const Icon(Icons.check_circle_outline, color: kGreen, size: 22),
        ),
        _Field(
          label: 'Phone Number',
          icon: Icons.phone_outlined,
          value: (u.telephone ?? '').isEmpty ? 'Not set' : u.telephone!,
        ),
        const Text('Consultation Hours',
            style: TextStyle(
                color: kNavy, fontWeight: FontWeight.w700, fontSize: 13)),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: _kFieldBg, borderRadius: BorderRadius.circular(10)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.schedule_outlined, color: kNavy, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hours.isEmpty ? 'Not set' : hours,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------- Practice Statistics (médecin) ----------------
  Widget _buildPracticeStats(List<Appointment> appointments) {
    final now = DateTime.now();
    final today = appointments.where((a) {
      final d = a.startDateTime;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).length;
    final upcoming =
        appointments.where((a) => a.startDateTime.isAfter(now)).length;
    final completed = appointments.where((a) => a.isPast).length;

    return _SectionCard(
      title: 'Practice Statistics',
      icon: Icons.insights_rounded,
      iconColor: kGreen,
      children: [
        Row(
          children: [
            Expanded(child: _StatBox(label: 'Today', value: today)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Upcoming', value: upcoming)),
            const SizedBox(width: 10),
            Expanded(child: _StatBox(label: 'Past', value: completed)),
          ],
        ),
      ],
    );
  }

  // ---------------- Boutons ----------------
  Widget _buildButtons(User u) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: _editProfile,
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit Profile',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: kGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        if (!u.isMedecin) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: _exportPdf,
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text('Medical Records & Export PDF',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDDE4FA),
                foregroundColor: kNavy,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
        const SizedBox(height: 6),
        TextButton.icon(
          onPressed: _logout,
          icon: Icon(Icons.logout, size: 18, color: Colors.grey.shade700),
          label: Text('Log out',
              style: TextStyle(color: Colors.grey.shade700, fontSize: 16)),
        ),
      ],
    );
  }
}

// ======================= Petits widgets réutilisables =======================

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: _kShadow, blurRadius: 12, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: kNavy)),
              Icon(icon, color: iconColor),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  final Widget? trailing;

  const _Field({
    required this.label,
    required this.icon,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
          const SizedBox(height: 6),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
                color: _kFieldBg, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Icon(icon, size: 22, color: kNavy),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(value, style: const TextStyle(fontSize: 16)),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line {
  final String text;
  final bool bold;
  _Line(this.text, {this.bold = false});
}

class _StatBox extends StatelessWidget {
  final String label;
  final int value;

  const _StatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      decoration: BoxDecoration(
          color: _kFieldBg, borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: kGreen,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700)),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String small;
  final List<_Line> lines;

  const _InfoTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.small,
    required this.lines,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _kFieldBg, borderRadius: BorderRadius.circular(12)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(small,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700)),
                const SizedBox(height: 2),
                for (final l in lines)
                  Text(l.text,
                      style: TextStyle(
                          fontSize: l.bold ? 17 : 14,
                          fontWeight:
                          l.bold ? FontWeight.w700 : FontWeight.w400)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
