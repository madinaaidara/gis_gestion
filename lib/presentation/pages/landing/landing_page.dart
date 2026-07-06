import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/utils/responsive_utils.dart';
import '../auth/login_page.dart';

/// Assets landing — captures émulateur réelles.
abstract final class LandingAssets {
  static const logo = 'assets/images/logo_guiss_gestion1.png';

  static const ac1 = 'assets/images/ac1.png';
  static const pro1 = 'assets/images/pro1.png';
  static const ven1 = 'assets/images/ven1.png';
  static const cre1 = 'assets/images/cre1.png';
  static const his1 = 'assets/images/his1.png';
  static const sta1 = 'assets/images/sta1.png';

  /// Ordre du carrousel hero : Accueil → Produits → Caisse → Crédits → Historique → Stats.
  static const carouselScreens = [ac1, pro1, ven1, cre1, his1, sta1];

  static const carouselLabels = [
    'Accueil',
    'Produits',
    'Caisse',
    'Crédits',
    'Historique',
    'Statistiques',
  ];

  /// Captures site desktop (section Outils clés).
  static const desktopAccueil = 'assets/images/acceuil.png';
  static const desktopProduits = 'assets/images/produits.png';
  static const desktopStats = 'assets/images/stats.png';
  static const desktopVentes = 'assets/images/ventes.png';
}

Widget _landingImage(String asset, {BoxFit fit = BoxFit.cover}) {
  return Image.asset(
    asset,
    fit: fit,
    gaplessPlayback: true,
    errorBuilder: (_, __, ___) => Container(
      color: const Color(0xFFF3F4F6),
      alignment: Alignment.center,
      child: const Icon(Icons.image_not_supported_outlined, color: Color(0xFF9CA3AF), size: 36),
    ),
  );
}

