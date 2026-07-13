import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../../../core/theme/gis_palette.dart';
import '../../widgets/theme_toggle_button.dart';

class OnboardingTourPage extends StatefulWidget {
  const OnboardingTourPage({super.key});

  @override
  State<OnboardingTourPage> createState() => _OnboardingTourPageState();
}

class _OnboardingSlide {
  final String image;
  final String tag;
  final String title;
  final String subtitle;
  final List<String> bullets;
  final Color accent;

  const _OnboardingSlide({
    required this.image,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.bullets,
    required this.accent,
  });
}

class _OnboardingTourPageState extends State<OnboardingTourPage> with TickerProviderStateMixin {
  GisPalette get _p => GisPalette.of(context);

  final PageController _pageController = PageController();
  late AnimationController _contentController;

  int _currentPage = 0;
  double _pageOffset = 0;

  List<_OnboardingSlide> get _slides => [
        _OnboardingSlide(
          image: 'assets/images/ac1.png',
          tag: 'Tableau de bord',
          title: 'Pilotez votre\nboutique en direct',
          subtitle:
              'CA du jour, objectifs, alertes stock et actions rapides — tout est centralisé dès l\'ouverture.',
          bullets: const [
            'Indicateurs en temps réel',
            'Actions personnalisées',
            'Vue d\'ensemble instantanée',
          ],
          accent: _p.accent,
        ),
        _OnboardingSlide(
          image: 'assets/images/pro1.png',
          tag: 'Produits & Stock',
          title: 'Maîtrisez\nvotre inventaire',
          subtitle:
              'Catalogue, catégories, alertes rupture et réapprovisionnement — ne perdez plus de ventes faute de stock.',
          bullets: const [
            'Alertes rupture & stock faible',
            'Gestion par unités',
            'Mise à jour automatique',
          ],
          accent: _p.success,
        ),
        _OnboardingSlide(
          image: 'assets/images/ven1.png',
          tag: 'Caisse / Ventes',
          title: 'Encaissez\nen quelques secondes',
          subtitle:
              'Ventes comptant ou crédit, panier multi-produits et historique complet pour un suivi sans faille.',
          bullets: const [
            'Caisse ultra-rapide',
            'Ventes à crédit',
            'Restauration stock si annulation',
          ],
          accent: _p.warning,
        ),
        _OnboardingSlide(
          image: 'assets/images/sta1.png',
          tag: 'Statistiques',
          title: 'Décidez avec\nvos chiffres',
          subtitle:
              'Graphiques, calendrier des ventes, top produits et marges — comprenez ce qui fait grandir votre business.',
          bullets: const [
            'Graphiques & diagrammes',
            'Calendrier CA',
            'Top produits du mois',
          ],
          accent: const Color(0xFF06B6D4),
        ),
      ];

  @override
  void initState() {
    super.initState();
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _contentController.forward();
    _pageController.addListener(() {
      setState(() => _pageOffset = _pageController.page ?? 0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
    _contentController.forward(from: 0);
  }

  Future<void> _finishTour() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) Navigator.of(context).pushReplacementNamed('/navigation');
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeOutCubic);
    } else {
      _finishTour();
    }
  }

  SystemUiOverlayStyle get _overlayStyle {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return (isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
        .copyWith(statusBarColor: Colors.transparent);
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: _overlayStyle,
      child: Scaffold(
        backgroundColor: _p.bg,
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 12, 0),
                child: Row(
                  children: [
                    _TagChip(label: slide.tag, color: slide.accent, surface: _p.surface, border: _p.border),
                    const Spacer(),
                    const ThemeToggleButton(compact: true),
                    TextButton(
                      onPressed: _finishTour,
                      child: Text(
                        'Passer',
                        style: GoogleFonts.plusJakartaSans(
                          color: _p.textMute,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (_, index) => _buildImageSlide(index, isDark),
                ),
              ),
              _buildBottomPanel(slide, isLast, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlide(int index, bool isDark) {
    final slide = _slides[index];
    final delta = (_pageOffset - index).abs().clamp(0.0, 1.0);
    final scale = 1.0 - delta * 0.06;
    final opacity = 1.0 - delta * 0.25;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (_, __) {
        return Center(
          child: Transform.scale(
            scale: scale,
            child: Opacity(
              opacity: opacity,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(28, 12, 28, 8),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 320, maxHeight: 520),
                  decoration: BoxDecoration(
                    color: isDark ? _p.surfaceHi : _p.surface,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: _p.borderStrong.withValues(alpha: isDark ? 0.5 : 1)),
                    boxShadow: [
                      BoxShadow(
                        color: _p.accent.withValues(alpha: isDark ? 0.18 : 0.1),
                        blurRadius: 32,
                        offset: const Offset(0, 14),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(
                        slide.image,
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (_, __, ___) => ColoredBox(
                          color: slide.accent.withValues(alpha: 0.08),
                          child: Icon(
                            Icons.smartphone_rounded,
                            size: 56,
                            color: slide.accent.withValues(alpha: 0.45),
                          ),
                        ),
                      ),
                      if (!isDark)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.65),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomPanel(_OnboardingSlide slide, bool isLast, bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(top: BorderSide(color: _p.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.paddingOf(context).bottom + 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SmoothPageIndicator(
              controller: _pageController,
              count: _slides.length,
              effect: ExpandingDotsEffect(
                dotHeight: 4,
                dotWidth: 8,
                expansionFactor: 3.5,
                spacing: 6,
                activeDotColor: slide.accent,
                dotColor: _p.borderStrong,
              ),
            ),
            const SizedBox(height: 20),
            FadeTransition(
              opacity: CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
                  CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      slide.title,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: _p.text,
                        height: 1.12,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      slide.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        color: _p.textMute,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...slide.bullets.map(
                      (b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 5),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: slide.accent, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                b,
                                style: TextStyle(
                                  color: _p.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildCta(slide, isLast),
          ],
        ),
      ),
    );
  }

  Widget _buildCta(_OnboardingSlide slide, bool isLast) {
    return Container(
      height: 52,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [slide.accent, slide.accent.withValues(alpha: 0.78)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: slide.accent.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _next,
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isLast ? 'Accéder à mon espace' : 'Continuer',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color surface;
  final Color border;

  const _TagChip({
    required this.label,
    required this.color,
    required this.surface,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
