import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SetupBoutiquePage extends StatefulWidget {
  const SetupBoutiquePage({super.key});

  @override
  State<SetupBoutiquePage> createState() => _SetupBoutiquePageState();
}

class _SetupBoutiquePageState extends State<SetupBoutiquePage> {
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
  final _nomBoutiqueController = TextEditingController();
  final _proprietaireController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _adresseController = TextEditingController();

  bool _isLoading = false;
  String _selectedDevise = 'FCFA';
  int _currentStep = 0;

  @override
  void dispose() {
    _nomBoutiqueController.dispose();
    _proprietaireController.dispose();
    _telephoneController.dispose();
    _adresseController.dispose();
    super.dispose();
  }

  Future<void> _saveBoutique() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _currentStep = 1;
    });

    HapticFeedback.mediumImpact();

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) throw Exception("Utilisateur non connecté");

      await Supabase.instance.client.from('shops').insert({
        'owner_id': userId,
        'nom_boutique': _nomBoutiqueController.text.trim(),
        'proprietaire': _proprietaireController.text.trim().isEmpty ? null : _proprietaireController.text.trim(),
        'telephone': _telephoneController.text.trim().isEmpty ? null : _telephoneController.text.trim(),
        'adresse': _adresseController.text.trim().isEmpty ? null : _adresseController.text.trim(),
        'devise': _selectedDevise,
      });

      if (mounted) {
        setState(() => _currentStep = 2);
        await Future.delayed(const Duration(milliseconds: 600));
        Navigator.of(context).pushReplacementNamed('/onboarding-tour');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _currentStep = 0;
        });
        _showErrorSnackBar('Échec de la configuration: ${e.toString().split(':').first}');
      }
    }
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
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildForm(),
          ],
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
                  _buildLogo(),
                  const SizedBox(height: 32),
                  const Text('Bienvenue', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _text, letterSpacing: -0.5)),
                  const SizedBox(height: 12),
                  Text('Configurez votre boutique\ndès maintenant', style: TextStyle(fontSize: 14, color: _textMute, height: 1.4), textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderDesktop(),
                const SizedBox(height: 32),
                _buildForm(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLogo({double size = 120}) {
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

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(14), border: Border.all(color: _accent.withOpacity(0.2))),
          child: Icon(Icons.store_rounded, color: _accent, size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Configuration', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _text, letterSpacing: -0.3)),
              Text('Créez votre boutique', style: TextStyle(fontSize: 13, color: _textMute)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderDesktop() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _accent.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: _accent.withOpacity(0.2))),
          child: Icon(Icons.store_rounded, color: _accent, size: 22),
        ),
        const SizedBox(width: 14),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('Configuration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _text, letterSpacing: -0.3)),
            Text('Créez votre boutique', style: TextStyle(fontSize: 12, color: _textMute)),
          ],
        ),
      ],
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Informations générales'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nomBoutiqueController,
            label: 'Nom de la boutique',
            hint: 'Ex: Boutique Cheikh',
            icon: Icons.store_rounded,
            validator: (v) => v == null || v.isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _proprietaireController,
            label: 'Nom du propriétaire',
            hint: 'Ex: Cheikh Diallo',
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Devise'),
          const SizedBox(height: 16),
          _buildCurrencySelector(),
          const SizedBox(height: 24),
          _buildSectionTitle('Contact'),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _telephoneController,
            label: 'Téléphone',
            hint: 'Ex: 77 123 45 67',
            icon: Icons.phone_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 14),
          _buildTextField(
            controller: _adresseController,
            label: 'Adresse',
            hint: 'Ex: Dakar, Sacré-Cœur',
            icon: Icons.location_on_rounded,
          ),
          const SizedBox(height: 32),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(width: 4, height: 18, decoration: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 10),
        Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _textMute)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
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
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _text),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(fontSize: 12, color: _textDim),
            filled: true,
            fillColor: _surfaceHi,
            prefixIcon: Icon(icon, size: 18, color: _accent),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _accent)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySelector() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedDevise = 'FCFA');
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceHi,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _accent),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FE6)]), borderRadius: BorderRadius.circular(10)),
              child: const Center(child: Text('F', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white))),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Franc CFA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _text)),
                Text('FCFA', style: TextStyle(fontSize: 12, color: _textMute)),
              ],
            ),
            const Spacer(),
            Icon(Icons.check_circle_rounded, color: _accent, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveBoutique,
        style: ElevatedButton.styleFrom(
          backgroundColor: _accent,
          disabledBackgroundColor: _surfaceHi,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? (_currentStep == 1
                ? const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
                    SizedBox(width: 12),
                    Text('Configuration...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ])
                : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Boutique créée !', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ]))
            : const Text('Créer ma boutique', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
      ),
    );
  }
}