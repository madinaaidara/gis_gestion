import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/gis_palette.dart';
import '../../../core/theme/gis_theme_ext.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/repositories/shops_repository.dart';
import '../../../core/services/app_refresh_listener.dart';
import '../../../core/services/app_refresh_notifier.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../viewmodels/stats_viewmodel.dart';
import '../../widgets/custom_charts.dart';
import '../../widgets/gis_dashboard_widgets.dart';
import '../../widgets/gis_report_sheet.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with AppRefreshListener {
  GisPalette get _p => GisPalette.of(context);

  @override
  AppRefreshScope get refreshScope => AppRefreshScope.stats;

  @override
  void onAppRefresh() => _loadData();


  String? shopId;
  String? shopName;
  String? devise;
  bool _exportingReport = false;

  StatsChartTheme get _chartTheme =>  StatsChartTheme(
        surface: _p.surface,
        border: _p.border,
        text: _p.text,
        textMute: _p.textMute,
        accent: _p.accent,
        accentSoft: _p.accentSoft,
        success: _p.success,
      );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;
      if (!mounted) return;

      final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopRepo.checkAndLoadShop(userId);
      if (!mounted || shopRepo.currentShop == null) return;

      shopId = shopRepo.currentShop!.id;
      shopName = shopRepo.currentShop!.nomBoutique;
      devise = shopRepo.currentShop?.devise ?? 'FCFA';

      await Provider.of<StatsViewModel>(context, listen: false).loadStatsData(shopId!);
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur chargement stats: $e');
    }
  }

  String _formatMoney(double value, {bool compact = false}) {
    final d = devise ?? 'FCFA';
    if (compact) {
      if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M $d';
      if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K $d';
    }
    return '${NumberFormat('#,##0', 'fr_FR').format(value.round())} $d';
  }

  String _trendLabel(double evo) => '${evo >= 0 ? '+' : ''}${evo.toStringAsFixed(1)}%';

  Future<void> _exportReport(StatsViewModel statsVM) async {
    if (shopId == null || _exportingReport) return;
    setState(() => _exportingReport = true);

    try {
      final data = await statsVM.buildReportData(
        shopId: shopId!,
        shopName: shopName ?? 'Boutique',
        devise: devise ?? 'FCFA',
      );
      if (!mounted) return;

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: _p.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => GisReportSheet(
          data: data,
          periodeId: statsVM.selectedPeriode,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Impossible de générer le rapport'), behavior: SnackBarBehavior.floating),
      );
    } finally {
      if (mounted) setState(() => _exportingReport = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
          : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _p.bg,
        body: SafeArea(
          child: Consumer<StatsViewModel>(
            builder: (context, statsVM, _) {
              if (shopId == null) return _buildNoShop();
              if (statsVM.isLoading && statsVM.totalVentes == 0 && statsVM.totalCA == 0) {
                return _buildLoading();
              }
              if (statsVM.errorMessage.isNotEmpty && statsVM.totalCA == 0 && statsVM.totalVentes == 0) {
                return _buildError(statsVM);
              }

              return RefreshIndicator(
                onRefresh: () => statsVM.refreshData(shopId!),
                color: _p.accent,
                backgroundColor: _p.surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(child: _buildFilyHeader(statsVM)),
                    SliverToBoxAdapter(child: _buildFilySummaryRow(statsVM)),
                    SliverToBoxAdapter(child: _buildFilyMainContent(statsVM)),
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                        ResponsiveUtils.pageHorizontalPadding(context),
                        8,
                        ResponsiveUtils.pageHorizontalPadding(context),
                        ResponsiveUtils.scrollBottomInset(context),
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          GisReportsPanel(
                            periodeLabel: statsVM.periodeLabel,
                            totalCA: statsVM.totalCA,
                            totalVentes: statsVM.totalVentes,
                            devise: devise ?? 'FCFA',
                            isLoading: _exportingReport,
                            onExport: () => _exportReport(statsVM),
                          ),
                          const SizedBox(height: 16),
                          _buildFilyProductsTable(statsVM),
                          const SizedBox(height: 16),
                          _buildFilyAnalysis(statsVM),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildFilyHeader(StatsViewModel statsVM) {
    final pad = ResponsiveUtils.pageHorizontalPadding(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 20, pad, 8),
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
                      '${shopName ?? 'Votre boutique'} · ${statsVM.periodeLabel}',
                      style: TextStyle(color: _p.textMute, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Material(
                color: _p.surfaceHi,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: _exportingReport ? null : () => _exportReport(statsVM),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _p.border),
                    ),
                    child: _exportingReport
                        ? Padding(
                            padding: const EdgeInsets.all(11),
                            child: CircularProgressIndicator(strokeWidth: 2, color: _p.accent),
                          )
                        : Icon(Icons.assessment_outlined, color: _p.text, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: _p.surfaceHi,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: statsVM.isLoading ? null : () => statsVM.refreshData(shopId!),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: _p.border),
                    ),
                    child: Icon(Icons.refresh_rounded, color: _p.text, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildPeriodSelector(statsVM),
        ],
      ),
    );
  }

  Widget _buildFilySummaryRow(StatsViewModel statsVM) {
    final pad = ResponsiveUtils.pageHorizontalPadding(context);
    final evoCa = statsVM.evolutionCA;
    final evoVentes = statsVM.evolutionVentes;

    final cards = [
      (
        label: 'Chiffre d\'affaires',
        value: _formatMoney(statsVM.totalCA, compact: true),
        footer: '${statsVM.periodeLabel} · ${_trendLabel(evoCa)}',
        progress: (evoCa.abs() / 100).clamp(0.0, 1.0),
        icon: Icons.payments_rounded,
        gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
      ),
      (
        label: 'Ventes',
        value: '${statsVM.totalVentes}',
        footer: '${statsVM.periodeLabel} · ${_trendLabel(evoVentes)}',
        progress: (evoVentes.abs() / 100).clamp(0.0, 1.0),
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
      ),
      (
        label: 'Clients uniques',
        value: '${statsVM.totalClients}',
        footer: 'Panier moy. ${_formatMoney(statsVM.panierMoyen, compact: true)}',
        progress: statsVM.panierMoyen > 0 ? 0.7 : 0.2,
        icon: Icons.people_rounded,
        gradient: const [Color(0xFFEC4899), Color(0xFFDB2777)],
      ),
      (
        label: 'Bénéfice net',
        value: _formatMoney(statsVM.beneficeTotal, compact: true),
        footer: 'Marge ${statsVM.margePercent.toStringAsFixed(0)}% · ${_trendLabel(statsVM.evolutionBenefice)}',
        progress: (statsVM.margePercent / 100).clamp(0.0, 1.0),
        icon: Icons.trending_up_rounded,
        gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
      ),
    ];

    return GisFourKpiRow(
      horizontalPadding: pad,
      topPadding: 4,
      cards: [
        for (final c in cards)
          GisKpiCardItem(
            label: c.label,
            value: c.value,
            footerLabel: c.footer,
            footerProgress: c.progress,
            icon: c.icon,
            gradient: c.gradient,
          ),
      ],
    );
  }

  Widget _buildFilyMainContent(StatsViewModel statsVM) {
    final isWide = ResponsiveUtils.isKpiRowWide(context);
    final pad = ResponsiveUtils.pageHorizontalPadding(context);

    final left = Column(
      children: [
        _buildFilyEvolutionPanel(statsVM),
        const SizedBox(height: 12),
        _buildFilyBarPanel(statsVM),
      ],
    );

    final right = Column(
      children: [
        _buildFilySparklineRow(statsVM),
        const SizedBox(height: 12),
        _buildFilyDonutPanel(statsVM),
        const SizedBox(height: 12),
        _buildFilyRingPanel(statsVM),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(pad, 0, pad, 8),
      child: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: left),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: right),
              ],
            )
          : Column(
              children: [
                left,
                const SizedBox(height: 12),
                right,
              ],
            ),
    );
  }

  Widget _buildFilyEvolutionPanel(StatsViewModel statsVM) {
    return GisEdukaPanel(
      title: 'Évolution du chiffre d\'affaires',
      subtitle: statsVM.periodeLabel,
      trailing: OutlinedButton.icon(
        onPressed: shopId == null ? null : () => _openCalendarModal(statsVM),
        icon: Icon(Icons.calendar_month_rounded, size: 16, color: _p.accent),
        label: Text('Calendrier', style: TextStyle(color: _p.text, fontWeight: FontWeight.w600, fontSize: 12)),
        style: OutlinedButton.styleFrom(
          backgroundColor: _p.surfaceHi,
          side: BorderSide(color: _p.border),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          visualDensity: VisualDensity.compact,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final metrics = [
                _FilyMetricTile(label: 'CA', value: _formatMoney(statsVM.totalCA, compact: true), color: _p.success),
                _FilyMetricTile(label: 'Ventes', value: '${statsVM.totalVentes}', color: _p.info),
                _FilyMetricTile(label: 'Bénéfice', value: _formatMoney(statsVM.beneficeTotal, compact: true), color: _p.warning),
                _FilyMetricTile(label: 'Clients', value: '${statsVM.totalClients}', color: _p.accent),
              ];
              if (constraints.maxWidth < AppBreakpoints.phone) {
                return GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.3,
                  children: metrics,
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
            },
          ),
          const SizedBox(height: 16),
          EvolutionAreaChartWidget(
            theme: _chartTheme,
            data: statsVM.evolutionChartData,
            title: '',
            subtitle: '',
            trendLabel: _trendLabel(statsVM.evolutionCA),
            height: ResponsiveUtils.isPhone(context) ? 200 : 240,
            embedded: true,
          ),
        ],
      ),
    );
  }

  Widget _buildFilyBarPanel(StatsViewModel statsVM) {
    return Padding(
      padding: const EdgeInsets.only(top: 0),
      child: BarChartWidget(
        theme: _chartTheme,
        data: statsVM.chartData,
        title: 'Rapport des ventes',
        subtitle: 'CA par jour · ${statsVM.periodeLabel.toLowerCase()}',
        height: 220,
      ),
    );
  }

  Widget _buildFilySparklineRow(StatsViewModel statsVM) {
    final compact = !ResponsiveUtils.isTwoColumnWide(context);
    final left = _FilySparkCard(
      label: 'Marge nette',
      value: '${statsVM.margePercent.toStringAsFixed(0)}%',
      trend: _trendLabel(statsVM.evolutionBenefice),
      trendUp: statsVM.evolutionBenefice >= 0,
      color: _p.success,
    );
    final right = _FilySparkCard(
      label: 'Ventes crédit',
      value: '${statsVM.tauxCredits.toStringAsFixed(0)}%',
      trend: '${statsVM.chartData.length} j. actifs',
      trendUp: true,
      color: _p.info,
    );

    if (compact) {
      return Column(
        children: [
          left,
          const SizedBox(height: 10),
          right,
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: left),
        const SizedBox(width: 10),
        Expanded(child: right),
      ],
    );
  }

  Widget _buildFilyDonutPanel(StatsViewModel statsVM) {
    final paymentSections = <Map<String, dynamic>>[];
    if (statsVM.caComptant > 0) paymentSections.add({'label': 'Comptant', 'value': statsVM.caComptant});
    if (statsVM.caCredit > 0) paymentSections.add({'label': 'Crédit', 'value': statsVM.caCredit});

    return GisEdukaPanel(
      title: 'Répartition des paiements',
      subtitle: 'Comptant vs crédit',
      child: DonutChartWidget(
        theme: _chartTheme,
        compact: true,
        embedded: true,
        title: '',
        centerLabel: 'CA total',
        centerValue: _formatMoney(statsVM.totalCA, compact: true),
        sections: paymentSections,
        colors: [_p.success, _p.warning],
      ),
    );
  }

  Widget _buildFilyRingPanel(StatsViewModel statsVM) {
    return GisEdukaPanel(
      title: 'Indicateurs clés',
      subtitle: statsVM.periodeLabel,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          RingMetricWidget(
            theme: _chartTheme,
            percent: statsVM.margePercent,
            label: 'Marge',
            value: '${statsVM.margePercent.toStringAsFixed(0)}%',
            explanation: 'Bénéfice / CA',
            color: _p.success,
            size: 72,
          ),
          RingMetricWidget(
            theme: _chartTheme,
            percent: statsVM.tauxCredits,
            label: 'Crédit',
            value: '${statsVM.tauxCredits.toStringAsFixed(0)}%',
            explanation: 'Part crédit',
            color: _p.warning,
            size: 72,
          ),
          RingMetricWidget(
            theme: _chartTheme,
            percent: statsVM.tauxActivite,
            label: 'Activité',
            value: '${statsVM.chartData.length}j',
            explanation: 'Jours actifs',
            color: _p.accent,
            size: 72,
          ),
        ],
      ),
    );
  }

  Widget _buildFilyProductsTable(StatsViewModel statsVM) {
    final products = statsVM.topProductsList;
    final productDonut = statsVM.topProductsDonut;

    return GisEdukaPanel(
      title: 'Classement produits',
      subtitle: 'Top ventes par chiffre d\'affaires · ${statsVM.periodeLabel.toLowerCase()}',
      child: products.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 40, color: _p.textDim),
                    const SizedBox(height: 10),
                    Text('Aucune vente sur cette période', style: TextStyle(color: _p.textMute, fontSize: 13)),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                if (productDonut.isNotEmpty) ...[
                  DonutChartWidget(
                    theme: _chartTheme,
                    compact: true,
                    embedded: true,
                    title: '',
                    centerLabel: 'Top 3',
                    centerValue: '${products.length}',
                    sections: productDonut,
                    colors: [_p.accent, _p.info, _p.gold, _p.textDim],
                  ),
                  const SizedBox(height: 16),
                  Divider(height: 1, color: _p.border),
                  const SizedBox(height: 12),
                ],
                _buildTableHeader(),
                const SizedBox(height: 8),
                ...products.asMap().entries.map((e) => _buildProductRow(e.key, e.value)),
              ],
            ),
    );
  }

  Widget _buildTableHeader() {
    return Row(
      children: [
        SizedBox(width: 36, child: Text('#', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(flex: 3, child: Text('Produit', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600))),
        Expanded(child: Text('Qté', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
        Expanded(flex: 2, child: Text('CA', style: TextStyle(color: _p.textMute, fontSize: 11, fontWeight: FontWeight.w600), textAlign: TextAlign.end)),
        const SizedBox(width: 72),
      ],
    );
  }

  Widget _buildProductRow(int index, Map<String, dynamic> p) {
    final ca = (p['ca'] as num?)?.toDouble() ?? 0;
    final qty = (p['quantite'] as num?)?.toStringAsFixed(0) ?? '0';
    final rankColors = [_p.gold, _p.textMute, const Color(0xFFCD7F32)];
    final rankColor = index < 3 ? rankColors[index] : _p.textDim;
    final statusLabel = index == 0 ? 'Top 1' : index == 1 ? 'Top 2' : index == 2 ? 'Top 3' : 'Actif';
    final statusColor = index == 0 ? _p.success : index < 3 ? _p.info : _p.textMute;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: rankColor.withValues(alpha: 0.15),
            child: Text('${index + 1}', style: TextStyle(color: rankColor, fontSize: 11, fontWeight: FontWeight.w800)),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Text(
              p['nom']?.toString() ?? '—',
              style: TextStyle(color: _p.text, fontSize: 13, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(qty, style: TextStyle(color: _p.textMute, fontSize: 12), textAlign: TextAlign.center),
          ),
          Expanded(
            flex: 2,
            child: Text(
              _formatMoney(ca, compact: true),
              style: TextStyle(color: _p.text, fontSize: 12, fontWeight: FontWeight.w700),
              textAlign: TextAlign.end,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilyAnalysis(StatsViewModel statsVM) {
    final cards = statsVM.analysisCards;
    if (cards.isEmpty) return const SizedBox.shrink();

    return GisEdukaPanel(
      title: 'Analyses & explications',
      subtitle: 'Interprétation automatique de vos chiffres',
      child: Column(
        children: cards.map((c) => _AnalysisCard(
              title: c['title'] ?? '',
              body: c['body'] ?? '',
              type: c['type'] ?? 'info',
            )).toList(),
      ),
    );
  }

  Widget _buildPeriodSelector(StatsViewModel statsVM) {
    return GisPeriodSelector(
      periods: const [('semaine', '7 jours'), ('mois', '30 jours'), ('annee', '12 mois')],
      selectedId: statsVM.selectedPeriode,
      enabled: !statsVM.isLoading,
      onSelected: (id) => statsVM.changePeriode(id, shopId!),
    );
  }

  Future<void> _openCalendarModal(StatsViewModel statsVM) async {
    if (shopId == null) return;
    statsVM.clearSelectedDay();
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => Dialog(
        backgroundColor: _p.surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _p.border),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 560,
            maxHeight: MediaQuery.sizeOf(ctx).height * 0.88,
          ),
          child: _CalendarModal(
            shopId: shopId!,
            formatMoney: _formatMoney,
          ),
        ),
      ),
    );
  }

  Widget _buildNoShop() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 56, color: _p.textDim),
            const SizedBox(height: 16),
            Text('Aucune boutique trouvée', style: TextStyle(color: _p.textMute, fontSize: 14)),
          ],
        ),
      );

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _p.accent, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text('Analyse en cours…', style: TextStyle(color: _p.textMute, fontSize: 13)),
          ],
        ),
      );

  Widget _buildError(StatsViewModel statsVM) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: _p.danger.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(statsVM.errorMessage, style: TextStyle(color: _p.textMute), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: shopId != null ? () => statsVM.loadStatsData(shopId!) : null,
                icon: Icon(Icons.refresh_rounded, size: 18),
                label: Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _p.accent,
                  foregroundColor: _p.text,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _FilyMetricTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _FilyMetricTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.textMute, fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: p.text,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _FilySparkCard extends StatelessWidget {
  final String label;
  final String value;
  final String trend;
  final bool trendUp;
  final Color color;

  const _FilySparkCard({
    required this.label,
    required this.value,
    required this.trend,
    required this.trendUp,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.border.withValues(alpha: isDark ? 0.55 : 0.35)),
        boxShadow: isDark
            ? [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 12, offset: const Offset(0, 4))]
            : [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: p.textMute, fontSize: 12, fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              color: p.text,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (trendUp ? p.success : p.danger).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color: trendUp ? p.success : p.danger,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.65,
              minHeight: 4,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modal calendrier — données réelles par jour au clic.
class _CalendarModal extends StatelessWidget {
  final String shopId;
  final String Function(double value, {bool compact}) formatMoney;

  const _CalendarModal({
    required this.shopId,
    required this.formatMoney,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Consumer<StatsViewModel>(
      builder: (context, vm, _) {
        final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(vm.focusedMonth);
        final capitalizedMonth = monthLabel[0].toUpperCase() + monthLabel.substring(1);

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Icon(Icons.calendar_month_rounded, color: p.accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Calendrier des ventes',
                          style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w800),
                        ),
                        Text(
                          'Données réelles · $capitalizedMonth',
                          style: TextStyle(color: p.textMute, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close_rounded, color: p.textMute),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _ModalMiniStat(
                    label: 'CA du mois',
                    value: formatMoney(vm.calendarMonthCA, compact: true),
                    color: p.accentSoft,
                  ),
                  const SizedBox(width: 8),
                  _ModalMiniStat(label: 'Ventes', value: '${vm.calendarMonthVentes}', color: p.info),
                  const SizedBox(width: 8),
                  _ModalMiniStat(label: 'Jours actifs', value: '${vm.calendarJoursActifs}', color: p.success),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                child: Column(
                  children: [
                    TableCalendar(
                      locale: 'fr_FR',
                      firstDay: DateTime(2020),
                      lastDay: DateTime.now().add(const Duration(days: 365)),
                      focusedDay: vm.focusedMonth,
                      selectedDayPredicate: (day) => vm.selectedDay != null && isSameDay(vm.selectedDay, day),
                      startingDayOfWeek: StartingDayOfWeek.monday,
                      calendarFormat: CalendarFormat.month,
                      availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w700),
                        leftChevronIcon: Icon(Icons.chevron_left_rounded, color: p.textMute, size: 22),
                        rightChevronIcon: Icon(Icons.chevron_right_rounded, color: p.textMute, size: 22),
                      ),
                      daysOfWeekStyle: DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: p.textMute, fontSize: 11),
                        weekendStyle: TextStyle(color: p.textMute.withValues(alpha: 0.7), fontSize: 11),
                      ),
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        defaultTextStyle: TextStyle(color: p.text, fontSize: 13),
                        todayDecoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(color: p.accent.withValues(alpha: 0.5)),
                        ),
                        selectedDecoration: BoxDecoration(color: p.accent, shape: BoxShape.circle),
                        selectedTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                        cellMargin: const EdgeInsets.all(4),
                      ),
                      eventLoader: (day) => vm.dayCa(day) > 0 ? [vm.dayCa(day)] : [],
                      onDaySelected: (selected, focused) => vm.selectDay(shopId, selected),
                      onPageChanged: (focused) => vm.loadCalendarMonth(shopId, focused),
                      calendarBuilders: CalendarBuilders(
                        defaultBuilder: (ctx, day, _) => _calendarDayCell(context, vm, day, false, false),
                        todayBuilder: (ctx, day, _) => _calendarDayCell(context, vm, day, true, false),
                        selectedBuilder: (ctx, day, _) => _calendarDayCell(context, vm, day, false, true),
                        outsideBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ),
                    if (vm.selectedDay != null) ...[
                      const SizedBox(height: 12),
                      _DayDetailPanel(vm: vm, formatMoney: formatMoney),
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _calendarDayCell(BuildContext context, StatsViewModel vm, DateTime day, bool isToday, bool isSelected) {
    final p = GisPalette.of(context);
    final ca = vm.dayCa(day);
    final maxCa = vm.calendarMaxCaJour;
    final intensity = maxCa > 0 ? (ca / maxCa).clamp(0.0, 1.0) : 0.0;
    final heatColor = ca > 0
        ? Color.lerp(p.accent.withValues(alpha: 0.08), p.accent.withValues(alpha: 0.45), intensity)!
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected ? p.accent : (isToday ? p.accent.withValues(alpha: 0.12) : heatColor),
        shape: BoxShape.circle,
        border: isToday && !isSelected ? Border.all(color: p.accent.withValues(alpha: 0.5)) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? Colors.white : (ca > 0 ? p.text : p.textMute),
                fontSize: 12,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (ca > 0 && !isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(color: p.success, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }
}

class _ModalMiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ModalMiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(color: GisPalette.of(context).textMute, fontSize: 10)),
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _DayDetailPanel extends StatelessWidget {
  final StatsViewModel vm;
  final String Function(double value, {bool compact}) formatMoney;

  const _DayDetailPanel({required this.vm, required this.formatMoney});

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final day = vm.selectedDay!;
    final label = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
    final capitalized = label[0].toUpperCase() + label.substring(1);
    final summary = vm.selectedDaySummary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: p.surfaceHi,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.event_note_rounded, color: p.accentSoft, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(capitalized, style: TextStyle(color: p.text, fontSize: 13, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (vm.loadingDayDetail)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
              ),
            )
          else if ((summary['ventes'] as int? ?? 0) == 0)
            Text('Aucune vente enregistrée ce jour-là.', style: TextStyle(color: p.textMute, fontSize: 12))
          else ...[
            Row(
              children: [
                _ModalMiniStat(
                  label: 'CA réel',
                  value: formatMoney((summary['ca'] as num?)?.toDouble() ?? 0, compact: true),
                  color: p.accentSoft,
                ),
                const SizedBox(width: 8),
                _ModalMiniStat(label: 'Ventes', value: '${summary['ventes']}', color: p.info),
                const SizedBox(width: 8),
                _ModalMiniStat(
                  label: 'Bénéfice',
                  value: formatMoney((summary['benefice'] as num?)?.toDouble() ?? 0, compact: true),
                  color: p.success,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Détail des transactions', style: TextStyle(color: p.textMute, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            ...vm.selectedDayVentes.map((v) {
              final nom = v['nom_produit']?.toString() ?? 'Vente';
              final total = (v['total'] as num?)?.toDouble() ?? 0;
              final credit = v['est_credit'] == true;
              final client = v['client_nom']?.toString() ?? '';
              final parsed = DateTime.tryParse(v['date_vente']?.toString() ?? '');
              final time = parsed != null ? DateFormat('HH:mm', 'fr_FR').format(parsed.toLocal()) : '';

              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      credit ? Icons.credit_card_rounded : Icons.payments_rounded,
                      size: 16,
                      color: credit ? p.warning : p.success,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(nom, style: TextStyle(color: p.text, fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2),
                          if (client.isNotEmpty || time.isNotEmpty)
                            Text(
                              [if (time.isNotEmpty) time, if (client.isNotEmpty) client].join(' · '),
                              style: TextStyle(color: p.textMute, fontSize: 10),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      formatMoney(total, compact: true),
                      style: TextStyle(color: p.text, fontSize: 12, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String body;
  final String type;

  const _AnalysisCard({required this.title, required this.body, required this.type});

  @override
  Widget build(BuildContext context) {
    final cardColor = switch (type) {
      'success' => GisPalette.of(context).success,
      'warning' => GisPalette.of(context).warning,
      _ => GisPalette.of(context).accent,
    };
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: GisPalette.of(context).surfaceHi,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardColor.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: GisPalette.of(context).text, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: TextStyle(color: GisPalette.of(context).textMute, fontSize: 12, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _IconBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GisPalette.of(context).surfaceHi,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: GisPalette.of(context).border),
          ),
          child: Icon(icon, color: GisPalette.of(context).textMute, size: 20),
        ),
      ),
    );
  }
}
