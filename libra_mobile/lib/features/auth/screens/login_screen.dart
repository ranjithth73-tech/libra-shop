import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../services/auth_service.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  bool _showForm = false;
  bool _loading = false;
  bool _obscure = true;

  late final AnimationController _animCtrl;
  late final Animation<double> _formAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));
    _formAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _toggleForm() {
    setState(() => _showForm = !_showForm);
    _showForm ? _animCtrl.forward() : _animCtrl.reverse();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.login(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } on DioException catch (e) {
      String msg = 'Login failed. Check your credentials.';
      if (e.response == null) {
        msg = 'Cannot connect to server.';
      } else if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        msg = (d['detail'] ?? d['message'] ?? msg).toString();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: Halo.sm),
        ));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: HaloBg(
        blobs: HaloBg.onboarding,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const SizedBox(height: 52),
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.70),
                          borderRadius: Halo.pill,
                        ),
                        child: const Text(
                          'HALO · EST. 2025',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                              letterSpacing: 1.5, color: Halo.inkMuted),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Wordmark
                      const Text(
                        'halo',
                        style: TextStyle(fontSize: 72, fontWeight: FontWeight.w300,
                            color: Halo.ink, letterSpacing: -3, height: 1.0),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A quieter way to discover\nobjects that last',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 15, color: Halo.inkMuted, height: 1.65),
                      ),
                      const SizedBox(height: 52),
                      // Stacked decorative cards
                      _StackedCards(),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              // Auth panel
              _AuthPanel(
                showForm: _showForm,
                formAnim: _formAnim,
                formKey: _formKey,
                emailCtrl: _emailCtrl,
                passCtrl: _passCtrl,
                obscure: _obscure,
                loading: _loading,
                onToggleObscure: () => setState(() => _obscure = !_obscure),
                onToggleForm: _toggleForm,
                onLogin: _login,
                onCreateAccount: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const RegisterScreen()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Stacked decorative cards ──────────────────────────────────
class _StackedCards extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 165,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform(
            transform: Matrix4.translationValues(48.0, 10.0, 0)..rotateZ(0.07),
            alignment: Alignment.center,
            child: _GlassCard(c1: const Color(0xFFCAAA88), c2: const Color(0xFF8FAF99), w: 240, h: 148),
          ),
          Transform(
            transform: Matrix4.translationValues(-38.0, 6.0, 0)..rotateZ(-0.05),
            alignment: Alignment.center,
            child: _GlassCard(c1: const Color(0xFFBAAED4), c2: const Color(0xFF8ECCC0), w: 238, h: 148),
          ),
          _GlassCard(c1: const Color(0xFFD4909E), c2: const Color(0xFFBAAED4), w: 256, h: 152),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Color c1, c2;
  final double w, h;
  const _GlassCard({required this.c1, required this.c2, required this.w, required this.h});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: w, height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [c1.withValues(alpha: 0.72), c2.withValues(alpha: 0.58)],
        ),
        boxShadow: [BoxShadow(color: c1.withValues(alpha: 0.22), blurRadius: 20, offset: const Offset(0, 8))],
      ),
    );
  }
}

// ── Auth panel ────────────────────────────────────────────────
class _AuthPanel extends StatelessWidget {
  final bool showForm;
  final Animation<double> formAnim;
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl, passCtrl;
  final bool obscure, loading;
  final VoidCallback onToggleObscure, onToggleForm, onLogin, onCreateAccount;

  const _AuthPanel({
    required this.showForm, required this.formAnim, required this.formKey,
    required this.emailCtrl, required this.passCtrl, required this.obscure,
    required this.loading, required this.onToggleObscure, required this.onToggleForm,
    required this.onLogin, required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.60),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(28, 24, 28, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slide-in login form
          SizeTransition(
            sizeFactor: formAnim,
            child: FadeTransition(
              opacity: formAnim,
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Welcome back',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Halo.ink)),
                    const SizedBox(height: 20),
                    HaloTextField(
                      controller: emailCtrl,
                      hint: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Email required';
                        if (!v.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    HaloTextField(
                      controller: passCtrl,
                      hint: 'Password',
                      obscure: obscure,
                      suffix: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Halo.inkMuted, size: 20,
                        ),
                        onPressed: onToggleObscure,
                      ),
                      validator: (v) => v == null || v.isEmpty ? 'Password required' : null,
                    ),
                    const SizedBox(height: 20),
                    HaloPrimaryButton(label: 'Sign in', onTap: onLogin, loading: loading),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: onToggleForm,
                        child: const Text('Back', style: TextStyle(color: Halo.inkMuted, fontSize: 14)),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ),

          if (!showForm) ...[
            HaloPrimaryButton(label: 'Continue with email', onTap: onToggleForm),
            const SizedBox(height: 12),
            HaloSecondaryButton(label: 'Create account', onTap: onCreateAccount),
            const SizedBox(height: 4),
          ],

          if (showForm) ...[
            GestureDetector(
              onTap: onCreateAccount,
              child: RichText(
                text: const TextSpan(
                  text: 'New here?  ',
                  style: TextStyle(color: Halo.inkMuted, fontSize: 13),
                  children: [
                    TextSpan(text: 'Create account',
                        style: TextStyle(color: Halo.ink, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
