import 'package:flutter/material.dart';

class Halo {
  Halo._();

  // ── Palette ──────────────────────────────────────────────
  static const Color bg       = Color(0xFFF2EDE8);
  static const Color surface  = Color(0xFFFFFFFF);
  static const Color ink      = Color(0xFF1A1A1A);
  static const Color inkMuted = Color(0xFF888888);
  static const Color inkFaint = Color(0xFFBBBBBB);
  static const Color border   = Color(0xFFE8E4DE);

  // pastel blob colors
  static const Color peach    = Color(0xFFF2A882);
  static const Color butter   = Color(0xFFE8CE82);
  static const Color rose     = Color(0xFFD4909E);
  static const Color sage     = Color(0xFF8FAF99);
  static const Color lavender = Color(0xFFBAAED4);
  static const Color mint     = Color(0xFF8ECCC0);
  static const Color blue     = Color(0xFF88A8CC);
  static const Color sand     = Color(0xFFCAAA88);
  static const Color mauve    = Color(0xFFD4A4B8);
  static const Color olive    = Color(0xFFA0B488);

  // ── Product gradient palette ──────────────────────────────
  static const _pg = [
    [Color(0xFFD4909E), Color(0xFFE8A8B8)],
    [Color(0xFF8FAF99), Color(0xFFA8C8B4)],
    [Color(0xFFBAAED4), Color(0xFFCCC4E0)],
    [Color(0xFFCAAA88), Color(0xFFDEC0A0)],
    [Color(0xFFE8CE82), Color(0xFFF0DC9C)],
    [Color(0xFF8ECCC0), Color(0xFFA8DCD4)],
    [Color(0xFF88A8CC), Color(0xFFA4C0DC)],
    [Color(0xFFF2A882), Color(0xFFF8C0A0)],
  ];

  static LinearGradient productGradient(int id) => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: _pg[id.abs() % _pg.length],
      );

  // ── Radius ────────────────────────────────────────────────
  static BorderRadius get pill => BorderRadius.circular(999);
  static BorderRadius get card => BorderRadius.circular(20);
  static BorderRadius get sm   => BorderRadius.circular(12);

  // ── Shadows ───────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

// ── Gradient background ───────────────────────────────────────
class HaloBg extends StatelessWidget {
  final Widget child;
  final List<HaloBlob> blobs;

  const HaloBg({super.key, required this.child, this.blobs = const []});

  // preset configs
  static const onboarding = [
    HaloBlob(color: Halo.peach,    dx: -0.65, dy: -0.70, r: 0.70),
    HaloBlob(color: Halo.butter,   dx:  0.60, dy: -0.80, r: 0.65),
    HaloBlob(color: Halo.rose,     dx: -0.20, dy:  0.05, r: 0.55),
    HaloBlob(color: Halo.lavender, dx: -0.75, dy:  0.65, r: 0.70),
    HaloBlob(color: Halo.mint,     dx:  0.70, dy:  0.55, r: 0.65),
  ];

  static const home = [
    HaloBlob(color: Halo.blue,   dx: -0.85, dy: -0.85, r: 0.75),
    HaloBlob(color: Halo.rose,   dx:  0.85, dy: -0.80, r: 0.70),
    HaloBlob(color: Halo.butter, dx:  0.50, dy:  0.60, r: 0.45),
  ];

  static const profile = [
    HaloBlob(color: Halo.lavender, dx: -0.60, dy: -0.80, r: 0.70),
    HaloBlob(color: Halo.mint,     dx:  0.65, dy: -0.70, r: 0.60),
    HaloBlob(color: Halo.peach,    dx:  0.50, dy:  0.50, r: 0.45),
  ];

  static const confirmation = [
    HaloBlob(color: Halo.peach,    dx: -0.50, dy: -0.85, r: 0.75),
    HaloBlob(color: Halo.butter,   dx:  0.55, dy: -0.85, r: 0.65),
    HaloBlob(color: Halo.lavender, dx: -0.60, dy:  0.30, r: 0.55),
    HaloBlob(color: Halo.mint,     dx:  0.60, dy:  0.40, r: 0.50),
  ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Halo.bg),
        ...blobs.map((b) => _Blob(def: b)),
        child,
      ],
    );
  }
}

class HaloBlob {
  final Color color;
  final double dx, dy, r; // dx/dy: fraction of half-width/height, r: fraction of width
  const HaloBlob({required this.color, required this.dx, required this.dy, required this.r});
}

class _Blob extends StatelessWidget {
  final HaloBlob def;
  const _Blob({required this.def});

  @override
  Widget build(BuildContext context) {
    final s = MediaQuery.sizeOf(context);
    final sz = s.width * def.r * 2;
    return Positioned(
      left: s.width / 2 + def.dx * s.width / 2 - sz / 2,
      top:  s.height / 2 + def.dy * s.height / 2 - sz / 2,
      width: sz, height: sz,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            def.color.withValues(alpha: 0.55),
            Colors.transparent,
          ]),
        ),
      ),
    );
  }
}

// ── Shared UI primitives ──────────────────────────────────────
class HaloPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool loading;
  final IconData? icon;

  const HaloPrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Halo.ink,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Halo.inkFaint,
          shape: RoundedRectangleBorder(borderRadius: Halo.pill),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 8)],
                  Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}

class HaloSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const HaloSecondaryButton({super.key, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withValues(alpha: 0.85),
          foregroundColor: Halo.ink,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: Halo.pill),
        ),
        child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class HaloTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final bool obscure;
  final Widget? suffix;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final int maxLines;

  const HaloTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.obscure = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(fontSize: 15, color: Halo.ink),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Halo.inkFaint),
        suffixIcon: suffix,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: Halo.pill,
          borderSide: const BorderSide(color: Halo.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: Halo.pill,
          borderSide: const BorderSide(color: Halo.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: Halo.pill,
          borderSide: const BorderSide(color: Halo.ink, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: Halo.pill,
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: Halo.pill,
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }
}
