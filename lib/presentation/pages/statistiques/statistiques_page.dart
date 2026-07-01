import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../../data/repositories/shops_repository.dart';
import '../../viewmodels/stats_viewmodel.dart';
import '../../widgets/custom_charts.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _borderHi = Color(0xFF2E2E33);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _accentSoft = Color(0xFFB8A4FF);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFFF4D6D);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _gold = Color(0xFFFBBF24);
  static const Color _info = Color(0xFF3B82F6);

  String? shopId;
  String? shopName;
  String? devise;

  StatsChartTheme get _chartTheme => const StatsChartTheme(
        surface: _surface,
        border: _border,
        text: _text,
        textMute: _textMute,
        accent: _accent,
        accentSoft: _accentSoft,
        success: _success,
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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _bg,
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
                color: _accent,
                backgroundColor: _surface,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(child: _buildHeader(statsVM)),
                    SliverToBoxAdapter(child: _buildPeriodSelector(statsVM)),
                    SliverToBoxAdapter(child: _buildHeroCard(statsVM)),
                    SliverToBoxAdapter(child: _buildRingMetrics(statsVM)),
                    SliverToBoxAdapter(child: _buildDonutSection(statsVM)),
                    SliverToBoxAdapter(child: _buildCalendar(statsVM)),
                    if (statsVM.selectedDay != null)
                      SliverToBoxAdapter(child: _buildDayDetail(statsVM)),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          BarChartWidget(
                            theme: _chartTheme,
                            data: statsVM.chartData,
                            title: 'Ventes journalières',
                            subtitle: 'Montant réel encaissé chaque jour (${statsVM.periodeLabel.toLowerCase()})',
                          ),
                          const SizedBox(height: 16),
                          LineChartWidget(
                            theme: _chartTheme,
                            data: statsVM.evolutionChartData,
                            title: 'Courbe du chiffre d\'affaires',
                            subtitle: 'Tendance sur ${statsVM.periodeLabel.toLowerCase()}',
                          ),
                          const SizedBox(height: 16),
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

  Widget _buildHeader(StatsViewModel statsVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Statistiques',
                  style: TextStyle(color: _text, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5),
                ),
                const SizedBox(height: 4),
                Text(shopName ?? 'Ma boutique', style: const TextStyle(color: _textMute, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                  'Données réelles de vos ventes (hors annulations)',
                  style: TextStyle(color: _textDim, fontSize: 11),
                ),
              ],
            ),
          ),
          _IconBtn(
            icon: Icons.refresh_rounded,
            onTap: statsVM.isLoading ? null : () => statsVM.refreshData(shopId!),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector(StatsViewModel statsVM) {
    const periods = [('semaine', '7 jours'), ('mois', '30 jours'), ('annee', '12 mois')];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: periods.map((p) {
            final selected = statsVM.selectedPeriode == p.$1;
            return Expanded(
              child: GestureDetector(
                onTap: statsVM.isLoading ? null : () => statsVM.changePeriode(p.$1, shopId!),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? _accent.withValues(alpha: 0.15) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: selected ? Border.all(color: _accent.withValues(alpha: 0.4)) : null,
                  ),
                  child: Center(
                    child: Text(
                      p.$2,
                      style: TextStyle(
                        color: selected ? _accentSoft : _textMute,
                        fontSize: 12,
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

  Widget _buildHeroCard(StatsViewModel statsVM) {
    final evo = statsVM.evolutionCA;
    final isUp = evo >= 0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [_accent.withValues(alpha: 0.18), _surface, _surface],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _chip(statsVM.periodeLabel, _accentSoft),
                const Spacer(),
                if (statsVM.isLoading)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _accent.withValues(alpha: 0.6)),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Chiffre d\'affaires total', style: TextStyle(color: _textMute, fontSize: 13)),
            const SizedBox(height: 6),
            Text(
              _formatMoney(statsVM.totalCA),
              style: const TextStyle(color: _text, fontSize: 32, fontWeight: FontWeight.w800, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              '${statsVM.totalVentes} vente${statsVM.totalVentes > 1 ? 's' : ''} · '
              'Bénéfice ${_formatMoney(statsVM.beneficeTotal, compact: true)} · '
              '${statsVM.totalClients} client${statsVM.totalClients > 1 ? 's' : ''}',
              style: const TextStyle(color: _textDim, fontSize: 11),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isUp ? _success : _danger).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(isUp ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                          size: 14, color: isUp ? _success : _danger),
                      const SizedBox(width: 4),
                      Text(
                        '${isUp ? '+' : ''}${evo.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: isUp ? _success : _danger,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Text('vs période précédente', style: TextStyle(color: _textDim, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 3 cercles : marge, crédit, activité
  Widget _buildRingMetrics(StatsViewModel statsVM) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Indicateurs circulaires',
                style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Pourcentages calculés sur vos ventes réelles de la période',
                style: TextStyle(color: _textDim, fontSize: 11),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RingMetricWidget(
                  theme: _chartTheme,
                  percent: statsVM.margePercent,
                  label: 'Marge nette',
                  value: _formatMoney(statsVM.beneficeTotal, compact: true),
                  explanation: 'Part bénéfice / CA',
                  color: _success,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  percent: statsVM.tauxCredits,
                  label: 'Ventes crédit',
                  value: '${statsVM.tauxCredits.toStringAsFixed(0)}%',
                  explanation: 'Dossiers à crédit',
                  color: _warning,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  percent: statsVM.tauxActivite,
                  label: 'Jours actifs',
                  value: '${statsVM.chartData.length} j',
                  explanation: 'Jours avec ventes',
                  color: _accent,
                ),
              ],
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
      colors: const [_success, _warning],
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
      colors: const [_accent, _info, _gold, _textDim],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Répartitions',
              style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
            ),
            Text(
              'Paiements et produits · ${statsVM.periodeLabel.toLowerCase()}',
              style: const TextStyle(color: _textDim, fontSize: 11),
            ),
            const SizedBox(height: 14),
            LayoutBuilder(
              builder: (context, constraints) {
                final sideBySide = constraints.maxWidth >= 300;
                if (sideBySide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: paymentDonut),
                        Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: _border),
                        Expanded(child: productsDonut),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    paymentDonut,
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: _border, height: 1),
                    ),
                    productsDonut,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(StatsViewModel statsVM) {
    final monthLabel = DateFormat('MMMM yyyy', 'fr_FR').format(statsVM.focusedMonth);
    final capitalizedMonth = monthLabel[0].toUpperCase() + monthLabel.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: _accentSoft, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Calendrier des ventes',
                        style: TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        'Touchez un jour pour voir le détail · $capitalizedMonth',
                        style: const TextStyle(color: _textDim, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _miniStat('CA du mois', _formatMoney(statsVM.calendarMonthCA, compact: true), _accentSoft),
                const SizedBox(width: 8),
                _miniStat('Ventes', '${statsVM.calendarMonthVentes}', _info),
                const SizedBox(width: 8),
                _miniStat('Jours actifs', '${statsVM.calendarJoursActifs}', _success),
              ],
            ),
            const SizedBox(height: 12),
            TableCalendar(
              locale: 'fr_FR',
              firstDay: DateTime(2020),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: statsVM.focusedMonth,
              selectedDayPredicate: (day) =>
                  statsVM.selectedDay != null && isSameDay(statsVM.selectedDay, day),
              startingDayOfWeek: StartingDayOfWeek.monday,
              calendarFormat: CalendarFormat.month,
              availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: const TextStyle(color: _text, fontSize: 14, fontWeight: FontWeight.w700),
                leftChevronIcon: const Icon(Icons.chevron_left_rounded, color: _textMute, size: 22),
                rightChevronIcon: const Icon(Icons.chevron_right_rounded, color: _textMute, size: 22),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(color: _textDim, fontSize: 11),
                weekendStyle: TextStyle(color: _textMute.withValues(alpha: 0.7), fontSize: 11),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                defaultTextStyle: const TextStyle(color: _text, fontSize: 13),
                weekendTextStyle: TextStyle(color: _textMute.withValues(alpha: 0.8), fontSize: 13),
                todayDecoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: _accent.withValues(alpha: 0.5)),
                ),
                todayTextStyle: const TextStyle(color: _accentSoft, fontWeight: FontWeight.w700),
                selectedDecoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                selectedTextStyle: const TextStyle(color: _text, fontWeight: FontWeight.w800),
                markerDecoration: const BoxDecoration(color: _success, shape: BoxShape.circle),
                markersMaxCount: 1,
                markerSize: 5,
                cellMargin: const EdgeInsets.all(4),
              ),
              eventLoader: (day) {
                final ca = statsVM.dayCa(day);
                return ca > 0 ? [ca] : [];
              },
              onDaySelected: (selected, focused) {
                statsVM.selectDay(shopId!, selected);
              },
              onPageChanged: (focused) {
                statsVM.loadCalendarMonth(shopId!, focused);
              },
              calendarBuilders: CalendarBuilders(
                defaultBuilder: (context, day, focusedDay) => _buildCalendarDay(day, statsVM, false, false),
                todayBuilder: (context, day, focusedDay) => _buildCalendarDay(day, statsVM, true, false),
                selectedBuilder: (context, day, focusedDay) => _buildCalendarDay(day, statsVM, false, true),
                outsideBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _legendDot(_success, 'Jour avec ventes'),
                const SizedBox(width: 16),
                _legendDot(_accent.withValues(alpha: 0.4), 'Intensité = CA élevé'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDay(DateTime day, StatsViewModel statsVM, bool isToday, bool isSelected) {
    final ca = statsVM.dayCa(day);
    final maxCa = statsVM.calendarMaxCaJour;
    final intensity = maxCa > 0 ? (ca / maxCa).clamp(0.0, 1.0) : 0.0;
    final heatColor = ca > 0
        ? Color.lerp(_accent.withValues(alpha: 0.08), _accent.withValues(alpha: 0.45), intensity)!
        : Colors.transparent;

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected ? _accent : (isToday ? _accent.withValues(alpha: 0.12) : heatColor),
        shape: BoxShape.circle,
        border: isToday && !isSelected ? Border.all(color: _accent.withValues(alpha: 0.5)) : null,
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.day}',
              style: TextStyle(
                color: isSelected ? _text : (ca > 0 ? _text : _textMute),
                fontSize: 12,
                fontWeight: isSelected || isToday ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
            if (ca > 0 && !isSelected)
              Container(
                width: 4,
                height: 4,
                margin: const EdgeInsets.only(top: 1),
                decoration: const BoxDecoration(color: _success, shape: BoxShape.circle),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayDetail(StatsViewModel statsVM) {
    final day = statsVM.selectedDay!;
    final data = statsVM.dayData(day);
    final label = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(day);
    final capitalized = label[0].toUpperCase() + label.substring(1);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surfaceHi,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_note_rounded, color: _accentSoft, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    capitalized,
                    style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (data == null || (data['ventes'] as int? ?? 0) == 0)
              Text(
                'Aucune vente ce jour-là.',
                style: TextStyle(color: _textMute, fontSize: 12),
              )
            else ...[
              Row(
                children: [
                  _miniStat('CA', _formatMoney((data['ca'] as num?)?.toDouble() ?? 0, compact: true), _accentSoft),
                  const SizedBox(width: 8),
                  _miniStat('Ventes', '${data['ventes']}', _info),
                  const SizedBox(width: 8),
                  _miniStat(
                    'Bénéfice',
                    _formatMoney((data['benefice'] as num?)?.toDouble() ?? 0, compact: true),
                    _success,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (statsVM.loadingDayDetail)
                const Center(child: Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                ))
              else
                ...statsVM.selectedDayVentes.take(5).map((v) {
                  final nom = v['nom_produit']?.toString() ?? 'Vente';
                  final total = (v['total'] as num?)?.toDouble() ?? 0;
                  final credit = v['est_credit'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Icon(
                          credit ? Icons.credit_card_rounded : Icons.payments_rounded,
                          size: 14,
                          color: credit ? _warning : _success,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            nom,
                            style: const TextStyle(color: _text, fontSize: 11),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          _formatMoney(total, compact: true),
                          style: const TextStyle(color: _textMute, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              if (statsVM.selectedDayVentes.length > 5)
                Text(
                  '+ ${statsVM.selectedDayVentes.length - 5} autre(s) vente(s)',
                  style: TextStyle(color: _textDim, fontSize: 10),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(StatsViewModel statsVM) {
    final products = statsVM.topProductsList;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Classement produits', style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          const Text('Basé sur le CA réel généré', style: TextStyle(color: _textDim, fontSize: 11)),
          const SizedBox(height: 16),
          if (products.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    Icon(Icons.inventory_2_outlined, size: 36, color: _textDim),
                    const SizedBox(height: 8),
                    Text('Aucune vente enregistrée', style: TextStyle(color: _textMute, fontSize: 12)),
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
              final rankColors = [_gold, _textMute, const Color(0xFFCD7F32)];

              return Padding(
                padding: EdgeInsets.only(bottom: i < products.length - 1 ? 12 : 0),
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: (i < 3 ? rankColors[i] : _textDim).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: (i < 3 ? rankColors[i] : _textDim).withValues(alpha: 0.25)),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: i < 3 ? rankColors[i] : _textMute,
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
                            style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w500),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 4,
                              backgroundColor: _borderHi,
                              valueColor: AlwaysStoppedAnimation(_accent.withValues(alpha: 0.8)),
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
                          style: const TextStyle(color: _accentSoft, fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${((p['quantite'] as num?)?.toStringAsFixed(0) ?? '0')} vendus',
                          style: const TextStyle(color: _textDim, fontSize: 10),
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
            Icon(Icons.auto_awesome_rounded, size: 16, color: _gold),
            const SizedBox(width: 8),
            const Text(
              'Analyses & explications',
              style: TextStyle(color: _text, fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Interprétation automatique de vos chiffres réels',
          style: TextStyle(color: _textDim, fontSize: 11),
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

  Widget _miniStat(String label, String value, Color color) {
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
            Text(label, style: TextStyle(color: _textDim, fontSize: 9)),
            Text(value, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(color: _textDim, fontSize: 10)),
      ],
    );
  }

  Widget _buildNoShop() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store_outlined, size: 56, color: _textDim),
            const SizedBox(height: 16),
            Text('Aucune boutique trouvée', style: TextStyle(color: _textMute, fontSize: 14)),
          ],
        ),
      );

  Widget _buildLoading() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _accent, strokeWidth: 2.5),
            const SizedBox(height: 16),
            Text('Analyse en cours…', style: TextStyle(color: _textMute, fontSize: 13)),
          ],
        ),
      );

  Widget _buildError(StatsViewModel statsVM) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: _danger.withValues(alpha: 0.6)),
              const SizedBox(height: 16),
              Text(statsVM.errorMessage, style: TextStyle(color: _textMute), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: shopId != null ? () => statsVM.loadStatsData(shopId!) : null,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Réessayer'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: _text,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      );
}

class _AnalysisCard extends StatelessWidget {
  final String title;
  final String body;
  final String type;

  const _AnalysisCard({required this.title, required this.body, required this.type});

  Color get _color {
    switch (type) {
      case 'success':
        return const Color(0xFF22C55E);
      case 'warning':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF7C5CFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(color: _color, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body, style: const TextStyle(color: Color(0xFF8A8A92), fontSize: 12, height: 1.45)),
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
      color: const Color(0xFF161618),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF222226)),
          ),
          child: Icon(icon, color: const Color(0xFF8A8A92), size: 20),
        ),
      ),
    );
  }
}
