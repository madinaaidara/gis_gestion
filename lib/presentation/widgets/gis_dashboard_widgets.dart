import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/gis_palette.dart';
import '../../core/theme/gis_theme_ext.dart';
import '../../core/utils/responsive_utils.dart';

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
    final isWide = ResponsiveUtils.isPageWide(context);

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
    final isWide = ResponsiveUtils.isPageWide(context);

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

/// Carte KPI style Eduka — dégradé, icône, barre de progression en bas.
class GisEdukaSummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final String? footerLabel;
  final double footerProgress;
  final IconData icon;
  final List<Color> gradient;
  final double height;

  const GisEdukaSummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.footerLabel,
    this.footerProgress = 0,
    this.height = 158,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boundedH = constraints.hasBoundedHeight && constraints.maxHeight.isFinite;
        final compact = boundedH && constraints.maxHeight < 155;

        return Container(
          height: boundedH ? constraints.maxHeight : height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            borderRadius: BorderRadius.circular(compact ? 16 : 20),
            boxShadow: [
              BoxShadow(
                color: gradient.first.withValues(alpha: compact ? 0.22 : 0.32),
                blurRadius: compact ? 12 : 18,
                offset: Offset(0, compact ? 4 : 8),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              if (!compact)
                Positioned(
                  top: -16,
                  right: -16,
                  child: Icon(icon, size: 88, color: Colors.white.withValues(alpha: 0.14)),
                ),
              Padding(
                padding: EdgeInsets.all(compact ? 11 : 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(compact ? 6 : 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(compact ? 9 : 12),
                          ),
                          child: Icon(icon, color: Colors.white, size: compact ? 15 : 18),
                        ),
                        if (compact) ...[
                          const Spacer(),
                          Icon(icon, size: 28, color: Colors.white.withValues(alpha: 0.12)),
                        ],
                      ],
                    ),
                    const Spacer(),
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: compact ? 18 : 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: compact ? -0.4 : -0.8,
                        height: 1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: compact ? 2 : 3),
                    Text(
                      label,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: compact ? 10 : 12,
                        fontWeight: FontWeight.w600,
                        height: 1.15,
                      ),
                      maxLines: compact ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (footerLabel != null) ...[
                      SizedBox(height: compact ? 5 : 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: footerProgress.clamp(0.0, 1.0),
                          minHeight: compact ? 2 : 3,
                          backgroundColor: Colors.white.withValues(alpha: 0.22),
                          valueColor: AlwaysStoppedAnimation(Colors.white.withValues(alpha: 0.9)),
                        ),
                      ),
                      SizedBox(height: compact ? 2 : 4),
                      Text(
                        footerLabel!,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.78),
                          fontSize: compact ? 9 : 10,
                          fontWeight: FontWeight.w500,
                          height: 1.15,
                        ),
                        maxLines: compact ? 2 : 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Dimensions KPI selon la largeur disponible (mobile / tablette / desktop).
abstract final class GisKpiLayout {
  static bool useRowLayout(double width) => width >= AppBreakpoints.kpiRow;

  /// Grille 2×2 sous 960 px — les 4 KPI visibles sans scroll.
  static bool useGridLayout(double width) => width < AppBreakpoints.kpiRow;

  static double gridAspectRatio(double width) =>
      width < AppBreakpoints.phone ? 1.12 : 1.18;

  static const gridSpacing = 10.0;
}

/// Layout 4 KPI : ligne desktop, grille 2×2 mobile/tablette.
class GisFourKpiLayout extends StatelessWidget {
  const GisFourKpiLayout({
    super.key,
    required this.children,
    this.horizontalPadding = 16,
    this.topPadding = 0,
    this.bottomPadding = 12,
  });

  final List<Widget> children;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    assert(children.length == 4, 'GisFourKpiLayout attend exactement 4 cartes');

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, topPadding, horizontalPadding, bottomPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (GisKpiLayout.useRowLayout(constraints.maxWidth)) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < children.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < children.length - 1 ? 12 : 0),
                      child: SizedBox(height: 158, child: children[i]),
                    ),
                  ),
              ],
            );
          }

          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: GisKpiLayout.gridSpacing,
            crossAxisSpacing: GisKpiLayout.gridSpacing,
            childAspectRatio: GisKpiLayout.gridAspectRatio(constraints.maxWidth),
            children: children,
          );
        },
      ),
    );
  }
}

/// Données d'une carte KPI pour [GisFourKpiRow].
class GisKpiCardItem {
  const GisKpiCardItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.footerLabel,
    this.footerProgress = 0,
  });

  final String label;
  final String value;
  final String? footerLabel;
  final double footerProgress;
  final IconData icon;
  final List<Color> gradient;
}

/// Rangée de 4 KPI : ligne desktop (≥960px), grille 2×2 mobile/tablette.
class GisFourKpiRow extends StatelessWidget {
  const GisFourKpiRow({
    super.key,
    required this.cards,
    this.horizontalPadding = 16,
    this.topPadding = 0,
    this.bottomPadding = 12,
  });

  final List<GisKpiCardItem> cards;
  final double horizontalPadding;
  final double topPadding;
  final double bottomPadding;

  @override
  Widget build(BuildContext context) {
    assert(cards.length == 4, 'GisFourKpiRow attend exactement 4 cartes');

    return GisFourKpiLayout(
      horizontalPadding: horizontalPadding,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      children: [
        for (final c in cards)
          GisEdukaSummaryCard(
            label: c.label,
            value: c.value,
            footerLabel: c.footerLabel,
            footerProgress: c.footerProgress,
            icon: c.icon,
            gradient: c.gradient,
          ),
      ],
    );
  }
}

/// Panneau blanc arrondi — style Eduka dashboard.
class GisEdukaPanel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;

  const GisEdukaPanel({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.border.withValues(alpha: isDark ? 0.55 : 0.35)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.22), blurRadius: 16, offset: const Offset(0, 6))]
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 4)),
              ],
      ),
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
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.3,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(color: p.textMute, fontSize: 12, fontWeight: FontWeight.w500),
                      ),
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

/// Fond ambient animé — orbes colorés derrière le dashboard.
class GisDashboardAmbientBackground extends StatelessWidget {
  final Animation<double> anim;

  const GisDashboardAmbientBackground({super.key, required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final pulse = 0.65 + anim.value * 0.35;
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final scale = isDark ? 1.0 : 0.65;
        final p = GisPalette.of(context);
        return IgnorePointer(
          child: Stack(
            children: [
              Positioned(
                top: -80 + anim.value * 20,
                right: -60,
                child: Container(
                  width: 220 * pulse,
                  height: 220 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [p.accent.withValues(alpha: 0.22 * scale), p.accent.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 180,
                left: -100 + anim.value * 15,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [p.info.withValues(alpha: 0.12 * scale), p.info.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                right: -40,
                child: Container(
                  width: 160 * pulse,
                  height: 160 * pulse,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [p.success.withValues(alpha: 0.08 * scale), p.success.withValues(alpha: 0)],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
