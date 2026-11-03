import 'package:flutter/material.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import 'login_screen.dart' show kGreen, kNavy, kBackground;

/// Mot de passe oublié : envoi d'un code par email puis saisie du code + nouveau mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _emailFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  final _repo = UserRepository();

  int _step = 0; // 0 = email, 1 = code + nouveau mot de passe
  bool _loading = false;
  bool _hidePassword = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    // À l'étape 1 (renvoi), le formulaire email n'est plus affiché.
    final emailForm = _emailFormKey.currentState;
    if (emailForm != null && !emailForm.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.forgotPassword(_emailCtrl.text);
      if (!mounted) return;
      setState(() {
        _loading = false;
        _step = 1;
      });
      _snack('Si un compte existe pour cet email, un code a été envoyé.');
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.message);
    }
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _repo.resetPassword(
          _emailCtrl.text, _codeCtrl.text, _passwordCtrl.text);
      if (!mounted) return;
      _snack('Mot de passe modifié. Connecte-toi avec le nouveau mot de passe.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack(e.message);
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _decoration(String label, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: Colors.grey.shade600),
      suffixIcon: suffix,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackground,
      appBar: AppBar(
        backgroundColor: kBackground,
        elevation: 0,
        foregroundColor: kNavy,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.lock_reset, size: 56, color: kGreen),
              const SizedBox(height: 16),
              const Text('Mot de passe oublié',
                  style: TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800, color: kNavy)),
              const SizedBox(height: 8),
              Text(
                _step == 0
                    ? 'Entre ton adresse email : nous t\'enverrons un code de réinitialisation.'
                    : 'Saisis le code reçu par email et choisis un nouveau mot de passe.',
                style: TextStyle(color: Colors.grey.shade700),
              ),
              const SizedBox(height: 24),
              if (_step == 0) _buildEmailStep() else _buildResetStep(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailStep() {
    return Form(
      key: _emailFormKey,
      child: Column(
        children: [
          TextFormField(
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _decoration('Email', Icons.mail_outline),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Email obligatoire';
              if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                return 'Email invalide';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _sendCode,
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
                  : const Text('Envoyer le code',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _codeCtrl,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: _decoration('Code reçu par email', Icons.pin_outlined),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return 'Code obligatoire';
              if (value.length != 6) return 'Le code comporte 6 chiffres';
              return null;
            },
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: _passwordCtrl,
            obscureText: _hidePassword,
            decoration: _decoration(
              'Nouveau mot de passe',
              Icons.lock_outline,
              suffix: IconButton(
                icon: Icon(_hidePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _hidePassword = !_hidePassword),
              ),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe obligatoire';
              if (v.length < 6) return 'Minimum 6 caractères';
              return null;
            },
          ),
          const SizedBox(height: 14),
          TextFormField(
            controller: _confirmCtrl,
            obscureText: _hidePassword,
            decoration:
                _decoration('Confirmer le mot de passe', Icons.lock_outline),
            validator: (v) =>
                v != _passwordCtrl.text ? 'Les mots de passe ne correspondent pas' : null,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _loading ? null : _resetPassword,
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
                  : const Text('Réinitialiser le mot de passe',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: _loading ? null : _sendCode,
              child: const Text('Renvoyer le code',
                  style: TextStyle(color: kGreen, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
