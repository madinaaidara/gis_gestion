import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingTourPage extends StatefulWidget {
  const OnboardingTourPage({super.key});

  @override
  State<OnboardingTourPage> createState() => _OnboardingTourPageState();
}

class _OnboardingTourPageState extends State<OnboardingTourPage> {
  // ===== PALETTE DARK PREMIUM =====
  static const Color _bg = Color(0xFF050505);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _success = Color(0xFF22C55E);
  static const Color _info = Color(0xFF06B6D4);

  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = const [
    {
      'icon': Icons.inventory_2_rounded,
      'title': 'Gestion des produits',
      'subtitle': 'Ajoutez, modifiez et suivez\nvotre inventaire en temps réel',
      'color': _success,
      'features': ['Catalogue intelligent', 'Alertes stock', 'Catégories'],
    },
    {
      'icon': Icons.point_of_sale_rounded,
      'title': 'Point de vente',
      'subtitle': 'Encaissements rapides\net suivi des crédits clients',
      'color': _accent,
      'features': ['Caisse rapide', 'Vente à crédit', 'Historique'],
    },
    {
      'icon': Icons.analytics_rounded,
      'title': 'Statistiques',
      'subtitle': 'Analysez vos performances\net développez votre activité',
      'color': _info,
      'features': ['Tableau de bord', 'Rapports', 'Export données'],
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    HapticFeedback.lightImpact();
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      _finishTour();
    }
  }

  Future<void> _finishTour() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/navigation');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            // Header with progress
            _buildHeader(),
            // Main content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemCount: _pages.length,
                itemBuilder: (context, index) => _buildPage(index),
              ),
            ),
            // Footer with button
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        children: [
          // Progress indicators
          Row(
            children: List.generate(_pages.length, (index) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.only(right: 8),
                width: _currentPage == index ? 28 : 8,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == index ? _pages[_currentPage]['color'] as Color : _border,
                  borderRadius: BorderRadius.circular(2),
                ),
              );
            }),
          ),
          const Spacer(),
          // Skip button
          TextButton(
            onPressed: _finishTour,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Passer',
              style: TextStyle(
                color: _textMute,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(int index) {
    final page = _pages[index];
    final Color color = page['color'] as Color;
    final List<String> features = page['features'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [color.withOpacity(0.15), color.withOpacity(0.02)],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: color.withOpacity(0.2),
                        blurRadius: 30 * value,
                        spreadRadius: 4 * value,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      page['icon'] as IconData,
                      size: 56,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          // Title
          Text(
            page['title'] as String,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: _text,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          // Subtitle
          Text(
            page['subtitle'] as String,
            style: TextStyle(
              fontSize: 14,
              color: _textMute,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          // Features chips
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 10,
            runSpacing: 10,
            children: features.map((feature) => _buildFeatureChip(feature, color)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final Color currentColor = _pages[_currentPage]['color'] as Color;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _nextPage,
              style: ElevatedButton.styleFrom(
                backgroundColor: currentColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _currentPage == _pages.length - 1 ? 'Commencer' : 'Continuer',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (_currentPage != _pages.length - 1) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '${_currentPage + 1} / ${_pages.length}',
            style: TextStyle(
              fontSize: 12,
              color: _textDim,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}