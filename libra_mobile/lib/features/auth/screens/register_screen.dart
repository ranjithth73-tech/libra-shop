import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../core/theme/halo_theme.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _authService = AuthService();

  bool _loading = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.register(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        password: _passCtrl.text.trim(),
      );
      if (mounted) Navigator.pushReplacementNamed(context, '/main');
    } on DioException catch (e) {
      String msg = 'Registration failed.';
      if (e.response == null) {
        msg = 'Cannot connect to server.';
      } else if (e.response?.data is Map) {
        final d = e.response!.data as Map;
        msg = (d['message'] ?? d['detail'] ??
            d.values.where((v) => v != null).join('\n')).toString();
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
        blobs: const [
          HaloBlob(color: Halo.lavender, dx: -0.6, dy: -0.75, r: 0.65),
          HaloBlob(color: Halo.mint,     dx:  0.65, dy: -0.65, r: 0.60),
          HaloBlob(color: Halo.peach,    dx:  0.50, dy:  0.55, r: 0.45),
        ],
        child: SafeArea(
          child: Column(
            children: [
              // Back button row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _CircleIconButton(
                    icon: Icons.arrow_back,
                    onTap: () => Navigator.pop(context),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        const Text(
                          'Create your\naccount',
                          style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700,
                              color: Halo.ink, height: 1.1, letterSpacing: -0.5),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Join halo to discover pieces that last.',
                          style: TextStyle(fontSize: 15, color: Halo.inkMuted, height: 1.5),
                        ),
                        const SizedBox(height: 36),
                        HaloTextField(
                          controller: _nameCtrl,
                          hint: 'Full name',
                          validator: (v) => v == null || v.isEmpty ? 'Name required' : null,
                        ),
                        const SizedBox(height: 14),
                        HaloTextField(
                          controller: _emailCtrl,
                          hint: 'Email address',
                          keyboardType: TextInputType.emailAddress,
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Email required';
                            if (!v.contains('@')) return 'Invalid email';
                            return null;
                          },
                        ),
                        const SizedBox(height: 14),
                        HaloTextField(
                          controller: _passCtrl,
                          hint: 'Password',
                          obscure: _obscure,
                          suffix: IconButton(
                            icon: Icon(
                              _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Halo.inkMuted, size: 20,
                            ),
                            onPressed: () => setState(() => _obscure = !_obscure),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) return 'Password required';
                            if (v.length < 6) return 'Minimum 6 characters';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        HaloPrimaryButton(label: 'Create Account', onTap: _register, loading: _loading),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account?  ',
                                style: TextStyle(color: Halo.inkMuted, fontSize: 13),
                                children: [
                                  TextSpan(text: 'Sign in',
                                      style: TextStyle(color: Halo.ink, fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.80),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: Halo.ink),
      ),
    );
  }
}
