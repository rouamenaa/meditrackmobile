import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../repositories/user_repository.dart';
import '../services/api_service.dart';
import '../services/session.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'verify_email_screen.dart';

const kGreen = Color(0xFF0B6B5D);
const kNavy = Color(0xFF0A2540);
const kBackground = Color(0xFFF8F7FF);

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _repo = UserRepository();

  bool _hidePassword = true;
  bool _rememberMe = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);
    try {
      final user = await _repo.login(
        _emailCtrl.text,
        _passwordCtrl.text,
        remember: _rememberMe,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      // Compte créé mais email non vérifié : on envoie vers l'écran de vérification
      if (e.statusCode == 403 &&
          e.body is Map &&
          e.body['needs_verification'] == true) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (_) =>
              VerifyEmailScreen(email: _emailCtrl.text.trim().toLowerCase()),
        ));
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    }
  }

  // Connexion biométrique : nécessite une session déjà enregistrée (Remember me).
  Future<void> _biometricLogin() async {
    final auth = LocalAuthentication();
    try {
      final supported =
          (await auth.canCheckBiometrics) || (await auth.isDeviceSupported());
      if (!supported) {
        _snack('Biometrics not available on this device');
        return;
      }

      final savedId = await Session.instance.loadSavedUserId();
      if (savedId == null) {
        _snack('No saved session. Log in first with your email.');
        return;
      }

      final ok = await auth.authenticate(
        localizedReason: 'Sign in to MediTrack',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (!ok) {
        _snack('Authentication cancelled');
        return;
      }

      setState(() => _loading = true);
      final user =
          await UserRepository().restoreSession(afterBiometric: true);
      if (!mounted) return;
      if (user == null) {
        setState(() => _loading = false);
        _snack('Session expired, please log in again with your credentials.');
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => HomeScreen(user: user)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      _snack('Biometrics unavailable: $e');
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  InputDecoration _fieldDecoration(String hint, IconData icon,
      {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
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
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ----- Logo + titre -----
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Icon(Icons.medical_services_rounded,
                            size: 38, color: kGreen),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE3EEF7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 14, color: Color(0xFF1B5E8C)),
                            SizedBox(width: 6),
                            Text('Encrypted Patient Gateway',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1B5E8C))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text('MediTrack',
                          style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              color: kNavy)),
                      const SizedBox(height: 6),
                      Text('Your personal health & medication companion',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ----- Carte de bienvenue -----
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDEFFD),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                            color: Color(0xFFD5E7E4), shape: BoxShape.circle),
                        child:
                        const Icon(Icons.vaccines_outlined, color: kGreen),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Welcome back!',
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 15)),
                            Text(
                                'Stay on track with today\'s dosages and vitals.',
                                style: TextStyle(fontSize: 12.5)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // ----- Email -----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Email address',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                    Text('Required',
                        style: TextStyle(
                            fontSize: 12, color: Colors.brown.shade400)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration:
                  _fieldDecoration('name@example.com', Icons.mail_outline),
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.isEmpty) return 'Email is required';
                    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                        .hasMatch(value)) {
                      return 'Invalid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // ----- Mot de passe -----
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Password',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                    GestureDetector(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const ForgotPasswordScreen()),
                      ),
                      child: const Text('Forgot password?',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kGreen)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _hidePassword,
                  decoration: _fieldDecoration(
                    '••••••••',
                    Icons.lock_outline,
                    suffix: IconButton(
                      icon: Icon(_hidePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                      onPressed: () =>
                          setState(() => _hidePassword = !_hidePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Password is required'
                      : null,
                ),
                const SizedBox(height: 14),

                // ----- Remember me -----
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      activeColor: kGreen,
                      onChanged: (v) =>
                          setState(() => _rememberMe = v ?? false),
                    ),
                    const Text('Remember this device for 30 days',
                        style: TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 12.5)),
                  ],
                ),
                const SizedBox(height: 10),

                // ----- Bouton Log in -----
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
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
                        : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Log in',
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15)),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ----- Séparateur -----
                Row(
                  children: [
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR SIGN IN WITH',
                          style: TextStyle(
                              fontSize: 11,
                              letterSpacing: 1,
                              color: Colors.grey.shade600)),
                    ),
                    Expanded(child: Divider(color: Colors.grey.shade300)),
                  ],
                ),
                const SizedBox(height: 16),

                InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: _loading ? null : _biometricLogin,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                              color: const Color(0xFFE6E9FB),
                              borderRadius: BorderRadius.circular(12)),
                          child: const Icon(Icons.fingerprint,
                              color: Color(0xFF3B4BA8)),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Touch ID',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                              Text('Instant biometric sign in',
                                  style: TextStyle(fontSize: 12.5)),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: kGreen),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ----- Créer un compte -----
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    ),
                    child: const Text("Don't have an account? Sign up",
                        style: TextStyle(
                            color: kGreen, fontWeight: FontWeight.w700)),
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