/// Landing publique Gis Gestion — boutiques au Sénégal.
class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  static const _green = Color(0xFF22C55E);
  static const _greenDark = Color(0xFF16A34A);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _surface = Color(0xFFF9FAFB);
  static const _border = Color(0xFFE5E7EB);

  final _scroll = ScrollController();
  final _featuresKey = GlobalKey();
  final _pricingKey = GlobalKey();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      alignment: 0.08,
    );
  }

  void _goLogin({bool signUp = false}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => LoginPage(initialSignUp: signUp)),
    );
  }

  Future<void> _contact() async {
    final uri = Uri.parse('mailto:support@gisgestion.app?subject=Gis%20Gestion%20-%20Contact');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final isWide = ResponsiveUtils.isTwoColumnWide(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scroll,
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _LandingHeaderDelegate(
              onHome: () => _scroll.animateTo(0, duration: const Duration(milliseconds: 500), curve: Curves.easeOut),
              onFeatures: () => _scrollTo(_featuresKey),
              onPricing: () => _scrollTo(_pricingKey),
              onLogin: () => _goLogin(),
              onTrial: () => _goLogin(signUp: true),
              onContact: _contact,
            ),
          ),
          SliverToBoxAdapter(child: _buildHero(isWide)),
          SliverToBoxAdapter(child: _buildTrustBand(isWide)),
          SliverToBoxAdapter(child: _buildKeyTools(isWide)),
          SliverToBoxAdapter(child: _buildSteps(isWide)),
          SliverToBoxAdapter(child: _buildPricing(isWide)),
          SliverToBoxAdapter(child: _buildFinalCta(isWide)),
          SliverToBoxAdapter(child: _buildFooter(isWide)),
        ],
      ),
    );
  }

  Widget _buildHero(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 32, isWide ? 48 : 20, 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: _green.withValues(alpha: 0.25)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🇸🇳', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 8),
                Text(
                  'Conçu pour les boutiques au Sénégal',
                  style: TextStyle(color: _greenDark, fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'La gestion complète\nde votre boutique',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: _text,
              fontSize: isWide ? 48 : 32,
              fontWeight: FontWeight.w800,
              height: 1.1,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              'Caisse, stock, crédits clients et statistiques — en FCFA, sur web et mobile. '
              'Tout ce dont votre commerce a besoin, dans une seule application.',
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: isWide ? 17 : 15, height: 1.55),
            ),
          ),
          const SizedBox(height: 28),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              _primaryButton('Commencer l\'essai gratuit', () => _goLogin(signUp: true), large: true),
              _outlineButton('Voir les outils clés', () => _scrollTo(_featuresKey), large: true),
            ],
          ),
          const SizedBox(height: 40),
          _phoneShowcase(isWide),
        ],
      ),
    );
  }

  Widget _phoneShowcase(bool isWide) {
    return _LandingScreenshotCarousel(height: isWide ? 420 : 320);
  }

  Widget _buildTrustBand(bool isWide) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: isWide ? 28 : 20),
      color: _surface,
      child: Column(
        children: [
          Text(
            'PENSÉ POUR LE COMMERCE DE PROXIMITÉ',
            style: TextStyle(
              color: _muted.withValues(alpha: 0.8),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 24,
            runSpacing: 8,
            children: [
              _trustItem(Icons.payments_rounded, 'FCFA natif'),
              _trustItem(Icons.cloud_done_rounded, 'Données cloud'),
              _trustItem(Icons.devices_rounded, 'Web & mobile'),
              _trustItem(Icons.storefront_rounded, 'Multi-produits'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _trustItem(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: _green),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildKeyTools(bool isWide) {
    const tools = [
      _KeyToolData(
        title: 'Accueil',
        subtitle: 'Tableau de bord',
        description:
            'CA du jour, ventes récentes, alertes stock et accès rapide à la caisse — tout en un coup d\'œil.',
        image: LandingAssets.desktopAccueil,
        icon: Icons.dashboard_rounded,
        accent: Color(0xFF22C55E),
      ),
      _KeyToolData(
        title: 'Produits',
        subtitle: 'Catalogue & stock',
        description:
            'Gérez votre catalogue, catégories, prix en FCFA et niveaux de stock avec recherche instantanée.',
        image: LandingAssets.desktopProduits,
        icon: Icons.inventory_2_rounded,
        accent: Color(0xFF3B82F6),
      ),
      _KeyToolData(
        title: 'Statistiques',
        subtitle: 'Pilotage & marges',
        description:
            'Graphiques d\'évolution, marges, top produits et analyses sur 7 jours, 30 jours ou 12 mois.',
        image: LandingAssets.desktopStats,
        icon: Icons.bar_chart_rounded,
        accent: Color(0xFF8B5CF6),
      ),
      _KeyToolData(
        title: 'Ventes',
        subtitle: 'Caisse POS',
        description:
            'Encaissez en espèces ou à crédit, modifiez prix et quantités à la volée — pensé pour vendre vite.',
        image: LandingAssets.desktopVentes,
        icon: Icons.point_of_sale_rounded,
        accent: Color(0xFFF97316),
      ),
    ];

    return Container(
      key: _featuresKey,
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 56, isWide ? 48 : 20, 48),
      color: _surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionBadge('OUTILS CLÉS'),
          const SizedBox(height: 16),
          Text(
            isWide ? 'Tout votre commerce,\ndepuis un seul écran.' : 'Tout votre commerce, depuis un seul écran.',
            style: GoogleFonts.plusJakartaSans(
              color: _text,
              fontSize: isWide ? 36 : 26,
              fontWeight: FontWeight.w800,
              height: 1.15,
              letterSpacing: isWide ? -0.8 : -0.4,
            ),
          ),
          const SizedBox(height: 10),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 560 : double.infinity),
            child: Text(
              'Interface web complète sur desktop, app mobile au comptoir — même données, même boutique.',
              style: TextStyle(color: _muted, fontSize: isWide ? 16 : 15, height: 1.55),
            ),
          ),
          SizedBox(height: isWide ? 48 : 32),
          for (var i = 0; i < tools.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i < tools.length - 1 ? (isWide ? 56 : 36) : 0),
              child: _keyToolBlock(tools[i], isWide: isWide, imageOnRight: i.isOdd),
            ),
        ],
      ),
    );
  }

  Widget _keyToolBlock(_KeyToolData tool, {required bool isWide, required bool imageOnRight}) {
    final text = _keyToolCopy(tool, isWide: isWide);
    final frame = _desktopBrowserFrame(tool.image, isWide: isWide);

    if (!isWide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          text,
          const SizedBox(height: 16),
          frame,
        ],
      );
    }

    final image = Expanded(flex: 11, child: frame);
    final copy = Expanded(flex: 9, child: text);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: imageOnRight
          ? [copy, const SizedBox(width: 40), image]
          : [image, const SizedBox(width: 40), copy],
    );
  }

  Widget _keyToolCopy(_KeyToolData tool, {required bool isWide}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: tool.accent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(tool.icon, size: 14, color: tool.accent),
              const SizedBox(width: 6),
              Text(
                tool.subtitle.toUpperCase(),
                style: TextStyle(
                  color: tool.accent,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          tool.title,
          style: GoogleFonts.plusJakartaSans(
            color: _text,
            fontSize: isWide ? 28 : 22,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.6,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tool.description,
          style: TextStyle(color: _muted, fontSize: isWide ? 15 : 14, height: 1.6),
        ),
      ],
    );
  }

  Widget _desktopBrowserFrame(String asset, {required bool isWide}) {
    const chromeH = 36.0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isWide ? 16 : 14),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isWide ? 0.1 : 0.08),
            blurRadius: isWide ? 32 : 20,
            offset: Offset(0, isWide ? 16 : 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: chromeH,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6),
              border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
            ),
            child: Row(
              children: [
                _browserDot(const Color(0xFFEF4444)),
                const SizedBox(width: 5),
                _browserDot(const Color(0xFFF59E0B)),
                const SizedBox(width: 5),
                _browserDot(const Color(0xFF22C55E)),
                const SizedBox(width: 12),
                Expanded(
                  child: Container(
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Text(
                      'app.gisgestion.app',
                      style: TextStyle(color: _muted.withValues(alpha: 0.85), fontSize: 10, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AspectRatio(
            aspectRatio: isWide ? 16 / 10 : 16 / 11,
            child: _landingImage(asset, fit: BoxFit.cover),
          ),
        ],
      ),
    );
  }

  Widget _browserDot(Color color) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }

  Widget _buildSteps(bool isWide) {
    const steps = [
      ('1', 'Créez votre boutique', 'Inscription en 2 minutes, nom et devise FCFA.'),
      ('2', 'Ajoutez vos produits', 'Catalogue, prix, stock et catégories.'),
      ('3', 'Vendez & suivez', 'Encaissez à la caisse et consultez vos stats.'),
    ];

    return Container(
      color: _surface,
      padding: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20, vertical: 48),
      child: Column(
        children: [
          _sectionBadge('COMMENT ÇA MARCHE'),
          const SizedBox(height: 20),
          Text(
            'Opérationnel en 3 étapes',
            style: GoogleFonts.plusJakartaSans(
              color: _text,
              fontSize: isWide ? 32 : 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 32),
          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(width: 24),
                  Expanded(child: _stepCard(steps[i].$1, steps[i].$2, steps[i].$3)),
                ],
              ],
            )
          else
            Column(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0) const SizedBox(height: 16),
                  _stepCard(steps[i].$1, steps[i].$2, steps[i].$3),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Widget _stepCard(String num, String title, String desc) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(num, style: TextStyle(color: _greenDark, fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 12),
          Text(title, style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(desc, style: TextStyle(color: _muted, fontSize: 13, height: 1.45)),
        ],
      ),
    );
  }

  Widget _buildPricing(bool isWide) {
    return Container(
      key: _pricingKey,
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 56, isWide ? 48 : 20, 56),
      child: Column(
        children: [
          _sectionBadge('TARIFS'),
          const SizedBox(height: 16),
          Text(
            'Simple et transparent',
            style: GoogleFonts.plusJakartaSans(
              color: _text,
              fontSize: isWide ? 32 : 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Essayez gratuitement, puis un abonnement unique par boutique.',
            style: TextStyle(color: _muted, fontSize: 15),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _green.withValues(alpha: 0.35), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: _green.withValues(alpha: 0.08),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Gis Gestion — Boutique',
                    style: GoogleFonts.plusJakartaSans(
                      color: _text,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    '0 FCFA',
                    style: GoogleFonts.plusJakartaSans(
                      color: _green,
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                    ),
                  ),
                  Text(
                    'pendant 30 jours',
                    style: TextStyle(color: _muted, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  Container(height: 1, color: _border),
                  const SizedBox(height: 16),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(color: _muted, fontSize: 14),
                      children: [
                        const TextSpan(text: 'puis '),
                        TextSpan(
                          text: '9 900 FCFA',
                          style: GoogleFonts.plusJakartaSans(
                            color: _text,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const TextSpan(text: ' / mois'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...[
                    'Caisse & ventes illimitées',
                    'Gestion stock & produits',
                    'Crédits & historique',
                    'Statistiques & tableau de bord',
                    '1 boutique · Web & mobile',
                  ].map(
                    (t) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 18, color: _green),
                          const SizedBox(width: 10),
                          Expanded(child: Text(t, style: TextStyle(color: _text, fontSize: 13))),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: _primaryButton('Commencer l\'essai gratuit', () => _goLogin(signUp: true)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sans engagement · Annulable à tout moment',
                    style: TextStyle(color: _muted, fontSize: 11),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalCta(bool isWide) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isWide ? 48 : 20),
      padding: EdgeInsets.all(isWide ? 48 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_green, _greenDark],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            'Prêt à gérer votre boutique\ncomme un pro ?',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white,
              fontSize: isWide ? 32 : 24,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '30 jours gratuits · Puis 9 900 FCFA/mois',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 15),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              FilledButton(
                onPressed: () => _goLogin(signUp: true),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: _greenDark,
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Créer ma boutique', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              OutlinedButton(
                onPressed: () => _goLogin(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Se connecter'),
              ),
            ],
          ),
        ],
      ),
    );
  }
  

  Widget _buildFooter(bool isWide) {
    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 48 : 20, 48, isWide ? 48 : 20, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 42,
                height: 42,
                child: _landingImage(LandingAssets.logo, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Text(
                'Gis Gestion',
                style: GoogleFonts.plusJakartaSans(
                  color: _text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Gestion de boutique · Sénégal · FCFA',
            style: TextStyle(color: _muted, fontSize: 12),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: _contact, child: Text('Contact', style: TextStyle(color: _muted))),
          const SizedBox(height: 8),
          Text(
            '© ${DateTime.now().year} Gis Gestion. Tous droits réservés.',
            style: TextStyle(color: _muted.withValues(alpha: 0.7), fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _sectionBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(color: _greenDark, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8),
      ),
    );
  }

  Widget _primaryButton(String label, VoidCallback onTap, {bool large = false}) {
    return FilledButton(
      onPressed: onTap,
      style: FilledButton.styleFrom(
        backgroundColor: _green,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: large ? 28 : 20, vertical: large ? 16 : 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(width: 6),
          const Icon(Icons.arrow_forward_rounded, size: 18),
        ],
      ),
    );
  }

  Widget _outlineButton(String label, VoidCallback onTap, {bool large = false}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        padding: EdgeInsets.symmetric(horizontal: large ? 28 : 20, vertical: large ? 16 : 12),
        side: const BorderSide(color: _border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }
}

/// Carrousel arc auto — téléphone central net, côtés réduits et floutés (style Pointel).
class _LandingScreenshotCarousel extends StatefulWidget {
  const _LandingScreenshotCarousel({required this.height});

  final double height;

  @override
  State<_LandingScreenshotCarousel> createState() => _LandingScreenshotCarouselState();
}

class _LandingScreenshotCarouselState extends State<_LandingScreenshotCarousel> {
  static const _border = Color(0xFFE5E7EB);
  static const _green = Color(0xFF22C55E);

  PageController? _pageController;
  Timer? _timer;
  int _index = 0;
  double _viewportFraction = 0.28;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final vf = wide ? 0.22 : 0.38;
    if (_pageController == null || _viewportFraction != vf) {
      _viewportFraction = vf;
      final page = _pageController?.hasClients == true ? (_pageController!.page?.round() ?? 0) : 0;
      _pageController?.dispose();
      _pageController = PageController(viewportFraction: vf, initialPage: page);
    }
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 1800), (_) => _next());
  }

  void _next() {
    if (!mounted || _pageController == null || !_pageController!.hasClients) return;
    final current = _pageController!.page?.round() ?? _index;
    final next = (current + 1) % LandingAssets.carouselScreens.length;
    _pageController!.animateToPage(
      next,
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Widget _phoneShell(String asset, double height) {
    final w = height * 9 / 19;
    return Container(
      width: w,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: _border, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.14),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: _landingImage(asset, fit: BoxFit.cover),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _pageController;
    if (controller == null) return SizedBox(height: widget.height + 48);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: widget.height + 36,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: 0,
                right: 0,
                top: widget.height * 0.42,
                child: CustomPaint(
                  size: Size(MediaQuery.sizeOf(context).width, 56),
                  painter: _LandingWavePainter(color: _green.withValues(alpha: 0.45)),
                ),
              ),
              PageView.builder(
                controller: controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _index = i),
                itemCount: LandingAssets.carouselScreens.length,
                itemBuilder: (context, index) {
                  return AnimatedBuilder(
                    animation: controller,
                    builder: (context, _) {
                      final page = controller.hasClients && controller.position.haveDimensions
                          ? controller.page ?? _index.toDouble()
                          : _index.toDouble();
                      final dist = (page - index).abs().clamp(0.0, 2.5);
                      final focus = (1 - dist / 2.5).clamp(0.0, 1.0);
                      final scale = 0.68 + focus * 0.32;
                      final blur = (1 - focus) * 6.0;
                      final opacity = 0.35 + focus * 0.65;
                      final tilt = (page - index) * 0.07;

                      return Opacity(
                        opacity: opacity,
                        child: Transform.translate(
                          offset: Offset(0, (1 - focus) * 18),
                          child: Transform.rotate(
                            angle: tilt,
                            child: Transform.scale(
                              scale: scale,
                              child: ImageFiltered(
                                imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                                child: _phoneShell(LandingAssets.carouselScreens[index], widget.height),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          LandingAssets.carouselLabels[_index],
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _LandingWavePainter extends CustomPainter {
  _LandingWavePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    const steps = 40;
    for (var i = 0; i <= steps; i++) {
      final t = i / steps;
      final x = size.width * t;
      final y = size.height * 0.5 + math.sin(t * math.pi * 2) * 14;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _LandingWavePainter oldDelegate) => false;
}

class _KeyToolData {
  final String title;
  final String subtitle;
  final String description;
  final String image;
  final IconData icon;
  final Color accent;

  const _KeyToolData({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.image,
    required this.icon,
    required this.accent,
  });
}

class _LandingHeaderDelegate extends SliverPersistentHeaderDelegate {
  _LandingHeaderDelegate({
    required this.onHome,
    required this.onFeatures,
    required this.onPricing,
    required this.onLogin,
    required this.onTrial,
    required this.onContact,
  });

  final VoidCallback onHome;
  final VoidCallback onFeatures;
  final VoidCallback onPricing;
  final VoidCallback onLogin;
  final VoidCallback onTrial;
  final VoidCallback onContact;

  static const _green = Color(0xFF22C55E);
  static const _text = Color(0xFF111827);

  @override
  double get minExtent => 76;

  @override
  double get maxExtent => 76;

  Widget _navLink(String label, VoidCallback onTap) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: _text,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final hPad = isWide ? 48.0 : 16.0;

    return SizedBox(
      height: maxExtent,
      child: Material(
        color: Colors.white.withValues(alpha: overlapsContent ? 0.97 : 1),
        elevation: overlapsContent ? 1 : 0,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: Colors.black.withValues(alpha: 0.06))),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 34,
                      height: 34,
                      child: _landingImage(LandingAssets.logo, fit: BoxFit.contain),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Gis Gestion',
                      style: GoogleFonts.plusJakartaSans(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
                if (isWide)
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _navLink('Accueil', onHome),
                        _navLink('Outils clés', onFeatures),
                        _navLink('Tarifs', onPricing),
                        _navLink('Contact', onContact),
                      ],
                    ),
                  )
                else
                  const Spacer(),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isWide)
                      TextButton(
                        onPressed: onLogin,
                        style: TextButton.styleFrom(
                          foregroundColor: _text,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                        child: const Text('Connexion', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      ),
                    if (!isWide)
                      IconButton(
                        onPressed: onLogin,
                        icon: const Icon(Icons.login_rounded, size: 22, color: _text),
                        tooltip: 'Connexion',
                        visualDensity: VisualDensity.compact,
                      ),
                    const SizedBox(width: 6),
                    FilledButton(
                      onPressed: onTrial,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(horizontal: isWide ? 20 : 14, vertical: 10),
                        minimumSize: const Size(0, 40),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: Text(
                        isWide ? 'Essai gratuit' : 'Essai',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _LandingHeaderDelegate oldDelegate) => false;
}
