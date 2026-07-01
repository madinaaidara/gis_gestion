import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/shops_repository.dart';
import '../../../data/repositories/abonnement_repository.dart';
import '../abonnement/abonnement_page.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> with SingleTickerProviderStateMixin {
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

  String _userName = 'Utilisateur';
  String _userEmail = '';
  String? _userPhone;
  String? _shopName;
  String? _shopAddress;
  String? _shopPhone;
  String? _shopOwner;
  String _devise = 'FCFA';
  bool _isLoading = true;

  late AnimationController _entranceController;
  late Animation<double> _entranceAnim;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _entranceAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _loadUserData();
    _loadAbonnement();
  }

  Future<void> _loadAbonnement() async {
    final shopId = context.read<ShopsRepository>().currentShop?.id;
    if (shopId != null) {
      await context.read<AbonnementRepository>().checkAbonnementStatus(shopId);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final email = currentUser.email ?? '';
      var nom = email.split('@').first;
      String? phone;

      try {
        final profileResponse = await Supabase.instance.client
            .from('profiles')
            .select('full_name, phone')
            .eq('id', currentUser.id)
            .maybeSingle();
        if (profileResponse != null) {
          nom = profileResponse['full_name']?.toString() ?? nom;
          phone = profileResponse['phone']?.toString();
        }
      } catch (e) {
        debugPrint('Erreur profil: $e');
      }

      String? boutique;
      String? adresse;
      String? telBoutique;
      String? proprietaire;
      var devise = 'FCFA';

      try {
        final shopResponse = await Supabase.instance.client
            .from('shops')
            .select('nom_boutique, adresse, telephone, proprietaire, devise')
            .eq('owner_id', currentUser.id)
            .maybeSingle();
        if (shopResponse != null) {
          boutique = shopResponse['nom_boutique']?.toString();
          adresse = shopResponse['adresse']?.toString();
          telBoutique = shopResponse['telephone']?.toString();
          proprietaire = shopResponse['proprietaire']?.toString();
          devise = shopResponse['devise']?.toString() ?? 'FCFA';
        }
      } catch (e) {
        debugPrint('Erreur boutique: $e');
      }

      if (mounted) {
        setState(() {
          _userName = nom;
          _userEmail = email;
          _userPhone = phone;
          _shopName = boutique;
          _shopAddress = adresse;
          _shopPhone = telBoutique;
          _shopOwner = proprietaire;
          _devise = devise;
          _isLoading = false;
        });
        _entranceController.forward(from: 0);
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _getInitiales() {
    if (_userName.isEmpty) return 'U';
    final parties = _userName.trim().split(' ');
    if (parties.length >= 2) return '${parties[0][0]}${parties[1][0]}'.toUpperCase();
    return _userName[0].toUpperCase();
  }

  Future<void> _editProfile() async {
    final nameCtrl = TextEditingController(text: _userName);
    final phoneCtrl = TextEditingController(text: _userPhone ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: Text('Modifier mon profil', style: GoogleFonts.plusJakartaSans(color: _text, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _dialogField(nameCtrl, 'Nom complet', Icons.person_outline),
            const SizedBox(height: 12),
            _dialogField(phoneCtrl, 'Téléphone', Icons.phone_outlined, keyboard: TextInputType.phone),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: _textMute))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _accent),
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      await Supabase.instance.client.from('profiles').upsert({
        'id': userId,
        'full_name': nameCtrl.text.trim(),
        'phone': phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      });
      HapticFeedback.lightImpact();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil mis à jour'), backgroundColor: _success),
        );
        await _loadUserData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: _danger),
        );
      }
    }
  }

  Widget _dialogField(TextEditingController ctrl, String label, IconData icon, {TextInputType? keyboard}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboard,
      style: const TextStyle(color: _text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textMute),
        prefixIcon: Icon(icon, color: _accentSoft, size: 20),
        filled: true,
        fillColor: _surfaceHi,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _accent)),
      ),
    );
  }

  Future<void> _deconnecter() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: _border)),
        title: Text('Déconnexion', style: GoogleFonts.plusJakartaSans(color: _text, fontWeight: FontWeight.w700)),
        content: const Text('Voulez-vous vraiment vous déconnecter ?', style: TextStyle(color: _textMute)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler', style: TextStyle(color: _textMute))),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _danger),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );

    if (confirmer == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  Widget _stagger(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceAnim,
      builder: (_, __) {
        final start = index * 0.08;
        final end = start + 0.5;
        final t = _interval(_entranceAnim.value, start, end.clamp(0.0, 1.0));
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
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2))
            : RefreshIndicator(
                onRefresh: _loadUserData,
                color: _accent,
                backgroundColor: _surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _stagger(0, _buildHeader()),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: _stagger(1, _buildUserCard()),
                      ),
                    ),
                    if (_shopName != null)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _stagger(2, _buildShopCard()),
                        ),
                      ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _stagger(3, _buildAbonnementCard()),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: _stagger(4, _buildActionsCard()),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _stagger(5, _buildDeconnexionBtn()),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_accent.withValues(alpha: 0.2), _surfaceHi, _surface],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(color: _accent.withValues(alpha: 0.12), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_accent, Color(0xFF5B3FD4)]),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(color: _accent.withValues(alpha: 0.4), blurRadius: 16, offset: const Offset(0, 6)),
              ],
            ),
            child: Center(
              child: Text(
                _getInitiales(),
                style: GoogleFonts.plusJakartaSans(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 22, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(_userEmail, style: const TextStyle(color: _textMute, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _panel({required String title, required IconData icon, required Color iconColor, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(title, style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accentSoft, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: _textDim, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard() {
    return _panel(
      title: 'Informations personnelles',
      icon: Icons.person_outline,
      iconColor: _accentSoft,
      children: [
        _infoRow(Icons.email_outlined, 'Email', _userEmail),
        if (_userPhone != null && _userPhone!.isNotEmpty)
          _infoRow(Icons.phone_outlined, 'Téléphone', _userPhone!),
      ],
    );
  }

  Widget _buildShopCard() {
    final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
    final shop = shopRepo.currentShop;

    return _panel(
      title: 'Ma boutique',
      icon: Icons.store_outlined,
      iconColor: _success,
      children: [
        _infoRow(Icons.badge_outlined, 'Nom', _shopName ?? '-'),
        if (_shopOwner != null && _shopOwner!.isNotEmpty)
          _infoRow(Icons.person_outline, 'Propriétaire', _shopOwner!),
        if (_shopPhone != null && _shopPhone!.isNotEmpty)
          _infoRow(Icons.phone_outlined, 'Téléphone boutique', _shopPhone!),
        if (_shopAddress != null && _shopAddress!.isNotEmpty)
          _infoRow(Icons.location_on_outlined, 'Adresse', _shopAddress!),
        _infoRow(Icons.payments_outlined, 'Devise', shop?.devise ?? _devise),
      ],
    );
  }

  Widget _buildAbonnementCard() {
    final abo = context.watch<AbonnementRepository>().currentAbonnement;
    final valid = abo?.isValid ?? false;

    return _panel(
      title: 'Abonnement Gis Gestion',
      icon: Icons.workspace_premium_outlined,
      iconColor: _accentSoft,
      children: [
        _infoRow(
          Icons.verified_outlined,
          'Statut',
          valid ? 'Actif · ${abo!.planLabel}' : 'Expiré ou inactif',
        ),
        if (abo != null && valid)
          _infoRow(Icons.timer_outlined, 'Jours restants', '${abo.daysRemaining} jour(s)'),
        _actionTile(Icons.card_membership_outlined, 'Gérer mon abonnement', () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AbonnementPage()),
          );
        }),
      ],
    );
  }

  Widget _buildActionsCard() {
    return _panel(
      title: 'Actions',
      icon: Icons.settings_outlined,
      iconColor: _textMute,
      children: [
        _actionTile(Icons.edit_outlined, 'Modifier mon profil', _editProfile),
        _actionTile(Icons.refresh_rounded, 'Actualiser les données', _loadUserData),
        _actionTile(Icons.help_outline, 'Aide et support', () async {
          final uri = Uri.parse('mailto:support@gisgestion.app?subject=Support%20Gis%20Gestion');
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        }),
        _actionTile(Icons.info_outline, 'À propos', () {
          showAboutDialog(
            context: context,
            applicationName: 'Gis Gestion',
            applicationVersion: '1.0.0',
            applicationLegalese: '© ${DateTime.now().year} Gis Gestion\nSolution de gestion commerciale pour boutiques.',
          );
        }),
      ],
    );
  }

  Widget _actionTile(IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: _accentSoft, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(label, style: const TextStyle(color: _text, fontSize: 14))),
              const Icon(Icons.chevron_right_rounded, color: _textDim, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeconnexionBtn() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: _deconnecter,
        style: FilledButton.styleFrom(
          backgroundColor: _danger,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        icon: const Icon(Icons.logout_rounded, color: Colors.white),
        label: Text(
          'Se déconnecter',
          style: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
    );
  }
}
