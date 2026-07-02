import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../core/theme/app_surface.dart';
import '../../core/theme/gis_palette.dart';
import 'package:google_fonts/google_fonts.dart';

/// Splash animé premium — logo pulsé, anneaux, particules.
class AnimatedSplash extends StatefulWidget {
  final String statusText;
  final bool hasError;
  final String? errorMessage;

  const AnimatedSplash({
    super.key,
    this.statusText = 'Chargement...',
    this.hasError = false,
    this.errorMessage,
  });

  @override
  State<AnimatedSplash> createState() => _AnimatedSplashState();
}

class _AnimatedSplashState extends State<AnimatedSplash> with TickerProviderStateMixin {
  GisPalette get _p => GisPalette.of(context);


  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> _textOpacity;
  late Animation<double> _textSlide;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _ringController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2200))..repeat();
    _glowController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _particleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );
    _logoOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0, 0.4, curve: Curves.easeIn)),
    );
    _textOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.45, 1, curve: Curves.easeOut)),
    );
    _textSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(parent: _logoController, curve: const Interval(0.45, 1, curve: Curves.easeOutCubic)),
    );

    _logoController.forward();
  }

  @override
  void dispose() {
    _logoController.dispose();
    _ringController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logoSize = MediaQuery.sizeOf(context).width >= 900 ? 160.0 : 120.0;

    return Scaffold(
      backgroundColor: _p.bg,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _AmbientLayer(controller: _particleController),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _ringController, _glowController]),
                    builder: (_, __) {
                      return Transform.scale(
                        scale: _logoScale.value,
                        child: Opacity(
                          opacity: _logoOpacity.value,
                          child: _AnimatedLogo(
                            size: logoSize,
                            ringRotation: _ringController.value * 2 * math.pi,
                            glow: 0.6 + _glowController.value * 0.4,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  AnimatedBuilder(
                    animation: _logoController,
                    builder: (_, __) {
                      return Transform.translate(
                        offset: Offset(0, _textSlide.value),
                        child: Opacity(
                          opacity: _textOpacity.value,
                          child: Column(
                            children: [
                              Text(
                                'GIS Gestion',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: _p.text,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Voir · Gérer · Performer',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 13,
                                  color: _p.textMute,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 48),
                  AnimatedBuilder(
                    animation: Listenable.merge([_logoController, _glowController]),
                    builder: (_, __) {
                      return Opacity(
                        opacity: _textOpacity.value,
                        child: Column(
                          children: [
                            SizedBox(
                              width: 120,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                backgroundColor:  AppSurface.border,
                                valueColor: AlwaysStoppedAnimation(_p.accent.withValues(alpha: 0.8 + _glowController.value * 0.2)),
                                minHeight: 3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              widget.statusText,
                              style:  TextStyle(color: _p.textMute, fontSize: 12),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  if (widget.hasError && widget.errorMessage != null) ...[
                    const SizedBox(height: 24),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 32),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:  AppSurface.danger.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color:  AppSurface.danger.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        widget.errorMessage!,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppSurface.danger, fontSize: 11),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLogo extends StatelessWidget {
  final double size;
  final double ringRotation;
  final double glow;

  const _AnimatedLogo({required this.size, required this.ringRotation, required this.glow});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 48,
      height: size + 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: ringRotation,
            child: Container(
              width: size + 40,
              height: size + 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: SweepGradient(
                  colors: [
                     AppSurface.accent.withValues(alpha: 0),
                     AppSurface.accent.withValues(alpha: 0.7),
                     AppSurface.accentSoft.withValues(alpha: 0.3),
                     AppSurface.accent.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: size + 20,
            height: size + 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color:  AppSurface.accent.withValues(alpha: 0.35 * glow),
                  blurRadius: 40 * glow,
                  spreadRadius: 4,
                ),
              ],
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppSurface.accent, Color(0xFF5B3FD4)],
              ),
              borderRadius: BorderRadius.circular(size * 0.28),
              border: Border.all(color:  AppSurface.accentSoft.withValues(alpha: 0.4), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(size * 0.26),
              child: Image.asset(
                'assets/images/logo_guiss_gestion1.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(Icons.store_rounded, size: size * 0.45, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientLayer extends StatelessWidget {
  final AnimationController controller;

  const _AmbientLayer({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        final t = controller.value;
        return CustomPaint(
          painter: _SplashParticlePainter(t),
          size: Size.infinite,
        );
      },
    );
  }
}

class _SplashParticlePainter extends CustomPainter {
  final double t;

  _SplashParticlePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final bg = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppSurface.bg, AppSurface.surfaceHi, AppSurface.bg],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final rnd = math.Random(7);
    for (var i = 0; i < 40; i++) {
      final x = rnd.nextDouble() * size.width;
      final y = ((rnd.nextDouble() + t * (0.3 + rnd.nextDouble())) % 1) * size.height;
      canvas.drawCircle(
        Offset(x, y),
        rnd.nextDouble() * 2 + 0.5,
        Paint()..color = Colors.white.withValues(alpha: 0.06),
      );
    }

    final pulse = 0.5 + math.sin(t * math.pi * 2) * 0.15;
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.15),
      120 * pulse,
      Paint()
        ..shader = RadialGradient(
          colors: [ AppSurface.accent.withValues(alpha: 0.15), Colors.transparent],
        ).createShader(Rect.fromCircle(center: Offset(size.width * 0.8, size.height * 0.15), radius: 120)),
    );
  }

  @override
  bool shouldRepaint(covariant _SplashParticlePainter oldDelegate) => oldDelegate.t != t;
}
