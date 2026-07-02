import 'package:flutter/material.dart';
import '../../../core/theme/gis_palette.dart';
import '../../../core/theme/gis_theme_ext.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/repositories/shops_repository.dart';
import '../../viewmodels/stats_viewmodel.dart';
import '../../widgets/custom_charts.dart';
import '../../widgets/gis_dashboard_widgets.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  GisPalette get _p => GisPalette.of(context);


  String? shopId;
  String? shopName;
  String? devise;

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
                    SliverToBoxAdapter(child: _buildPageHeader(statsVM)),
                    SliverToBoxAdapter(child: _buildPeriodSelector(statsVM)),
                    SliverToBoxAdapter(child: _buildMainKpiGrid(statsVM)),
                    SliverToBoxAdapter(child: _buildEvolutionSection(statsVM)),
                    SliverToBoxAdapter(child: _buildDonutSection(statsVM)),
                    SliverToBoxAdapter(child: _buildRingMetrics(statsVM)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _buildTopProducts(statsVM),
                          const SizedBox(height: 16),
                          _buildAnalysis(statsVM),
                          const SizedBox(height: 24),
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

  Widget _buildPageHeader(StatsViewModel statsVM) {
    final now = DateFormat('dd/MM/yyyy', 'fr_FR').format(DateTime.now());
    return GisAnalyticsHeader(
      title: 'Statistiques avancées',
      subtitle: 'Analysez les performances de ${shopName ?? 'votre boutique'} · données réelles (hors annulations)',
      badge: now,
      onRefresh: statsVM.isLoading ? null : () => statsVM.refreshData(shopId!),
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

  Widget _buildMainKpiGrid(StatsViewModel statsVM) {
    final evo = statsVM.evolutionCA;
    final evoNorm = ((evo.abs() / 100).clamp(0.0, 1.0)).toDouble();

    return GisStatCardGrid(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      cards: [
        GisGradientStatCard(
          label: 'Chiffre d\'affaires',
          value: _formatMoney(statsVM.totalCA, compact: true),
          subtitle: statsVM.periodeLabel,
          icon: Icons.payments_rounded,
          gradient: const [Color(0xFF7C5CFF), Color(0xFF5B3FE6)],
          progress: evoNorm,
        ),
        GisGradientStatCard(
          label: 'Ventes',
          value: '${statsVM.totalVentes}',
          subtitle: '${evo >= 0 ? '+' : ''}${evo.toStringAsFixed(1)}% vs période préc.',
          icon: Icons.receipt_long_rounded,
          gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
        ),
        GisGradientStatCard(
          label: 'Clients',
          value: '${statsVM.totalClients}',
          subtitle: 'Panier moy. ${_formatMoney(statsVM.panierMoyen, compact: true)}',
          icon: Icons.people_rounded,
          gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
        ),
        GisGradientStatCard(
          label: 'Bénéfice net',
          value: _formatMoney(statsVM.beneficeTotal, compact: true),
          subtitle: 'Marge ${statsVM.margePercent.toStringAsFixed(0)}%',
          icon: Icons.account_balance_wallet_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
      ],
    );
  }

  Widget _buildEvolutionSection(StatsViewModel statsVM) {
    final evo = statsVM.evolutionCA;
    final isUp = evo >= 0;
    final trendLabel = '${isUp ? '+' : ''}${evo.toStringAsFixed(1)}% vs période préc.';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: EvolutionAreaChartWidget(
        theme: _chartTheme,
        data: statsVM.evolutionChartData,
        title: 'Évolution du chiffre d\'affaires',
        subtitle: statsVM.periodeLabel,
        trendLabel: trendLabel,
        height: 280,
        trailing: OutlinedButton.icon(
          onPressed: shopId == null ? null : () => _openCalendarModal(statsVM),
          icon: Icon(Icons.calendar_month_rounded, size: 18, color: _p.accent),
          label: Text('Calendrier', style: TextStyle(color: _p.text, fontWeight: FontWeight.w600)),
          style: OutlinedButton.styleFrom(
            backgroundColor: _p.surfaceHi,
            side: BorderSide(color: _p.accent.withValues(alpha: 0.45)),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),
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

  /// 3 cercles : marge, crédit, activité
  Widget _buildRingMetrics(StatsViewModel statsVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GisChartPanel(
        title: 'Indicateurs circulaires',
        subtitle: 'Marge · crédits · activité sur ${statsVM.periodeLabel.toLowerCase()}',
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            RingMetricWidget(
              theme: _chartTheme,
              percent: statsVM.margePercent,
              label: 'Marge nette',
              value: _formatMoney(statsVM.beneficeTotal, compact: true),
              explanation: 'Part bénéfice / CA',
              color: _p.success,
            ),
            RingMetricWidget(
              theme: _chartTheme,
              percent: statsVM.tauxCredits,
              label: 'Ventes crédit',
              value: '${statsVM.tauxCredits.toStringAsFixed(0)}%',
              explanation: 'Dossiers à crédit',
              color: _p.warning,
            ),
            RingMetricWidget(
              theme: _chartTheme,
              percent: statsVM.tauxActivite,
              label: 'Jours actifs',
              value: '${statsVM.chartData.length} j',
              explanation: 'Jours avec ventes',
              color: _p.accent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutSection(StatsViewModel statsVM) {
    final paymentSections = <Map<String, dynamic>>[];
    if (statsVM.caComptant > 0) {
      paymentSections.add({'label': 'Comptant', 'value': statsVM.caComptant});
    }
    if (statsVM.caCredit > 0) {
      paymentSections.add({'label': 'Crédit', 'value': statsVM.caCredit});
    }

    final paymentDonut = DonutChartWidget(
      theme: _chartTheme,
      compact: true,
      embedded: true,
      title: 'Paiements',
      subtitle: 'Comptant / crédit',
      centerLabel: 'CA',
      centerValue: _formatMoney(statsVM.totalCA, compact: true),
      sections: paymentSections,
      colors: [_p.success, _p.warning],
    );

    final productsDonut = DonutChartWidget(
      theme: _chartTheme,
      compact: true,
      embedded: true,
      title: 'Produits',
      subtitle: 'Top 3 + autres',
      centerLabel: 'Refs',
      centerValue: '${statsVM.topProductsList.length}',
      sections: statsVM.topProductsDonut,
      colors: [_p.accent, _p.info, _p.gold, _p.textDim],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GisChartPanel(
        title: 'Répartitions',
        subtitle: 'Paiements et produits · ${statsVM.periodeLabel.toLowerCase()} · Total ${_formatMoney(statsVM.totalCA, compact: true)}',
        child: GisDashboardSplit(
          left: paymentDonut,
          right: productsDonut,
        ),
      ),
    );
  }

  Widget _buildTopProducts(StatsViewModel statsVM) {
    final products = statsVM.topProductsList;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: _p.cardDecoration(context, radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
           Text('Classement produits', style: TextStyle(color: _p.text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
           Text('Basé sur le CA réel généré', style: TextStyle(color: _p.textDim, fontSize: 11)),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 36, color: _p.textDim),
                    const SizedBox(height: 8),
                    Text('Aucune vente enregistrée', style: TextStyle(color: _p.textMute, fontSize: 12)),
                  ],
                ),
              ),
            )
          else
            ...products.asMap().entries.map((entry) {
              final i = entry.key;
              final p = entry.value;
              final ca = (p['ca'] as num?)?.toDouble() ?? 0;
              final maxCa = (products.first['ca'] as num?)?.toDouble() ?? 1;
              final progress = maxCa > 0 ? ca / maxCa : 0.0;
              final rankColors = [_p.gold, _p.textMute, Color(0xFFCD7F32)];

              return Padding(
                padding: EdgeInsets.only(bottom: i < products.length - 1 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (i < 3 ? rankColors[i] : _p.textDim).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (i < 3 ? rankColors[i] : _p.textDim).withValues(alpha: 0.25)),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i < 3 ? rankColors[i] : _p.textMute,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p['nom']?.toString() ?? '—',
                            style:  TextStyle(color: _p.text, fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: _p.borderStrong,
                              valueColor: AlwaysStoppedAnimation(_p.accent.withValues(alpha: 0.8)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _formatMoney(ca, compact: true),
                          style:  TextStyle(color: _p.accentSoft, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${((p['quantite'] as num?)?.toStringAsFixed(0) ?? '0')} vendus',
                          style:  TextStyle(color: _p.textDim, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAnalysis(StatsViewModel statsVM) {
    final cards = statsVM.analysisCards;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.auto_awesome_rounded, size: 16, color: _p.gold),
            const SizedBox(width: 8),
             Text(
              'Analyses & explications',
              style: TextStyle(color: _p.text, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
         Text(
          'Interprétation automatique de vos chiffres réels',
          style: TextStyle(color: _p.textDim, fontSize: 11),
        ),
        const SizedBox(height: 12),
        ...cards.map((c) => _AnalysisCard(
              title: c['title'] ?? '',
              body: c['body'] ?? '',
              type: c['type'] ?? 'info',
            )),
      ],
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
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
