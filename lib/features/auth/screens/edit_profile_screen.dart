import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import 'login_screen.dart' show kGreen, kNavy, kBackground;

/// Édition des informations du profil (hors email, mot de passe et rôle).
class EditProfileScreen extends StatefulWidget {
  final User user;
  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = UserRepository();

  late final TextEditingController _prenomCtrl;
  late final TextEditingController _nomCtrl;
  late final TextEditingController _telCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _conditionCtrl;
  late final TextEditingController _urgenceNomCtrl;
  late final TextEditingController _urgenceLienCtrl;
  late final TextEditingController _urgenceTelCtrl;
  late final TextEditingController _assuranceNomCtrl;
  late final TextEditingController _assurancePoliceCtrl;

  String? _sexe;
  String? _groupeSanguin;
  bool _loading = false;

  static const _groupes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];

  @override
  void initState() {
    super.initState();
    final u = widget.user;
    _prenomCtrl = TextEditingController(text: u.prenom);
    _nomCtrl = TextEditingController(text: u.nom);
    _telCtrl = TextEditingController(text: u.telephone ?? '');
    _dateCtrl = TextEditingController(text: u.dateNaissance ?? '');
    _conditionCtrl = TextEditingController(text: u.conditionMedicale ?? '');
    _urgenceNomCtrl = TextEditingController(text: u.contactUrgenceNom ?? '');
    _urgenceLienCtrl = TextEditingController(text: u.contactUrgenceLien ?? '');
    _urgenceTelCtrl = TextEditingController(text: u.contactUrgenceTel ?? '');
    _assuranceNomCtrl = TextEditingController(text: u.assuranceNom ?? '');
    _assurancePoliceCtrl = TextEditingController(text: u.assurancePolice ?? '');
    _sexe = u.sexe;
    _groupeSanguin =
        (u.groupeSanguin != null && _groupes.contains(u.groupeSanguin))
            ? u.groupeSanguin
            : null;
  }

  @override
  void dispose() {
    _prenomCtrl.dispose();
    _nomCtrl.dispose();
    _telCtrl.dispose();
    _dateCtrl.dispose();
    _conditionCtrl.dispose();
    _urgenceNomCtrl.dispose();
    _urgenceLienCtrl.dispose();
    _urgenceTelCtrl.dispose();
    _assuranceNomCtrl.dispose();
    _assurancePoliceCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final current = DateTime.tryParse(_dateCtrl.text) ?? DateTime(2000, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final m = picked.month.toString().padLeft(2, '0');
      final d = picked.day.toString().padLeft(2, '0');
      _dateCtrl.text = '${picked.year}-$m-$d';
    }
  }

  String? _emptyToNull(String s) => s.trim().isEmpty ? null : s.trim();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final updated = await _repo.updateProfile(
        nom: _nomCtrl.text,
        prenom: _prenomCtrl.text,
        telephone: _emptyToNull(_telCtrl.text),
        dateNaissance: _emptyToNull(_dateCtrl.text),
        sexe: _sexe,
        groupeSanguin: _groupeSanguin,
        conditionMedicale: _emptyToNull(_conditionCtrl.text),
        contactUrgenceNom: _emptyToNull(_urgenceNomCtrl.text),
        contactUrgenceLien: _emptyToNull(_urgenceLienCtrl.text),
        contactUrgenceTel: _emptyToNull(_urgenceTelCtrl.text),
        assuranceNom: _emptyToNull(_assuranceNomCtrl.text),
        assurancePolice: _emptyToNull(_assurancePoliceCtrl.text),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mis à jour')),
      );
      Navigator.of(context).pop(updated);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kNavy,
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SectionLabel('Identité'),
                TextFormField(
                  controller: _prenomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Prénom', Icons.person_outline),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Prénom obligatoire'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: _decoration('Nom', Icons.badge_outlined),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Nom obligatoire' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _decoration('Téléphone', Icons.phone_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _dateCtrl,
                  readOnly: true,
                  onTap: _pickDate,
                  decoration: _decoration(
                      'Date de naissance', Icons.cake_outlined),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _sexe,
                  decoration: _decoration('Sexe', Icons.wc_outlined),
                  items: const [
                    DropdownMenuItem(value: 'Femme', child: Text('Femme')),
                    DropdownMenuItem(value: 'Homme', child: Text('Homme')),
                    DropdownMenuItem(value: 'Autre', child: Text('Autre')),
                  ],
                  onChanged: (v) => setState(() => _sexe = v),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: _groupeSanguin,
                  decoration:
                      _decoration('Groupe sanguin', Icons.bloodtype_outlined),
                  items: [
                    for (final g in _groupes)
                      DropdownMenuItem(value: g, child: Text(g)),
                  ],
                  onChanged: (v) => setState(() => _groupeSanguin = v),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _conditionCtrl,
                  decoration: _decoration(
                      'Condition médicale', Icons.monitor_heart_outlined),
                ),
                const SizedBox(height: 22),

                const _SectionLabel('Contact d\'urgence'),
                TextFormField(
                  controller: _urgenceNomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration:
                      _decoration('Nom', Icons.contact_phone_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urgenceLienCtrl,
                  decoration: _decoration(
                      'Lien (ex : conjoint, parent)', Icons.family_restroom),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _urgenceTelCtrl,
                  keyboardType: TextInputType.phone,
                  decoration:
                      _decoration('Téléphone', Icons.phone_outlined),
                ),
                const SizedBox(height: 22),

                const _SectionLabel('Assurance'),
                TextFormField(
                  controller: _assuranceNomCtrl,
                  decoration: _decoration(
                      'Assureur', Icons.account_balance_outlined),
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _assurancePoliceCtrl,
                  decoration: _decoration(
                      'N° de police', Icons.numbers_outlined),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                                strokeWidth: 2.5, color: Colors.white))
                        : const Text('Enregistrer',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text.toUpperCase(),
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: kNavy)),
    );
  }
}
