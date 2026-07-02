import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/gis_palette.dart';
import '../../core/theme/gis_theme_ext.dart';

/// Bandeau d'accueil — style dashboard professionnel (Pointel / Shopify).
class GisDashboardWelcome extends StatelessWidget {
  final String userName;
  final String? shopName;
  final VoidCallback? onRefresh;
  final List<Widget>? actions;

  const GisDashboardWelcome({
    super.key,
    required this.userName,
    this.shopName,
    this.onRefresh,
    this.actions,
  });

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final now = DateTime.now();
    final dateLabel = DateFormat('dd/MM/yyyy', 'fr_FR').format(now);
    final timeLabel = DateFormat('HH:mm', 'fr_FR').format(now);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 16, isWide ? 24 : 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $userName !',
                      style: GoogleFonts.plusJakartaSans(
                        color: p.accent,
                        fontSize: isWide ? 28 : 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _MetaChip(icon: Icons.calendar_today_rounded, label: dateLabel),
                        _MetaChip(icon: Icons.schedule_rounded, label: timeLabel),
                        if (shopName != null && shopName!.isNotEmpty)
                          _MetaChip(icon: Icons.storefront_rounded, label: shopName!),
                      ],
                    ),
                  ],
                ),
              ),
              if (onRefresh != null)
                Material(
                  color: p.surfaceHi,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(Icons.refresh_rounded, color: p.text, size: 20),
                    ),
                  ),
                ),
            ],
          ),
          if (actions != null && actions!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Wrap(spacing: 10, runSpacing: 10, children: actions!),
          ],
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: p.textMute),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: p.textMute, fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Bouton d'action rapide du dashboard.
class GisDashboardAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool primary;

  const GisDashboardAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.primary = false,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    if (primary) {
      return FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: p.accent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18, color: p.text),
      label: Text(label, style: TextStyle(color: p.text, fontWeight: FontWeight.w600)),
      style: OutlinedButton.styleFrom(
        backgroundColor: p.surface,
        side: BorderSide(color: p.borderStrong),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

/// Carte KPI avec dégradé — style dashboard premium.
class GisGradientStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final List<Color> gradient;
  final double progress;

  const GisGradientStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.subtitle,
    this.progress = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Icon(icon, size: 80, color: Colors.white.withValues(alpha: 0.12)),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 10),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (progress > 0)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.85)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Grille responsive de cartes KPI.
class GisStatCardGrid extends StatelessWidget {
  final List<GisGradientStatCard> cards;
  final EdgeInsetsGeometry? padding;

  const GisStatCardGrid({super.key, required this.cards, this.padding});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final crossCount = w >= 900 ? 4 : (w >= 520 ? 2 : 1);
          final spacing = 12.0;

          if (crossCount == 1) {
            return Column(
              children: [
                for (var i = 0; i < cards.length; i++) ...[
                  cards[i],
                  if (i < cards.length - 1) SizedBox(height: spacing),
                ],
              ],
            );
          }

          return GridView.count(
            crossAxisCount: crossCount,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: spacing,
            crossAxisSpacing: spacing,
            childAspectRatio: crossCount == 4 ? 1.55 : 1.65,
            children: cards,
          );
        },
      ),
    );
  }
}

/// En-tête de page analytics (Statistiques avancées).
class GisAnalyticsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? badge;
  final VoidCallback? onRefresh;

  const GisAnalyticsHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.badge,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final isWide = MediaQuery.sizeOf(context).width >= 720;

    return Padding(
      padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 16, isWide ? 24 : 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: p.accentLinear(),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(color: p.accent.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: p.text,
                    fontSize: isWide ? 26 : 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(color: p.textMute, fontSize: 13, height: 1.35, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: p.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: p.border),
                  ),
                  child: Text(badge!, style: TextStyle(color: p.textMute, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              if (onRefresh != null) ...[
                const SizedBox(height: 8),
                Material(
                  color: p.surfaceHi,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: onRefresh,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: p.border),
                      ),
                      child: Icon(Icons.refresh_rounded, color: p.text, size: 18),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Panneau blanc/surface pour graphiques.
class GisChartPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const GisChartPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: p.cardDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.plusJakartaSans(
                        color: p.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: TextStyle(color: p.textMute, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Sélecteur de période — pills premium.
class GisPeriodSelector extends StatelessWidget {
  final List<(String id, String label)> periods;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool enabled;

  const GisPeriodSelector({
    super.key,
    required this.periods,
    required this.selectedId,
    required this.onSelected,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: p.cardDecoration(context, radius: 14),
        child: Row(
          children: periods.map((item) {
            final selected = selectedId == item.$1;
            return Expanded(
              child: GestureDetector(
                onTap: enabled ? () => onSelected(item.$1) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    gradient: selected ? p.accentLinear() : null,
                    color: selected ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: selected
                        ? [BoxShadow(color: p.accent.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0, 2))]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      item.$2,
                      style: TextStyle(
                        color: selected ? Colors.white : p.textMute,
                        fontSize: 13,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Layout 2 colonnes pour graphiques (responsive).
class GisDashboardSplit extends StatelessWidget {
  final Widget left;
  final Widget right;
  final double minWidth;

  const GisDashboardSplit({
    super.key,
    required this.left,
    required this.right,
    this.minWidth = 640,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= minWidth) {
          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: left),
                const SizedBox(width: 12),
                Expanded(child: right),
              ],
            ),
          );
        }
        return Column(
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      },
    );
  }
}
