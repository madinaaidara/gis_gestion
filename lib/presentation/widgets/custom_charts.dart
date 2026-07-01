import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

/// Thème graphiques dark premium
class StatsChartTheme {
  final Color surface;
  final Color border;
  final Color text;
  final Color textMute;
  final Color accent;
  final Color accentSoft;
  final Color success;

  const StatsChartTheme({
    required this.surface,
    required this.border,
    required this.text,
    required this.textMute,
    required this.accent,
    required this.accentSoft,
    required this.success,
  });
}

String formatChartValue(double value) {
  if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
  return value.toStringAsFixed(0);
}

class BarChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String? subtitle;
  final StatsChartTheme theme;
  final double height;

  const BarChartWidget({
    super.key,
    required this.data,
    required this.title,
    required this.theme,
    this.subtitle,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      theme: theme,
      title: title,
      subtitle: subtitle,
      child: data.isEmpty
          ? _EmptyChart(theme: theme, icon: Icons.bar_chart_rounded)
          : SizedBox(
              height: height,
              child: BarChart(_buildData()),
            ),
    );
  }

  BarChartData _buildData() {
    final totals = data.map((e) => (e['total'] as num).toDouble()).toList();
    final maxY = totals.reduce((a, b) => a > b ? a : b);
    final ceiling = maxY <= 0 ? 100.0 : maxY * 1.15;

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: ceiling,
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => theme.surface,
          tooltipBorder: BorderSide(color: theme.border),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final total = totals[group.x.toInt()];
            return BarTooltipItem(
              formatChartValue(total),
              TextStyle(color: theme.text, fontWeight: FontWeight.bold, fontSize: 12),
            );
          },
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) return const SizedBox.shrink();
              final date = data[index]['date'].toString();
              final label = date.length >= 10 ? date.substring(8, 10) : date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(label, style: TextStyle(color: theme.textMute, fontSize: 10)),
              );
            },
            reservedSize: 28,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) return const SizedBox.shrink();
              return Text(
                formatChartValue(value),
                style: TextStyle(color: theme.textMute, fontSize: 9),
              );
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: ceiling / 4,
        getDrawingHorizontalLine: (_) => FlLine(color: theme.border.withOpacity(0.5), strokeWidth: 1),
      ),
      barGroups: List.generate(data.length, (index) {
        final value = totals[index];
        return BarChartGroupData(
          x: index,
          barRods: [
            BarChartRodData(
              toY: value,
              width: data.length > 14 ? 8 : 14,
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [theme.accent.withOpacity(0.6), theme.accentSoft],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: ceiling,
                color: theme.border.withOpacity(0.3),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class LineChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> data;
  final String title;
  final String? subtitle;
  final StatsChartTheme theme;
  final double height;

  const LineChartWidget({
    super.key,
    required this.data,
    required this.title,
    required this.theme,
    this.subtitle,
    this.height = 220,
  });

  @override
  Widget build(BuildContext context) {
    return _ChartCard(
      theme: theme,
      title: title,
      subtitle: subtitle,
      child: data.isEmpty
          ? _EmptyChart(theme: theme, icon: Icons.show_chart_rounded)
          : SizedBox(height: height, child: LineChart(_buildData())),
    );
  }

  LineChartData _buildData() {
    final values = data.map((e) => (e['value'] as num).toDouble()).toList();
    final maxY = values.isEmpty ? 100.0 : values.reduce((a, b) => a > b ? a : b);
    final ceiling = maxY <= 0 ? 100.0 : maxY * 1.2;

    final spots = List.generate(values.length, (i) => FlSpot(i.toDouble(), values[i]));

    return LineChartData(
      minX: 0,
      maxX: (data.length - 1).toDouble().clamp(0, double.infinity),
      minY: 0,
      maxY: ceiling,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => theme.surface,
          tooltipBorder: BorderSide(color: theme.border),
          getTooltipItems: (spots) => spots.map((spot) {
            return LineTooltipItem(
              formatChartValue(spot.y),
              TextStyle(color: theme.success, fontWeight: FontWeight.bold, fontSize: 12),
            );
          }).toList(),
        ),
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  data[index]['label'].toString(),
                  style: TextStyle(color: theme.textMute, fontSize: 9),
                ),
              );
            },
            reservedSize: 32,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) {
              if (value == meta.max || value == meta.min) return const SizedBox.shrink();
              return Text(formatChartValue(value), style: TextStyle(color: theme.textMute, fontSize: 9));
            },
          ),
        ),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: ceiling / 4,
        getDrawingHorizontalLine: (_) => FlLine(color: theme.border.withOpacity(0.5), strokeWidth: 1),
      ),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.35,
          color: theme.success,
          barWidth: 2.5,
          dotData: FlDotData(
            show: data.length <= 12,
            getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
              radius: 3,
              color: theme.success,
              strokeWidth: 2,
              strokeColor: theme.surface,
            ),
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [theme.success.withOpacity(0.25), theme.success.withOpacity(0.0)],
            ),
          ),
        ),
      ],
    );
  }
}

