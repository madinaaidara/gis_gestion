import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/shops_repository.dart';
import '../../../data/repositories/abonnement_repository.dart';

class SetupBoutiquePage extends StatefulWidget {
  const SetupBoutiquePage({super.key});

  @override
  State<SetupBoutiquePage> createState() => _SetupBoutiquePageState();
}

class _SetupBoutiquePageState extends State<SetupBoutiquePage> with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _accentSoft = Color(0xFFB8A4FF);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFFF4D6D);

  final _formKey = GlobalKey<FormState>();
  final _nomBoutiqueController = TextEditingController();
  final _proprietaireController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  late AnimationController _entranceController;
  late AnimationController _ambientController;
  late Animation<double> _entranceAnim;
  late Animation<double> _ambientAnim;

  bool _isLoading = false;
  int _savePhase = 0; // 0 idle, 1 saving, 2 done
  String _selectedDevise = 'FCFA';

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _ambientController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))..repeat(reverse: true);
    _entranceAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _ambientAnim = CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut);
    _entranceController.forward();
    _prefillOwner();
  }

  Future<void> _prefillOwner() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      var name = user.userMetadata?['full_name']?.toString() ??
          user.userMetadata?['name']?.toString();
      if (name == null) {
        final row = await Supabase.instance.client
            .from('profiles')
            .select('full_name, phone')
            .eq('id', user.id)
            .maybeSingle();
        name = row?['full_name']?.toString();
        final phone = row?['phone']?.toString();
        if (phone != null && _telephoneController.text.isEmpty) {
          _telephoneController.text = phone;
        }
      }
      if (name != null && _proprietaireController.text.isEmpty && mounted) {
        setState(() => _proprietaireController.text = name!);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nomBoutiqueController.dispose();
    _proprietaireController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    _entranceController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  Future<void> _saveBoutique() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _savePhase = 1;
    });
    HapticFeedback.mediumImpact();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception('Utilisateur non connecté');

      await Supabase.instance.client.from('shops').insert({
        'owner_id': userId,
        'nom_boutique': _nomBoutiqueController.text.trim(),
        'proprietaire': _proprietaireController.text.trim().isEmpty ? null : _proprietaireController.text.trim(),
        'telephone': _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        'devise': _selectedDevise,
        'onboarding_completed': false,
      });

      if (mounted) {
        final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
        await shopRepo.checkAndLoadShop(userId);
        final shopId = shopRepo.currentShop?.id;
        if (shopId != null && mounted) {
          await Provider.of<AbonnementRepository>(context, listen: false).ensureTrialForShop(shopId);
        }
      }

      if (mounted) {
        setState(() => _savePhase = 2);
        HapticFeedback.lightImpact();
        await Future.delayed(const Duration(milliseconds: 800));
        Navigator.of(context).pushReplacementNamed('/onboarding-tour');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _savePhase = 0;
        });
        _showErrorSnackBar(_parseError(e));
      }
    }
  }

  String _parseError(Object e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('duplicate') || msg.contains('unique')) {
      return 'Vous avez déjà une boutique enregistrée.';
    }
    if (msg.contains('network') || msg.contains('connection')) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    }
    return 'Impossible de créer la boutique. Réessayez.';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _danger, size: 18),
            const SizedBox(width: 10),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: _text))),
          ],
        ),
        backgroundColor: _surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: _border)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _stagger(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceAnim,
      builder: (_, __) {
        final start = index * 0.07;
        final end = (start + 0.5).clamp(0.0, 1.0);
        final t = _interval(_entranceAnim.value, start, end);
        return Opacity(
          opacity: t,
          child: Transform.translate(offset: Offset(0, 20 * (1 - t)), child: child),
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
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            _AmbientBackground(anim: _ambientAnim),
            LayoutBuilder(
              builder: (context, c) => c.maxWidth >= 900 ? _buildDesktopLayout() : _buildMobileLayout(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                _stagger(0, _buildHeader()),
                const SizedBox(height: 20),
                _stagger(1, _buildProgressSteps()),
                const SizedBox(height: 24),
                _stagger(2, _buildFormCard()),
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
          child: Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _stagger(0, _buildLogo(size: 72)),
                const SizedBox(height: 28),
                _stagger(1, Text(
                  'Bienvenue sur GIS Gestion',
                  style: GoogleFonts.plusJakartaSans(fontSize: 32, fontWeight: FontWeight.w800, color: _text, letterSpacing: -0.8),
                )),
                const SizedBox(height: 10),
                _stagger(2, Text(
                  'Quelques informations pour\npersonnaliser votre espace.',
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, color: _textMute, height: 1.5),
                )),
                const SizedBox(height: 32),
                _stagger(3, _buildFeatureList()),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            decoration: BoxDecoration(
              color: _surface.withValues(alpha: 0.9),
              border: const Border(left: BorderSide(color: _border)),
            ),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _stagger(0, _buildHeader(compact: true)),
                      const SizedBox(height: 20),
                      _stagger(1, _buildProgressSteps()),
                      const SizedBox(height: 24),
                      _stagger(2, _buildFormCard(bordered: false)),
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

  Widget _buildFeatureList() {
    const items = [
      (Icons.store_rounded, 'Identité boutique', 'Nom et propriétaire'),
      (Icons.payments_rounded, 'Devise FCFA', 'Prix et totaux en franc CFA'),
      (Icons.location_on_outlined, 'Contact', 'Téléphone et adresse optionnels'),
    ];
    return Column(
      children: items.map((f) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _accent.withValues(alpha: 0.2)),
                ),
                child: Icon(f.$1, color: _accentSoft, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(f.$2, style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(f.$3, style: const TextStyle(color: _textDim, fontSize: 11)),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogo({double size = 100}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FD4)]),
        borderRadius: BorderRadius.circular(size * 0.28),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.26),
        child: Image.asset(
          'assets/images/logo_guiss_gestion1.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(Icons.store_rounded, size: size * 0.45, color: Colors.white),
        ),
      ),
    );
  }

  Widget _buildHeader({bool compact = false}) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 10 : 12),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _accent.withValues(alpha: 0.25)),
          ),
          child: Icon(Icons.store_rounded, color: _accentSoft, size: compact ? 20 : 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuration boutique',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: compact ? 18 : 20,
                  fontWeight: FontWeight.w800,
                  color: _text,
                  letterSpacing: -0.3,
                ),
              ),
              Text('Étape obligatoire après inscription', style: TextStyle(fontSize: compact ? 11 : 12, color: _textMute)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSteps() {
    const labels = ['Identité', 'Devise', 'Contact'];
    return Row(
      children: List.generate(labels.length, (i) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: i < labels.length - 1 ? 8 : 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 6),
                Text(labels[i], style: const TextStyle(color: _textDim, fontSize: 9, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildFormCard({bool bordered = true}) {
    final form = _buildForm();
    if (!bordered) return form;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
      ),
      child: form,
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informations générales'),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _nomBoutiqueController,
            label: 'Nom de la boutique *',
            hint: 'Ex: Boutique Cheikh',
            icon: Icons.store_rounded,
            textInputAction: TextInputAction.next,
            validator: (v) => v == null || v.trim().isEmpty ? 'Nom requis' : null,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _proprietaireController,
            label: 'Nom du propriétaire',
            hint: 'Ex: Cheikh Diallo',
            icon: Icons.person_rounded,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 22),
          _buildSectionTitle('Devise'),
          const SizedBox(height: 12),
          _buildCurrencySelector(),
          const SizedBox(height: 22),
          _buildSectionTitle('Contact (optionnel)'),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            hint: 'Ex: 77 123 45 67',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse',
            hint: 'Ex: Dakar, Sacré-Cœur',
            icon: Icons.location_on_rounded,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _saveBoutique(),
          ),
          const SizedBox(height: 28),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 3, height: 16, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: _textMute)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textDim)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(fontSize: 14, color: _text),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: _textDim),
            filled: true,
            fillColor: _surfaceHi,
            prefixIcon: Icon(icon, size: 18, color: _accentSoft),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surfaceHi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FD4)]),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('F', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Franc CFA', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _text)),
              Text('Devise par défaut · FCFA', style: TextStyle(fontSize: 11, color: _textMute)),
            ],
          ),
          const Spacer(),
          Icon(Icons.check_circle_rounded, color: _accentSoft, size: 22),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    final isDone = _savePhase == 2;
    final isSaving = _savePhase == 1;

    return Container(
      height: 50,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDone
              ? [_success, const Color(0xFF16A34A)]
              : isSaving
                  ? [_textDim, _textDim]
                  : [_accent, const Color(0xFF5B3FD4)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: isSaving || isDone
            ? null
            : [BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _saveBoutique,
          borderRadius: BorderRadius.circular(12),
          child: Center(
            child: isSaving
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                      const SizedBox(width: 12),
                      Text('Création...', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
                    ],
                  )
                : isDone
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                          const SizedBox(width: 8),
                          Text('Boutique créée !', style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700)),
                        ],
                      )
                    : Text(
                        'Créer ma boutique',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                      ),
          ),
        ),
      ),
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
        final pulse = 0.65 + anim.value * 0.35;
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -60,
                left: -40,
                child: Container(
                  width: 200 * pulse,
                  height: 200 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF7C5CFF).withValues(alpha: 0.18), Colors.transparent]),
                  ),
                ),
              ),
              Positioned(
                bottom: 80,
                right: -50,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(colors: [const Color(0xFF22C55E).withValues(alpha: 0.08), Colors.transparent]),
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
