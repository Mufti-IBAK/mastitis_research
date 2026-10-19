import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/local_storage_service.dart';
import '../services/supabase_service.dart';
import '../widgets/udder_logo_widget.dart';
import '../widgets/responsive_wrapper.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _institutionController = TextEditingController();

  bool _isLogin = true;
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _selectedRole = 'observer'; // 'observer' or 'grand_observer'

  final _supabase = SupabaseService();
  final _storage = LocalStorageService.instance;

  Future<void> _handleAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter email and password.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        // 1. Sign In
        final res = await _supabase.signIn(email, password);
        final user = res.user;

        if (user != null) {
          final profileData = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();

          if (profileData != null) {
            await _storage.setObserverId(profileData['observer_code'] ?? 'OBS-01');
            await _storage.setObserverName(profileData['full_name'] ?? email.split('@').first);
            await _storage.setObserverEmail(email);
            await _storage.setObserverInstitution(profileData['institution'] ?? 'Faculty of Veterinary Medicine');
            await _storage.setUserRole(profileData['role'] ?? 'observer');
          } else {
            await _storage.setObserverEmail(email);
          }
        }
      } else {
        // 2. Sign Up
        final res = await _supabase.signUp(email, password);
        final user = res.user;

        if (user != null) {
          final obsCode = _codeController.text.trim().isEmpty ? 'OBS-01' : _codeController.text.trim().toUpperCase();
          final fullName = _nameController.text.trim().isEmpty ? email.split('@').first : _nameController.text.trim();
          final institution = _institutionController.text.trim().isEmpty ? 'Faculty of Veterinary Medicine' : _institutionController.text.trim();

          try {
            await Supabase.instance.client.from('profiles').upsert({
              'id': user.id,
              'email': email,
              'full_name': fullName,
              'observer_code': obsCode,
              'role': _selectedRole,
              'institution': institution,
            });
          } catch (e) {
            debugPrint('Non-critical profile upsert notice: $e');
          }

          await _storage.setObserverId(obsCode);
          await _storage.setObserverName(fullName);
          await _storage.setObserverEmail(email);
          await _storage.setObserverInstitution(institution);
          await _storage.setUserRole(_selectedRole);
        }
      }

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } on AuthException catch (e) {
      if (mounted) {
        String msg = e.message;
        if (e.message.toLowerCase().contains('invalid login credentials') ||
            e.message.toLowerCase().contains('invalid credentials')) {
          msg = 'Incorrect email or password. Please check your credentials.';
        } else if (e.message.toLowerCase().contains('email not confirmed')) {
          msg = 'Email address not yet confirmed. Please verify your email.';
        } else if (e.message.toLowerCase().contains('user already registered')) {
          msg = 'An account with this email already exists. Please sign in.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(msg, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Authentication error: $e', style: const TextStyle(fontSize: 13)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    try {
      final res = await _supabase.signInWithGoogle();
      final user = res.user;

      if (user != null) {
        final email = user.email ?? '';
        final metadata = user.userMetadata ?? {};
        final displayName = (metadata['full_name'] ?? metadata['name'] ?? email.split('@').first).toString();
        final avatar = (metadata['avatar_url'] ?? metadata['picture'] ?? '').toString();

        final existingProfile = await Supabase.instance.client
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (existingProfile != null) {
          await _storage.setObserverId(existingProfile['observer_code'] ?? 'OBS-01');
          await _storage.setObserverName(existingProfile['full_name'] ?? displayName);
          await _storage.setObserverEmail(email);
          await _storage.setObserverInstitution(existingProfile['institution'] ?? 'Faculty of Veterinary Medicine');
          await _storage.setUserRole(existingProfile['role'] ?? 'observer');
        } else {
          final obsCode = displayName.replaceAll(' ', '').toUpperCase();
          final truncatedCode = obsCode.length > 8 ? obsCode.substring(0, 8) : obsCode;

          try {
            await Supabase.instance.client.from('profiles').upsert({
              'id': user.id,
              'email': email,
              'full_name': displayName,
              'observer_code': truncatedCode,
              'role': _selectedRole,
              'institution': 'Faculty of Veterinary Medicine',
              'avatar_url': avatar,
            });
          } catch (e) {
            debugPrint('Non-critical Google profile upsert: $e');
          }

          await _storage.setObserverId(truncatedCode);
          await _storage.setObserverName(displayName);
          await _storage.setObserverEmail(email);
          await _storage.setObserverInstitution('Faculty of Veterinary Medicine');
          await _storage.setUserRole(_selectedRole);
        }

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text(e.message, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFFDC2626),
            content: Text('Google Sign-In error: $e', style: const TextStyle(fontSize: 13)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _continueAsOfflineGuest() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: ResponsiveWrapper(
              maxWidth: 420,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // App Emblem & Clean Branding
                  const UdderLogoWidget(size: 48, showBadgeBorder: true),
                  const SizedBox(height: 12),
                  const Text(
                    'mastitis_research',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F766E),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Udder Health & CMT Surveillance',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),

                  // Modern Form Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Pill Switcher: Sign In vs Register
                        Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(7),
                                  onTap: () => setState(() => _isLogin = true),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    decoration: BoxDecoration(
                                      color: _isLogin ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: _isLogin
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: _isLogin ? FontWeight.w700 : FontWeight.w500,
                                        color: _isLogin ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(7),
                                  onTap: () => setState(() => _isLogin = false),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    padding: const EdgeInsets.symmetric(vertical: 7),
                                    decoration: BoxDecoration(
                                      color: !_isLogin ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(7),
                                      boxShadow: !_isLogin
                                          ? [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 3, offset: const Offset(0, 1))]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Register',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: !_isLogin ? FontWeight.w700 : FontWeight.w500,
                                        color: !_isLogin ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        if (!_isLogin) ...[
                          // Role Pill Toggle
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => setState(() => _selectedRole = 'observer'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'observer' ? const Color(0xFFCCFBF1) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedRole == 'observer' ? const Color(0xFF0F766E) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Field Observer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _selectedRole == 'observer' ? FontWeight.w700 : FontWeight.w500,
                                        color: _selectedRole == 'observer' ? const Color(0xFF0F766E) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => setState(() => _selectedRole = 'grand_observer'),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _selectedRole == 'grand_observer' ? const Color(0xFFFEF3C7) : const Color(0xFFF8FAFC),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _selectedRole == 'grand_observer' ? const Color(0xFFD97706) : const Color(0xFFE2E8F0),
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      'Grand Observer',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: _selectedRole == 'grand_observer' ? FontWeight.w700 : FontWeight.w500,
                                        color: _selectedRole == 'grand_observer' ? const Color(0xFFB45309) : const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          TextField(
                            controller: _nameController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF64748B)),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 10),

                          TextField(
                            controller: _codeController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Observer Code',
                              hintText: 'e.g. OBS-01',
                              prefixIcon: Icon(Icons.tag_rounded, size: 18, color: Color(0xFF64748B)),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 10),

                          TextField(
                            controller: _institutionController,
                            style: const TextStyle(fontSize: 13),
                            decoration: const InputDecoration(
                              labelText: 'Institution',
                              hintText: 'Faculty of Veterinary Medicine',
                              prefixIcon: Icon(Icons.account_balance_outlined, size: 18, color: Color(0xFF64748B)),
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],

                        TextField(
                          controller: _emailController,
                          style: const TextStyle(fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Email Address',
                            prefixIcon: Icon(Icons.email_outlined, size: 18, color: Color(0xFF64748B)),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 10),

                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: const TextStyle(fontSize: 13),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Color(0xFF64748B)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF64748B),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleAuth,
                          child: _isLoading
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : Text(
                                  _isLogin ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                ),
                        ),
                        const SizedBox(height: 14),

                        Row(
                          children: [
                            const Expanded(child: Divider()),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('OR', style: TextStyle(color: Colors.grey.shade400, fontSize: 11, fontWeight: FontWeight.w600)),
                            ),
                            const Expanded(child: Divider()),
                          ],
                        ),
                        const SizedBox(height: 14),

                        OutlinedButton(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 18,
                                height: 18,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF4285F4),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'G',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 12),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                _isLogin ? 'Continue with Google' : 'Sign up with Google',
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Offline Mode Link
                  TextButton.icon(
                    onPressed: _continueAsOfflineGuest,
                    icon: const Icon(Icons.offline_pin_outlined, size: 16, color: Color(0xFF0F766E)),
                    label: const Text(
                      'Work in Offline Field Mode',
                      style: TextStyle(color: Color(0xFF0F766E), fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
