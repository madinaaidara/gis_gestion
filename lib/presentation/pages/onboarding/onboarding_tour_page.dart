import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

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
  static const Color _bg = Color(0xFF050505);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);

  final PageController _pageController = PageController(viewportFraction: 1.0);
  late AnimationController _contentController;

  int _currentPage = 0;
  double _pageOffset = 0;

  static const _slides = [
    _OnboardingSlide(
      image: 'assets/images/onboarding_dashboard.png',
      tag: 'Tableau de bord',
      title: 'Pilotez votre\nboutique en direct',
      subtitle: 'CA du jour, objectifs, alertes stock et actions rapides — tout est centralisé dès l\'ouverture.',
      bullets: ['Indicateurs en temps réel', 'Actions personnalisées', 'Vue d\'ensemble instantanée'],
      accent: Color(0xFF7C5CFF),
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_produits.png',
      tag: 'Produits & Stock',
      title: 'Maîtrisez\nvotre inventaire',
      subtitle: 'Catalogue, catégories, alertes rupture et réapprovisionnement — ne perdez plus de ventes faute de stock.',
      bullets: ['Alertes rupture & stock faible', 'Gestion par unités', 'Mise à jour automatique'],
      accent: Color(0xFF22C55E),
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_ventes.png',
      tag: 'Caisse / Ventes',
      title: 'Encaissez\nen quelques secondes',
      subtitle: 'Ventes comptant ou crédit, panier multi-produits et historique complet pour un suivi sans faille.',
      bullets: ['Caisse ultra-rapide', 'Ventes à crédit', 'Restauration stock si annulation'],
      accent: Color(0xFFF59E0B),
    ),
    _OnboardingSlide(
      image: 'assets/images/onboarding_stats.png',
      tag: 'Statistiques',
      title: 'Décidez avec\nvos chiffres',
      subtitle: 'Graphiques, calendrier des ventes, top produits et marges — comprenez ce qui fait grandir votre business.',
      bullets: ['Graphiques & diagrammes', 'Calendrier CA', 'Top produits du mois'],
      accent: Color(0xFF06B6D4),
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

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final isLast = _currentPage == _slides.length - 1;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
        body: Stack(
          children: [
            PageView.builder(
              controller: _pageController,
              onPageChanged: _onPageChanged,
              itemCount: _slides.length,
              itemBuilder: (_, index) => _buildSlidePage(index),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 0),
                child: Row(
                  children: [
                    _TagChip(label: slide.tag, color: slide.accent),
                    const Spacer(),
                    TextButton(
                      onPressed: _finishTour,
                      child: Text('Passer', style: GoogleFonts.plusJakartaSans(color: _textMute, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _buildBottomPanel(slide, isLast),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidePage(int index) {
    final slide = _slides[index];
    final delta = (_pageOffset - index).abs().clamp(0.0, 1.0);
    final scale = 1.0 - delta * 0.08;
    final opacity = 1.0 - delta * 0.35;

    return Stack(
      fit: StackFit.expand,
      children: [
        Transform.scale(
          scale: scale,
          child: Opacity(
            opacity: opacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  slide.image,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: slide.accent.withValues(alpha: 0.15),
                    child: Icon(Icons.image_rounded, size: 64, color: slide.accent.withValues(alpha: 0.5)),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.45, 0.75, 1.0],
                      colors: [
                        _bg.withValues(alpha: 0.1),
                        Colors.transparent,
                        _bg.withValues(alpha: 0.85),
                        _bg,
                      ],
                    ),
                  ),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.2,
                      colors: [slide.accent.withValues(alpha: 0.15), Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomPanel(_OnboardingSlide slide, bool isLast) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, 0, 24, MediaQuery.paddingOf(context).bottom + 24),
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
              dotColor: const Color(0xFF333338),
            ),
          ),
          const SizedBox(height: 24),
          FadeTransition(
            opacity: CurvedAnimation(parent: _contentController, curve: Curves.easeOut),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
                  .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    slide.title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: _text,
                      height: 1.1,
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    slide.subtitle,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: _textMute, height: 1.5),
                  ),
                  const SizedBox(height: 18),
                  ...slide.bullets.map((b) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(color: slide.accent, shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(b, style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildCta(slide, isLast),
        ],
      ),
    );
  }

  Widget _buildCta(_OnboardingSlide slide, bool isLast) {
    return Container(
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [slide.accent, slide.accent.withValues(alpha: 0.75)]),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: slide.accent.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8)),
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
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Icon(isLast ? Icons.rocket_launch_rounded : Icons.arrow_forward_rounded, color: Colors.white, size: 20),
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

  const _TagChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
