import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  // ===== PALETTE DARK PREMIUM =====
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _danger = Color(0xFFFF4D6D);

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animController, curve: Curves.linear));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() => _isSignUp = !_isSignUp);
    _animController.reset();
    _animController.forward();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      if (_isSignUp) {
        await Supabase.instance.client.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'full_name': _nameController.text.trim()},
        );
        await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) await _navigateAfterLogin();
      } else {
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
        if (response.user != null && mounted) await _navigateAfterLogin();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        _showErrorSnackBar(_getErrorMessage(e));
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [Icon(Icons.error_outline_rounded, color: _danger, size: 18), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(fontSize: 13)))]),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _navigateAfterLogin() async {
    final hasBoutique = await _checkIfUserHasBoutique();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed(hasBoutique ? '/navigation' : '/setup-boutique');
  }

  Future<bool> _checkIfUserHasBoutique() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return false;
      final response = await Supabase.instance.client.from('shops').select().eq('owner_id', userId).limit(1);
      return response.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) return 'Email ou mot de passe incorrect';
    if (message.contains('already registered') || message.contains('email_already_exists')) return 'Cet email est déjà utilisé';
    if (message.contains('network') || message.contains('connection')) return 'Erreur réseau. Vérifiez votre connexion';
    return 'Une erreur est survenue. Veuillez réessayer';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: LayoutBuilder(
        builder: (context, constraints) => constraints.maxWidth >= 900 ? _buildDesktopLayout() : _buildMobileLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [_bg, Color(0xFF0A0A0F)])),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              _buildLogo(),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(_isSignUp ? 'Créer un compte' : 'Connexion', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _text, letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(_isSignUp ? 'Rejoignez GIS Gestion' : 'Bienvenue !', style: TextStyle(fontSize: 14, color: _textMute)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildToggleSwitch(),
              const SizedBox(height: 24),
              SlideTransition(position: _slideAnimation, child: FadeTransition(opacity: _fadeAnimation, child: _buildForm())),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: Container(
            decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF0A0A0F), _bg])),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildLogo(size: 140),
                  const SizedBox(height: 24),
                  const Text('GIS Gestion', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: _text, letterSpacing: -0.5)),
                  const SizedBox(height: 8),
                  Text('Gestion de boutique', style: TextStyle(fontSize: 14, color: _textMute, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: Container(
            color: _surface,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_isSignUp ? 'Créer un compte' : 'Connexion', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _text, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text(_isSignUp ? 'Rejoignez notre plateforme' : 'Accédez à votre espace', style: TextStyle(fontSize: 14, color: _textMute)),
                    const SizedBox(height: 32),
                    _buildToggleSwitch(),
                    const SizedBox(height: 32),
                    _buildForm(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FE6)]),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: _accent.withOpacity(0.3), blurRadius: 30, spreadRadius: 4)],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_guiss_gestion1.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Icon(Icons.store_rounded, size: 50, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 280),
      decoration: BoxDecoration(color: _surfaceHi, borderRadius: BorderRadius.circular(12), border: Border.all(color: _border)),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () { if (_isSignUp) _toggleView(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: !_isSignUp ? _accent : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text('Connexion', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: !_isSignUp ? Colors.white : _textMute, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () { if (!_isSignUp) _toggleView(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(color: _isSignUp ? _accent : Colors.transparent, borderRadius: BorderRadius.circular(10)),
                child: Text("S'inscrire", textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: _isSignUp ? Colors.white : _textMute, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          if (_isSignUp) ...[
            _buildTextField(controller: _nameController, label: 'Nom complet', icon: Icons.person_outline_rounded, validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null),
            const SizedBox(height: 14),
          ],
          _buildTextField(controller: _emailController, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) {
            if (v == null || v.isEmpty) return 'Email requis';
            if (!v.contains('@')) return 'Email invalide';
            return null;
          }),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            suffixIcon: IconButton(icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _textMute, size: 18), onPressed: () => setState(() => _obscurePassword = !_obscurePassword)),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 6) return '6 caractères minimum';
              return null;
            },
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: _accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isSignUp ? "S'inscrire" : 'Se connecter', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, TextInputType? keyboardType, bool obscureText = false, Widget? suffixIcon, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textDim)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 14, color: _text),
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, size: 18, color: _accent),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: _surfaceHi,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}