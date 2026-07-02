import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/oauth_helper.dart';
import '../../../core/theme/gis_palette.dart';
import '../../../core/theme/gis_theme_ext.dart';
import '../../widgets/theme_toggle_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  GisPalette get _p => GisPalette.of(context);


  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  late AnimationController _entranceController;
  late AnimationController _ambientController;
  late Animation<double> _entranceAnim;
  late Animation<double> _ambientAnim;

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSignUp = false;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      if (!mounted) return;
      if (data.event == AuthChangeEvent.signedIn && _isLoading) {
        await OAuthHelper.ensureProfileFromAuthUser();
        if (mounted) await _navigateAfterLogin();
        if (mounted) setState(() => _isLoading = false);
      }
    });
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _entranceAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _ambientAnim = CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut);
    _entranceController.forward();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _toggleView() {
    HapticFeedback.selectionClick();
    setState(() => _isSignUp = !_isSignUp);
    _entranceController.forward(from: 0);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();

    try {
      if (_isSignUp) {
        await _signUp();
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

  Future<void> _signUp() async {
    final response = await Supabase.instance.client.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      data: {'full_name': _nameController.text.trim()},
    );

    final user = response.user;
    if (user == null) {
      throw Exception('Création du compte impossible');
    }

    // Profil : best-effort (peut être créé par un trigger Supabase)
    try {
      await Supabase.instance.client.from('profiles').upsert({
        'id': user.id,
        'full_name': _nameController.text.trim(),
      });
    } catch (e) {
      debugPrint('Profil (non bloquant): $e');
    }

    // Session déjà active → email confirmé ou confirmation désactivée
    if (response.session != null) {
      if (mounted) await _navigateAfterLogin();
      return;
    }

    // Confirmation email requise : ne pas tenter signInWithPassword (échoue toujours)
    if (mounted) {
      HapticFeedback.lightImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Compte créé ! Vérifiez votre boîte mail pour confirmer, puis connectez-vous.',
            style: TextStyle(fontSize: 13),
          ),
          backgroundColor: _p.surfaceHi,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side:  BorderSide(color: _p.border)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 6),
        ),
      );
      setState(() => _isSignUp = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    HapticFeedback.lightImpact();
    try {
      await OAuthHelper.signInWithGoogle();
      if (kIsWeb) return;
      await Future.delayed(const Duration(milliseconds: 800));
      if (Supabase.instance.client.auth.currentSession != null && mounted) {
        await OAuthHelper.ensureProfileFromAuthUser();
        await _navigateAfterLogin();
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.heavyImpact();
        final err = e.toString().toLowerCase();
        _showErrorSnackBar(_getErrorMessage(e));
        if (err.contains('provider is not enabled') ||
            err.contains('unsupported provider') ||
            err.contains('missing oauth secret')) {
          await _showGoogleNotConfiguredDialog();
        }
      }
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _forgotPassword() async {
    final emailCtrl = TextEditingController(text: _emailController.text.trim());
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side:  BorderSide(color: _p.border)),
        title: Text('Mot de passe oublié', style: GoogleFonts.plusJakartaSans(color: _p.text, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             Text('Entrez votre email pour recevoir un lien de réinitialisation.', style: TextStyle(color: _p.textMute, fontSize: 13)),
            const SizedBox(height: 16),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              style:  TextStyle(color: _p.text),
              decoration: _inputDecoration('Email', Icons.email_outlined),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child:  Text('Annuler', style: TextStyle(color: _p.textMute))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _p.accent),
            child: Text('Envoyer'),
          ),
        ],
      ),
    );

    if (sent != true || emailCtrl.text.trim().isEmpty) return;

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(emailCtrl.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email de réinitialisation envoyé'),
            backgroundColor: _p.surfaceHi,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) _showErrorSnackBar(_getErrorMessage(e));
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
             Icon(Icons.error_outline_rounded, color: _p.danger, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style:  TextStyle(fontSize: 13, color: _p.text))),
          ],
        ),
        backgroundColor: _p.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side:  BorderSide(color: _p.border)),
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
      final response = await Supabase.instance.client.from('shops').select('id').eq('owner_id', userId).limit(1);
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _getErrorMessage(dynamic error) {
    final message = error.toString().toLowerCase();
    if (message.contains('invalid login credentials')) return 'Email ou mot de passe incorrect';
    if (message.contains('already registered') || message.contains('email_already_exists')) return 'Cet email est déjà utilisé';
    if (message.contains('network') || message.contains('connection')) return 'Erreur réseau. Vérifiez votre connexion';
    if (message.contains('weak password')) return 'Mot de passe trop faible (6 caractères minimum)';
    if (message.contains('email not confirmed') || message.contains('not confirmed')) {
      return 'Confirmez votre email via le lien reçu, puis reconnectez-vous.';
    }
    if (message.contains('profiles') || message.contains('row-level security')) {
      return 'Compte créé. Connectez-vous — le profil sera complété automatiquement.';
    }
    if (message.contains('provider is not enabled') || message.contains('unsupported provider')) {
      if (message.contains('missing oauth secret')) {
        return 'Client Secret Google manquant dans Supabase → Providers → Google.';
      }
      return 'Google n\'est pas activé dans Supabase. Voir Authentication → Providers → Google.';
    }
    return 'Une erreur est survenue. Veuillez réessayer';
  }

  Future<void> _showGoogleNotConfiguredDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side:  BorderSide(color: _p.border)),
        title: Text('Google non configuré', style: GoogleFonts.plusJakartaSans(color: _p.text, fontWeight: FontWeight.w700)),
        content:  SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Activez Google dans votre projet Supabase :', style: TextStyle(color: _p.textMute, fontSize: 13)),
              SizedBox(height: 12),
              Text('1. dashboard.supabase.com → votre projet', style: TextStyle(color: _p.text, fontSize: 12)),
              Text('2. Authentication → Providers → Google', style: TextStyle(color: _p.text, fontSize: 12)),
              Text('3. Activer + Client ID & Secret (Google Cloud)', style: TextStyle(color: _p.text, fontSize: 12)),
              Text('   → Le Client Secret est OBLIGATOIRE (champ vide = erreur)', style: TextStyle(color: Color(0xFFFF4D6D), fontSize: 11)),
              SizedBox(height: 8),
              Text('4. Redirect URL Supabase :', style: TextStyle(color: _p.textMute, fontSize: 11)),
              Text('guissgestion://login-callback', style: TextStyle(color: _p.accentSoft, fontSize: 11)),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            style: FilledButton.styleFrom(backgroundColor: _p.accent),
            child: Text('Compris'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle:  TextStyle(color: _p.textDim, fontSize: 14),
      prefixIcon: Icon(icon, size: 18, color: _p.accentSoft),
      suffixIcon: suffix,
      filled: true,
      fillColor: _p.surfaceHi,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide:  BorderSide(color: _p.border)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide:  BorderSide(color: _p.accent, width: 1.5)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
    );
  }

  Widget _stagger(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceAnim,
      builder: (_, __) {
        final start = index * 0.08;
        final end = (start + 0.55).clamp(0.0, 1.0);
        final t = _interval(_entranceAnim.value, start, end);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 24 * (1 - t)), child: child),
        );
      },
    );
  }

  double _interval(double v, double start, double end) {
    if (v <= start) return 0;
    if (v >= end) return 1;
    return (v - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: (Theme.of(context).brightness == Brightness.dark
              ? SystemUiOverlayStyle.light
              : SystemUiOverlayStyle.dark)
          .copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _p.bg,
        body: ThemeToggleOverlay(
          child: Stack(
            children: [
              _AmbientBackground(anim: _ambientAnim),
              LayoutBuilder(
                builder: (context, constraints) =>
                    constraints.maxWidth >= 900 ? _buildDesktopLayout() : _buildMobileLayout(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              children: [
                _stagger(0, _buildLogo(size: 88)),
                const SizedBox(height: 28),
                _stagger(1, _buildHeadline()),
                const SizedBox(height: 28),
                _stagger(2, _buildToggleSwitch()),
                const SizedBox(height: 24),
                _stagger(3, _buildFormCard()),
                const SizedBox(height: 24),
                _stagger(4, _buildFooter()),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 64),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _stagger(0, _buildLogo(size: 64)),
                      const SizedBox(height: 24),
                      _stagger(1, Text(
                        'Gis Gestion',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: _p.text,
                          letterSpacing: -1,
                        ),
                      )),
                      const SizedBox(height: 8),
                      _stagger(2, Text(
                        'La solution professionnelle pour\npiloter votre boutique.',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, color: _p.textMute, height: 1.5),
                      )),
                      const SizedBox(height: 28),
                      _stagger(3, _buildFeatureList(compact: constraints.maxHeight < 720)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: _p.surface.withValues(alpha: 0.85),
              border:  Border(left: BorderSide(color: _p.border)),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Column(
                    children: [
                      _stagger(0, _buildHeadline(compact: true)),
                      const SizedBox(height: 28),
                      _stagger(1, _buildToggleSwitch()),
                      const SizedBox(height: 24),
                      _stagger(2, _buildFormCard(bordered: false)),
                      const SizedBox(height: 20),
                      _stagger(3, _buildFooter()),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureList({bool compact = false}) {
    const allFeatures = [
      (Icons.point_of_sale_rounded, 'Caisse rapide', 'Ventes comptant et crédit'),
      (Icons.inventory_2_rounded, 'Stock intelligent', 'Alertes rupture et faible stock'),
      (Icons.insights_rounded, 'Tableau de bord', 'Statistiques en temps réel'),
      (Icons.credit_card_rounded, 'Crédits clients', 'Suivi et encaissement'),
    ];
    final features = compact ? allFeatures.take(3).toList() : allFeatures;

    return Column(
      children: features.map((f) {
        return Padding(
          padding: EdgeInsets.only(bottom: compact ? 10 : 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _p.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _p.accent.withValues(alpha: 0.2)),
                ),
                child: Icon(f.$1, color: _p.accentSoft, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2, style:  TextStyle(color: _p.text, fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(f.$3, style:  TextStyle(color: _p.textDim, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHeadline({bool compact = false}) {
    return Column(
      children: [
        Text(
          _isSignUp ? 'Créer un compte' : 'Connexion',
          style: GoogleFonts.plusJakartaSans(
            fontSize: compact ? 26 : 28,
            fontWeight: FontWeight.w800,
            color: _p.text,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isSignUp ? 'Rejoignez Gis Gestion en quelques secondes' : 'Accédez à votre espace gérant',
          textAlign: TextAlign.center,
          style:  TextStyle(fontSize: 14, color: _p.textMute),
        ),
      ],
    );
  }

  Widget _buildLogo({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: _p.accentLinear(),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [
          BoxShadow(color: _p.accent.withValues(alpha: 0.35), blurRadius: 28, offset: const Offset(0, 8)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.28),
        child: Image.asset(
          'assets/images/logo_guiss_gestion1.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.store_rounded, size: size * 0.45, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      decoration: BoxDecoration(
        color: _p.surfaceHi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _p.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          Expanded(child: _toggleTab('Connexion', !_isSignUp, () { if (_isSignUp) _toggleView(); })),
          Expanded(child: _toggleTab("S'inscrire", _isSignUp, () { if (!_isSignUp) _toggleView(); })),
        ],
      ),
    );
  }

  Widget _toggleTab(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: active ? _p.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: _p.accent.withValues(alpha: 0.35), blurRadius: 8, offset: Offset(0, 2))]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: active ? Colors.white : _p.textMute,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildFormCard({bool bordered = true}) {
    final form = _buildForm();
    if (!bordered) return form;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _p.cardDecoration(context, radius: 20),
      child: form,
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_isSignUp) ...[
            _buildTextField(
              controller: _nameController,
              label: 'Nom complet',
              icon: Icons.person_outline_rounded,
              textInputAction: TextInputAction.next,
              validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
            ),
            const SizedBox(height: 14),
          ],
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: (v) {
              if (v == null || v.isEmpty) return 'Email requis';
              if (!v.contains('@') || !v.contains('.')) return 'Email invalide';
              return null;
            },
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _passwordController,
            label: 'Mot de passe',
            icon: Icons.lock_outline_rounded,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: _p.textMute, size: 18),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Mot de passe requis';
              if (v.length < 6) return '6 caractères minimum';
              return null;
            },
          ),
          if (!_isSignUp) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: _isLoading ? null : _forgotPassword,
                child:  Text('Mot de passe oublié ?', style: TextStyle(color: _p.accentSoft, fontSize: 12)),
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildSubmitButton(),
          if (!_isSignUp) ...[
            const SizedBox(height: 20),
            _buildOrDivider(),
            const SizedBox(height: 16),
            _buildGoogleButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: _p.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('ou continuer avec', style: TextStyle(color: _p.textDim, fontSize: 11)),
        ),
        Expanded(child: Container(height: 1, color: _p.border)),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return Material(
      color: _p.surfaceHi,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: _isLoading ? null : _signInWithGoogle,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _p.border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Center(
                  child: Text(
                    'G',
                    style: TextStyle(
                      color: Color(0xFF4285F4),
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Continuer avec Google',
                style: GoogleFonts.plusJakartaSans(
                  color: _p.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _isLoading ? [_p.textDim, _p.textDim] : [_p.accent, Color(0xFF5B3FD4)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: _isLoading
            ? null
            : [BoxShadow(color: _p.accent.withValues(alpha: 0.4), blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submit,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: _isLoading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(
                    _isSignUp ? "Créer mon compte" : 'Se connecter',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style:  TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _p.textDim)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style:  TextStyle(fontSize: 14, color: _p.text),
          validator: validator,
          decoration: _inputDecoration(label, icon, suffix: suffixIcon),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      '© ${DateTime.now().year} Gis Gestion · Gestion commerciale',
      textAlign: TextAlign.center,
      style:  TextStyle(color: _p.textDim, fontSize: 11),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  final Animation<double> anim;

  const _AmbientBackground({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (_, __) {
        final pulse = 0.7 + anim.value * 0.3;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 280 * pulse,
                  height: 280 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF7C5CFF).withValues(alpha: 0.12), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -60,
                left: -60,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [const Color(0xFF3B82F6).withValues(alpha: 0.1), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