class _ChartCard extends StatelessWidget {
  final StatsChartTheme theme;
  final String title;
  final String? subtitle;
  final Widget child;

  const _ChartCard({
    required this.theme,
    required this.title,
    required this.child,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: theme.text, fontSize: 15, fontWeight: FontWeight.w700)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: TextStyle(color: theme.textMute, fontSize: 11)),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  final StatsChartTheme theme;
  final IconData icon;

  const _EmptyChart({required this.theme, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: theme.textMute.withOpacity(0.4)),
            const SizedBox(height: 10),
            Text('Aucune donnée sur cette période', style: TextStyle(color: theme.textMute, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// Anneau circulaire avec pourcentage (marge, crédit, activité…)
class RingMetricWidget extends StatelessWidget {
  final double percent;
  final String label;
  final String value;
  final String? explanation;
  final Color color;
  final StatsChartTheme theme;
  final double size;

  const RingMetricWidget({
    super.key,
    required this.percent,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
    this.explanation,
    this.size = 88,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 100.0) / 100;

    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(theme.border),
                ),
              ),
              SizedBox(
                width: size,
                height: size,
                child: CircularProgressIndicator(
                  value: clamped,
                  strokeWidth: 7,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${percent.clamp(0, 100).toStringAsFixed(0)}%',
                    style: TextStyle(color: theme.text, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    value,
                    style: TextStyle(color: theme.textMute, fontSize: 9),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: theme.text, fontSize: 11, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        if (explanation != null) ...[
          const SizedBox(height: 4),
          Text(
            explanation!,
            style: TextStyle(color: theme.textMute, fontSize: 9, height: 1.3),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Graphique circulaire (donut) — répartition paiements ou produits
class DonutChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> sections;
  final String title;
  final String? subtitle;
  final String centerLabel;
  final String centerValue;
  final StatsChartTheme theme;
  final List<Color> colors;
  final bool compact;
  final bool embedded;

  const DonutChartWidget({
    super.key,
    required this.sections,
    required this.title,
    required this.centerLabel,
    required this.centerValue,
    required this.theme,
    required this.colors,
    this.subtitle,
    this.compact = false,
    this.embedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final chartHeight = compact ? 120.0 : 180.0;
    final centerRadius = compact ? 36.0 : 52.0;
    final sectionRadius = compact ? 20.0 : 28.0;
    final valueFontSize = compact ? 11.0 : 14.0;
    final labelFontSize = compact ? 8.0 : 10.0;
    final legendFontSize = compact ? 9.0 : 11.0;

    final content = sections.isEmpty
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (embedded) ...[
                Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: compact ? 11 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: compact ? 120 : 180,
                child: _EmptyChart(theme: theme, icon: Icons.donut_large_rounded),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (embedded) ...[
                Text(
                  title,
                  style: TextStyle(
                    color: theme.text,
                    fontSize: compact ? 11 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: TextStyle(color: theme.textMute, fontSize: compact ? 8 : 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 8),
              ],
              SizedBox(
                height: chartHeight,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: centerRadius,
                        startDegreeOffset: -90,
                        sections: List.generate(sections.length, (i) {
                          final val = (sections[i]['value'] as num?)?.toDouble() ?? 0;
                          return PieChartSectionData(
                            value: val <= 0 ? 0.001 : val,
                            color: colors[i % colors.length],
                            radius: sectionRadius,
                            showTitle: false,
                          );
                        }),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          centerValue,
                          style: TextStyle(
                            color: theme.text,
                            fontSize: valueFontSize,
                            fontWeight: FontWeight.w800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          centerLabel,
                          style: TextStyle(color: theme.textMute, fontSize: labelFontSize),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: compact ? 6 : 12),
              ...sections.asMap().entries.map((e) {
                final i = e.key;
                final s = e.value;
                final total = sections.fold(0.0, (sum, x) => sum + ((x['value'] as num?)?.toDouble() ?? 0));
                final val = (s['value'] as num?)?.toDouble() ?? 0;
                final pct = total > 0 ? val / total * 100 : 0.0;
                return Padding(
                  padding: EdgeInsets.only(bottom: compact ? 4 : 6),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 6 : 8,
                        height: compact ? 6 : 8,
                        decoration: BoxDecoration(color: colors[i % colors.length], shape: BoxShape.circle),
                      ),
                      SizedBox(width: compact ? 5 : 8),
                      Expanded(
                        child: Text(
                          s['label']?.toString() ?? '—',
                          style: TextStyle(color: theme.text, fontSize: legendFontSize),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        '${pct.toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: colors[i % colors.length],
                          fontSize: legendFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          );

    if (embedded) return content;

    return _ChartCard(
      theme: theme,
      title: title,
      subtitle: subtitle,
      child: content,
    );
  }
}
