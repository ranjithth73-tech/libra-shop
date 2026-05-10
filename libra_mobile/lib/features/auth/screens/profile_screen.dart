import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/halo_theme.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../orders/screens/orders_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _loading = true;
  bool _editing = false;
  bool _saving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final user = await _authService.getProfile();
      if (mounted) {
        setState(() {
          _user = user;
          _nameCtrl.text = user.name;
          _phoneCtrl.text = user.phone;
          _addressCtrl.text = user.address;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final updated = await _authService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      if (mounted) {
        setState(() { _user = updated; _editing = false; });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Profile updated'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.response?.data.toString() ?? 'Failed to update'),
          backgroundColor: Colors.red.shade400,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: Halo.card),
        title: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel', style: TextStyle(color: Halo.inkMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sign out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TokenStorage.clearTokens();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  String _memberSince() {
    if (_user == null) return '';
    try {
      final dt = DateTime.parse(_user!.createdAt);
      return 'Halo member · since ${dt.year}';
    } catch (_) {
      return 'Halo member';
    }
  }

  @override
  Widget build(BuildContext context) {
    return HaloBg(
      blobs: HaloBg.profile,
      child: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Halo.ink, strokeWidth: 1.5))
            : CustomScrollView(
                slivers: [
                  // ── Profile header ─────────────────────
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        const SizedBox(height: 32),
                        // Avatar
                        Container(
                          width: 80, height: 80,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFD4909E), Color(0xFFBAAED4)],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _user?.name.isNotEmpty == true
                                  ? _user!.name[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700,
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(_user?.name ?? '',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Halo.ink)),
                        const SizedBox(height: 4),
                        Text(_memberSince(),
                            style: const TextStyle(fontSize: 13, color: Halo.inkMuted)),

                        // Stats row
                        const SizedBox(height: 24),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: Halo.card,
                                boxShadow: Halo.cardShadow),
                            child: Row(
                              children: [
                                _Stat(value: '—', label: 'ORDERS'),
                                _divider(),
                                _Stat(value: '—', label: 'SAVED'),
                                _divider(),
                                _Stat(value: '—', label: 'CREDIT'),
                                _divider(),
                                _Stat(value: 'Member', label: 'TIER'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // ── Menu items ─────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _MenuItem(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Orders',
                          subtitle: 'View your order history',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const OrdersScreen()),
                          ),
                        ),
                        _MenuItem(
                          icon: Icons.favorite_border,
                          label: 'Saved',
                          subtitle: 'Your wishlist',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.location_on_outlined,
                          label: 'Addresses',
                          subtitle: _user?.address.isNotEmpty == true
                              ? _user!.address.split('\n').first
                              : 'No address saved',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.notifications_none_outlined,
                          label: 'Notifications',
                          onTap: () {},
                        ),
                        _MenuItem(
                          icon: Icons.card_giftcard_outlined,
                          label: 'Invite friends · earn \$40',
                          onTap: () {},
                        ),

                        const SizedBox(height: 24),

                        // Edit profile section
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: Halo.card,
                            boxShadow: Halo.cardShadow,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Profile details',
                                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Halo.ink)),
                                  GestureDetector(
                                    onTap: () {
                                      if (_editing) {
                                        setState(() {
                                          _editing = false;
                                          _nameCtrl.text = _user!.name;
                                          _phoneCtrl.text = _user!.phone;
                                          _addressCtrl.text = _user!.address;
                                        });
                                      } else {
                                        setState(() => _editing = true);
                                      }
                                    },
                                    child: Text(
                                      _editing ? 'Cancel' : 'Edit',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                          color: Halo.inkMuted),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _ProfileField(label: 'Name', ctrl: _nameCtrl, enabled: _editing),
                              const SizedBox(height: 12),
                              _ProfileField(label: 'Email', value: _user?.email ?? '', enabled: false),
                              const SizedBox(height: 12),
                              _ProfileField(label: 'Phone', ctrl: _phoneCtrl,
                                  enabled: _editing, keyboardType: TextInputType.phone),
                              const SizedBox(height: 12),
                              _ProfileField(label: 'Address', ctrl: _addressCtrl,
                                  enabled: _editing, maxLines: 2),
                              if (_editing) ...[
                                const SizedBox(height: 20),
                                HaloPrimaryButton(label: 'Save Changes', onTap: _save, loading: _saving),
                              ],
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign out
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red, width: 1),
                              shape: RoundedRectangleBorder(borderRadius: Halo.pill),
                            ),
                            child: const Text('Sign out',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ]),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 30, color: Halo.border);
  }
}

// ── Stat cell ─────────────────────────────────────────────────
class _Stat extends StatelessWidget {
  final String value, label;
  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Halo.ink)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                  letterSpacing: 1.0, color: Halo.inkMuted)),
        ],
      ),
    );
  }
}

// ── Menu item ─────────────────────────────────────────────────
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _MenuItem({required this.icon, required this.label, this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Halo.card, boxShadow: Halo.cardShadow),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Halo.bg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, size: 20, color: Halo.ink),
        ),
        title: Text(label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Halo.ink)),
        subtitle: subtitle != null
            ? Text(subtitle!,
                style: const TextStyle(fontSize: 11, color: Halo.inkMuted),
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        trailing: const Icon(Icons.chevron_right, size: 18, color: Halo.inkFaint),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: Halo.card),
      ),
    );
  }
}

// ── Profile field ─────────────────────────────────────────────
class _ProfileField extends StatelessWidget {
  final String label;
  final TextEditingController? ctrl;
  final String? value;
  final bool enabled;
  final TextInputType keyboardType;
  final int maxLines;

  const _ProfileField({
    required this.label,
    this.ctrl,
    this.value,
    this.enabled = false,
    this.keyboardType = TextInputType.text,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                letterSpacing: 1.0, color: Halo.inkMuted)),
        const SizedBox(height: 6),
        if (ctrl != null)
          TextField(
            controller: ctrl,
            enabled: enabled,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: const TextStyle(fontSize: 14, color: Halo.ink),
            decoration: InputDecoration(
              filled: true,
              fillColor: enabled ? Colors.white : Halo.bg,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(borderRadius: Halo.sm, borderSide: const BorderSide(color: Halo.border)),
              enabledBorder: OutlineInputBorder(borderRadius: Halo.sm, borderSide: const BorderSide(color: Halo.border)),
              disabledBorder: OutlineInputBorder(borderRadius: Halo.sm, borderSide: BorderSide(color: Halo.border)),
              focusedBorder: OutlineInputBorder(borderRadius: Halo.sm, borderSide: const BorderSide(color: Halo.ink)),
            ),
          )
        else
          Text(value ?? '',
              style: const TextStyle(fontSize: 14, color: Halo.inkMuted)),
      ],
    );
  }
}
