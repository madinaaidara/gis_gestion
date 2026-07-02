import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/gis_palette.dart';
import '../../core/theme/gis_theme_ext.dart';

/// En-tête de page unifié — Caisse, Crédits, Historique, etc.
class GisPageHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onRefresh;
  final List<GisMetricTile>? metrics;
  final Widget? trailing;

  const GisPageHeader({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onRefresh,
    this.metrics,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 800;

    return Container(
      padding: EdgeInsets.fromLTRB(isMobile ? 16 : 24, 16, isMobile ? 16 : 24, metrics != null ? 12 : 16),
      decoration: BoxDecoration(
        color: p.surface,
        border: Border(bottom: BorderSide(color: p.border)),
        boxShadow: p.isDark(context)
            ? null
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: p.accentLinear(),
                  borderRadius: BorderRadius.circular(13),
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        color: p.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(color: p.textMute, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
              if (onRefresh != null) ...[
                if (trailing != null) const SizedBox(width: 8),
                GisIconButton(icon: Icons.refresh_rounded, onTap: onRefresh!, tooltip: 'Actualiser'),
              ],
            ],
          ),
          if (metrics != null && metrics!.isNotEmpty) ...[
            const SizedBox(height: 16),
            _MetricsRow(metrics: metrics!, isMobile: isMobile),
          ],
        ],
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final List<GisMetricTile> metrics;
  final bool isMobile;

  const _MetricsRow({required this.metrics, required this.isMobile});

  @override
  Widget build(BuildContext context) {
    if (isMobile && metrics.length > 2) {
      final half = (metrics.length / 2).ceil();
      return Column(
        children: [
          Row(children: metrics.take(half).map((m) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: m))).toList()),
          const SizedBox(height: 8),
          Row(
            children: metrics.skip(half).map((m) => Expanded(child: Padding(padding: const EdgeInsets.only(right: 8), child: m))).toList(),
          ),
        ],
      );
    }
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++)
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < metrics.length - 1 ? 8 : 0),
              child: metrics[i],
            ),
          ),
      ],
    );
  }
}

/// Tuile KPI — stats en haut de page.
class GisMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData? icon;

  const GisMetricTile({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: p.cardDecoration(context, radius: 12),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 13, color: color),
                const SizedBox(width: 4),
              ],
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 11, color: p.textMute, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color, letterSpacing: -0.3),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// Barre de recherche unifiée.
class GisSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onClear;
  final EdgeInsetsGeometry? padding;
  final double height;

  const GisSearchField({
    super.key,
    required this.controller,
    required this.hint,
    this.onChanged,
    this.onClear,
    this.padding,
    this.height = 44,
  });

  @override
  State<GisSearchField> createState() => _GisSearchFieldState();
}

class _GisSearchFieldState extends State<GisSearchField> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Padding(
      padding: widget.padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.border),
          boxShadow: p.isDark(context) ? null : p.cardShadow(context).take(1).toList(),
        ),
        child: TextField(
          controller: widget.controller,
          onChanged: widget.onChanged,
          style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w500),
          decoration: p.searchInputDecoration(
            hint: widget.hint,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 8),
              child: Icon(Icons.search_rounded, size: 18, color: p.textMute),
            ),
            suffixIcon: widget.controller.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: p.textMute),
                    onPressed: widget.onClear ?? () => widget.controller.clear(),
                  )
                : null,
          ),
        ),
      ),
    );
  }
}

/// Filtres en chips — période, catégorie, etc.
class GisFilterChips extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry? padding;

  const GisFilterChips({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(labels.length, (i) {
          final selected = i == selectedIndex;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onSelected(i),
                borderRadius: BorderRadius.circular(20),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? p.accent.withValues(alpha: p.isDark(context) ? 0.22 : 0.12) : p.surfaceHi,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? p.accent.withValues(alpha: 0.5) : p.border,
                      width: selected ? 1.2 : 1,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    style: TextStyle(
                      color: selected ? (p.isDark(context) ? p.accentSoft : p.accent) : p.textMute,
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

/// État vide cohérent.
class GisEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  const GisEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: p.surfaceHi,
                shape: BoxShape.circle,
                border: Border.all(color: p.border),
              ),
              child: Icon(icon, size: 32, color: p.textMute),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                color: p.text,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(color: p.textMute, fontSize: 13, height: 1.4),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}

/// Carte surface avec ombre thématique.
class GisCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  const GisCard({
    super.key,
    required this.child,
    this.padding,
    this.radius = 14,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final content = Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: p.cardDecoration(context, radius: radius),
      child: child,
    );
    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}

/// Bouton icône carré — refresh, filtres, etc.
class GisIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;

  const GisIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.tooltip,
    this.size = 38,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final btn = Material(
      color: p.surfaceHi,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.border),
          ),
          child: Icon(icon, color: p.text, size: 18),
        ),
      ),
    );
    if (tooltip != null) return Tooltip(message: tooltip, child: btn);
    return btn;
  }
}

/// Badge coloré (stock, statut).
class GisStatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;

  const GisStatusBadge({super.key, required this.label, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
          ],
          Text(label, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
