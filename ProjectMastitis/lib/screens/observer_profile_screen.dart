import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/local_storage_service.dart';
import '../services/ota_update_service.dart';
import '../widgets/udder_logo_widget.dart';
import '../widgets/responsive_wrapper.dart';
import 'login_screen.dart';

class ObserverProfileScreen extends StatefulWidget {
  const ObserverProfileScreen({super.key});

  @override
  State<ObserverProfileScreen> createState() => _ObserverProfileScreenState();
}

class _ObserverProfileScreenState extends State<ObserverProfileScreen> {
  final _storage = LocalStorageService.instance;
  final _picker = ImagePicker();

  final _idController = TextEditingController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _instController = TextEditingController();

  String? _imagePath;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() => _isLoading = true);
    final id = await _storage.getObserverId();
    final name = await _storage.getObserverName();
    final email = await _storage.getObserverEmail();
    final inst = await _storage.getObserverInstitution();
    final img = await _storage.getObserverImagePath();

    _idController.text = id;
    _nameController.text = name;
    _emailController.text = email;
    _instController.text = inst;
    _imagePath = img;

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() => _imagePath = picked.path);
        await _storage.setObserverImagePath(picked.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to select image: $e')),
        );
      }
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(color: const Color(0xFFCBD5E1), borderRadius: BorderRadius.circular(2)),
              ),
              const Text('Select Profile Photo', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF0F172A))),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.camera_alt_rounded, color: Color(0xFF0F766E), size: 20),
                ),
                title: const Text('Take Photo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.photo_library_rounded, color: Color(0xFF0F766E), size: 20),
                ),
                title: const Text('Choose from Gallery', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (_imagePath != null)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  ),
                  title: const Text('Remove Photo', style: TextStyle(fontSize: 14, color: Colors.red, fontWeight: FontWeight.w600)),
                  onTap: () async {
                    Navigator.pop(ctx);
                    setState(() => _imagePath = null);
                    await _storage.setObserverImagePath(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isSaving = true);
    await _storage.setObserverId(_idController.text.trim());
    await _storage.setObserverName(_nameController.text.trim());
    await _storage.setObserverEmail(_emailController.text.trim());
    await _storage.setObserverInstitution(_instController.text.trim());
    await _storage.setObserverImagePath(_imagePath);
    setState(() => _isSaving = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Color(0xFF0F766E),
          content: Text('Observer profile updated successfully!'),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Observer Profile & Settings', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F766E)))
          : ResponsiveWrapper(
              maxWidth: 600,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Column(
                  children: [
                    // Profile Photo Header
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF0F766E), width: 2.5),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: _imagePath != null && File(_imagePath!).existsSync()
                                  ? Image.file(
                                      File(_imagePath!),
                                      width: 96,
                                      height: 96,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      color: const Color(0xFFF0FDFA),
                                      child: const Center(
                                        child: UdderLogoWidget(size: 48),
                                      ),
                                    ),
                            ),
                          ),
                          PositionTileBadge(onTap: _showImageSourceSheet),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _nameController.text.isEmpty ? 'Field Observer' : _nameController.text,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Observer ID: ${_idController.text.isEmpty ? "OBS-01" : _idController.text}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0F766E)),
                    ),
                    const SizedBox(height: 20),

                    // Profile Form Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.badge_outlined, color: Color(0xFF0F766E), size: 18),
                              SizedBox(width: 8),
                              Text('Observer Information', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Color(0xFF0F172A))),
                            ],
                          ),
                          const SizedBox(height: 14),

                          TextField(
                            controller: _idController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Observer ID / Code *',
                              hintText: 'e.g. OBS-01 or JIMOH-M',
                              prefixIcon: Icon(Icons.tag_rounded, size: 18),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              hintText: 'e.g. Dr. Muhammad Jimoh',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _emailController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Contact Email',
                              hintText: 'e.g. jimoh@veterinary.edu.ng',
                              prefixIcon: Icon(Icons.email_outlined, size: 18),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _instController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Affiliated Institution / Department',
                              hintText: 'e.g. Dept of Veterinary Medicine',
                              prefixIcon: Icon(Icons.account_balance_outlined, size: 18),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // App System Settings
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.system_update_rounded, color: Color(0xFF0F766E), size: 18),
                            ),
                            title: const Text('Check for OTA Updates', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: const Text('Verifies latest study release on cloud', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFF94A3B8)),
                            onTap: () async {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Checking cloud for updates...')),
                              );
                              final release = await OtaUpdateService().checkForUpdate();
                              if (!context.mounted) return;
                              if (release != null) {
                                OtaUpdateService.promptUpdateDialog(context, release);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    backgroundColor: Color(0xFF0F766E),
                                    content: Text('App is up to date!'),
                                  ),
                                );
                              }
                            },
                          ),
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                          ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(color: const Color(0xFF0F766E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.cloud_done_outlined, color: Color(0xFF0F766E), size: 18),
                            ),
                            title: const Text('Backend Database', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            subtitle: const Text('Supabase Project: vzcrfpevvofkzpqzreaj', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    SizedBox(
                      height: 44,
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isSaving ? null : _saveProfile,
                        icon: _isSaving
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : const Icon(Icons.save_outlined, size: 18),
                        label: const Text('Save Profile Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 10),

                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                          );
                        },
                        icon: const Icon(Icons.switch_account_outlined, size: 16),
                        label: const Text('Switch Account / Sign In with Supabase', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }
}

class PositionTileBadge extends StatelessWidget {
  final VoidCallback onTap;
  const PositionTileBadge({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      right: 0,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF0F766E),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 4, offset: const Offset(0, 2)),
            ],
          ),
          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
        ),
      ),
    );
  }
}
