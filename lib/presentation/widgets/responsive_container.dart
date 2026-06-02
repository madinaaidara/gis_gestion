import 'package:flutter/material.dart';
import '../../core/utils/responsive_utils.dart';

/// Container qui adapte automatiquement l'interface
/// - Téléphone: pleine largeur
/// - Desktop: largeur limitée (comme mobile), centré
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(16),
      child: ResponsiveUtils.centerWithMaxWidth(context, child),
    );
  }
}

/// Version avec SafeArea
class SafeResponsiveContainer extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const SafeResponsiveContainer({
    super.key,
    required this.child,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ResponsiveContainer(
        padding: padding,
        child: child,
      ),
    );
  }
}