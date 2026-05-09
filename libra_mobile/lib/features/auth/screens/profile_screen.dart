import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../core/storage/token_storage.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _authService = AuthService();
  UserModel? _user;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    try {
      final user = await _authService.getProfile();
      setState(() {
        _user = user;
        _nameCtrl.text = user.name;
        _phoneCtrl.text = user.phone;
        _addressCtrl.text = user.address;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load profile.'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    try {
      final updated = await _authService.updateProfile(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        address: _addressCtrl.text.trim(),
      );
      setState(() {
        _user = updated;
        _isEditing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated.'), backgroundColor: Colors.green),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.response?.data.toString() ?? 'Failed to update profile.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TokenStorage.clearTokens();
    if (mounted) Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          if (!_isLoading && _user != null)
            IconButton(
              onPressed: () {
                if (_isEditing) {
                  // Cancel — restore original values
                  setState(() {
                    _isEditing = false;
                    _nameCtrl.text = _user!.name;
                    _phoneCtrl.text = _user!.phone;
                    _addressCtrl.text = _user!.address;
                  });
                } else {
                  setState(() => _isEditing = true);
                }
              },
              icon: Icon(_isEditing ? Icons.close : Icons.edit_outlined),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _user == null
          ? const Center(child: Text('Failed to load profile'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Avatar
                  const SizedBox(height: 8),
                  CircleAvatar(
                    radius: 44,
                    backgroundColor: Colors.black,
                    child: Text(
                      _user!.name.isNotEmpty ? _user!.name[0].toUpperCase() : '?',
                      style: const TextStyle(fontSize: 36, color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_user!.email, style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                  const SizedBox(height: 24),

                  // Fields
                  _buildField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    icon: Icons.person_outline,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Phone',
                    controller: _phoneCtrl,
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 14),
                  _buildField(
                    label: 'Address',
                    controller: _addressCtrl,
                    icon: Icons.location_on_outlined,
                    maxLines: 3,
                    enabled: _isEditing,
                  ),
                  const SizedBox(height: 24),

                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                            : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16)),
                      ),
                    ),

                  if (!_isEditing) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _logout,
                        icon: const Icon(Icons.logout, color: Colors.red),
                        label: const Text('Logout', style: TextStyle(color: Colors.red, fontSize: 16)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = false,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.black, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
      ),
    );
  }
}
