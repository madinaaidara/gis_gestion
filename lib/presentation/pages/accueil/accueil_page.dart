import 'package:flutter/material.dart';
import '../../../core/theme/gis_palette.dart';
import '../../../core/theme/gis_theme_ext.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/accueil_repository.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../../core/services/app_refresh_listener.dart';
import '../../../core/services/app_refresh_notifier.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../widgets/custom_charts.dart';
import '../../widgets/gis_dashboard_widgets.dart';

class AccueilPage extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const AccueilPage({super.key, this.onNavigate});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> with TickerProviderStateMixin, AppRefreshListener {
  GisPalette get _p => GisPalette.of(context);

  @override
  AppRefreshScope get refreshScope => AppRefreshScope.dashboard;

  @override
  void onAppRefresh() => _loadData();

  final _repo = AccueilRepository();

  String? shopId;
  String? shopName;
  String? proprietaire;
  String? devise;
  String? userName;
  bool _loading = true;
  bool _entrancePlayed = false;
  String _salesFilter = 'all';
  Map<String, dynamic> _data = {};

  late AnimationController _entranceController;
  late AnimationController _countController;
  late Animation<double> _entranceAnim;
  late Animation<double> _countAnim;

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
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _countAnim = CurvedAnimation(parent: _countController, curve: Curves.easeOutExpo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _countController.dispose();
    super.dispose();
  }

  void _playEntrance() {
    if (_entrancePlayed) return;
    _entrancePlayed = true;
    _entranceController.forward(from: 0);
    _countController.forward(from: 0);
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final isFirstLoad = _data.isEmpty;
    setState(() {
      if (isFirstLoad) _loading = true;
    });
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      userName = user.userMetadata?['full_name']?.toString() ??
          user.email?.split('@').first ??
          'Gérant';

      try {
        final profile = await Supabase.instance.client
            .from('profiles')
            .select('full_name')
            .eq('id', user.id)
            .maybeSingle();
        if (profile?['full_name'] != null) userName = profile!['full_name'].toString();
      } catch (_) {}

      if (!mounted) return;
      final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopRepo.checkAndLoadShop(user.id);
      if (!mounted || shopRepo.currentShop == null) return;

      shopId = shopRepo.currentShop!.id;
      shopName = shopRepo.currentShop!.nomBoutique;
      proprietaire = shopRepo.currentShop!.proprietaire;
      devise = shopRepo.currentShop?.devise ?? 'FCFA';
      _data = await _repo.getDashboardSummary(shopId!);
    } catch (e) {
      debugPrint('Erreur accueil: $e');
    }
    if (mounted) {
      setState(() => _loading = false);
      _playEntrance();
    }
  }

  void _go(int index) {
    HapticFeedback.selectionClick();
    widget.onNavigate?.call(index);
  }

  String _formatMoney(double v, {bool compact = false}) {
    if (compact) {
      if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    }
    return NumberFormat('#,##0', 'fr_FR').format(v.round());
  }

  String _moneyLabel(double v, {bool compact = false}) =>
      '${_formatMoney(v, compact: compact)} ${devise ?? 'FCFA'}';

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Bonjour';
    if (h < 18) return 'Bon après-midi';
    return 'Bonsoir';
  }

  double _d(String key) => (_data[key] as num?)?.toDouble() ?? 0;
  int _i(String key) => (_data[key] as num?)?.toInt() ?? 0;

  Widget _stagger(int index, Widget child) {
    return AnimatedBuilder(
      animation: _entranceAnim,
      builder: (context, _) {
        final start = (index * 0.07).clamp(0.0, 0.55);
        final end = (start + 0.45).clamp(0.0, 1.0);
        final t = _intervalProgress(_entranceAnim.value, start, end);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, 28 * (1 - t)),
            child: Transform.scale(
              scale: 0.94 + 0.06 * t,
              child: child,
            ),
          ),
        );
      },
    );
  }

  double _intervalProgress(double value, double start, double end) {
    if (value <= start) return 0;
    if (value >= end) return 1;
    return (value - start) / (end - start);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return TooltipTheme(
      data: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1E) : _p.text,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _p.border),
        ),
        textStyle: TextStyle(color: isDark ? _p.text : Colors.white, fontSize: 12, height: 1.35),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        waitDuration: const Duration(milliseconds: 300),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: isDark
            ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
            : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: _p.bg,
          body: SafeArea(
            child: _loading
                ? const _DashboardSkeleton()
                : RefreshIndicator(
                    onRefresh: _loadData,
                    color: _p.accent,
                    backgroundColor: _p.surface,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                      slivers: [
                        SliverToBoxAdapter(child: _stagger(0, _buildEdukaHeader())),
                        SliverToBoxAdapter(child: _stagger(1, _buildEdukaSummaryRow())),
                        SliverToBoxAdapter(child: _stagger(2, _buildEdukaMainContent())),
                        const SliverToBoxAdapter(child: SizedBox(height: 16)),
                        SliverToBoxAdapter(child: _stagger(3, _buildAlerts())),
                        SliverToBoxAdapter(child: SizedBox(height: ResponsiveUtils.scrollBottomInset(context))),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEdukaHeader() {
    final displayName = proprietaire?.isNotEmpty == true ? proprietaire! : userName ?? 'Gérant';
    final isWide = ResponsiveUtils.isPageWide(context);
    final dateStr = DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now());
    final dateLabel = dateStr.isNotEmpty ? '${dateStr[0].toUpperCase()}${dateStr.substring(1)}' : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(isWide ? 24 : 16, 20, isWide ? 24 : 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_greeting, $displayName 👋',
                      style: GoogleFonts.plusJakartaSans(
                        color: _p.text,
                        fontSize: isWide ? 26 : 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        height: 1.15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      shopName ?? 'Ma boutique',
                      style: TextStyle(color: _p.textMute, fontSize: 13, fontWeight: FontWeight.w500),
                    ),
                    if (dateLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(dateLabel, style: TextStyle(color: _p.textDim, fontSize: 12)),
                    ],
                  ],
                ),
              ),
              if (isWide) ...[
                FilledButton.icon(
                  onPressed: () => _go(1),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Nouvelle vente'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _p.success,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              _TipIconButton(
                icon: Icons.refresh_rounded,
                tooltip: 'Actualiser le tableau de bord',
                onTap: _loadData,
              ),
            ],
          ),
        ),
        _buildEdukaMobileCta(),
      ],
    );
  }

  Widget _buildEdukaMobileCta() {
    final isWide = ResponsiveUtils.isPageWide(context);
    if (isWide) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: () => _go(1),
          icon: const Icon(Icons.add_rounded, size: 18),
          label: const Text('Nouvelle vente'),
          style: FilledButton.styleFrom(
            backgroundColor: _p.success,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ),
    );
  }

  Widget _buildEdukaSummaryRow() {
    final objectif = _d('objectif_jour_percent');
    final totalProd = _i('total_produits');
    final stockPct = totalProd > 0 ? _i('stock_ok') / totalProd : 0.0;
    final credits = _i('credits_en_cours');

    final cards = [
      _EdukaSummaryCardData(
        label: 'Chiffre d\'affaires du jour',
        value: _moneyLabel(_d('ca_jour'), compact: true),
        footerLabel: 'Objectif ${objectif.toStringAsFixed(0)}% vs moyenne',
        footerProgress: (objectif / 100).clamp(0.0, 1.0),
        icon: Icons.payments_rounded,
        gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
        animateValue: _d('ca_jour'),
      ),
      _EdukaSummaryCardData(
        label: 'Ventes aujourd\'hui',
        value: '${_i('ventes_jour')}',
        footerLabel: '${_i('ventes_comptant_jour')} comptant · ${_i('ventes_credit_jour')} crédit',
        footerProgress: _i('ventes_jour') > 0 ? _i('ventes_comptant_jour') / _i('ventes_jour') : 0,
        icon: Icons.receipt_long_rounded,
        gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
      ),
      _EdukaSummaryCardData(
        label: 'CA du mois',
        value: _moneyLabel(_d('ca_mois'), compact: true),
        footerLabel: 'Marge ${_d('marge_mois_percent').toStringAsFixed(0)}% · ${_i('ventes_mois')} ventes',
        footerProgress: (_d('marge_mois_percent') / 100).clamp(0.0, 1.0),
        icon: Icons.trending_up_rounded,
        gradient: const [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
      _EdukaSummaryCardData(
        label: credits > 0 ? 'Crédits en cours' : 'Catalogue produits',
        value: credits > 0 ? '$credits' : '$totalProd',
        footerLabel: credits > 0
            ? 'Reste ${_moneyLabel(_d('credits_reste_total'), compact: true)}'
            : '${_i('stock_ok')} en stock sain',
        footerProgress: credits > 0 ? 0.65 : stockPct,
        icon: credits > 0 ? Icons.credit_card_rounded : Icons.inventory_2_rounded,
        gradient: const [Color(0xFFF97316), Color(0xFFEA580C)],
      ),
    ];

    return GisFourKpiLayout(
      horizontalPadding: ResponsiveUtils.pageHorizontalPadding(context),
      topPadding: 4,
      bottomPadding: 12,
      children: [for (final c in cards) _buildAnimatedSummaryCard(c)],
    );
  }

  Widget _buildAnimatedSummaryCard(_EdukaSummaryCardData card) {
    if (card.animateValue != null) {
      return AnimatedBuilder(
        animation: _countAnim,
        builder: (context, _) {
          final animated = card.animateValue! * _countAnim.value;
          return GisEdukaSummaryCard(
            label: card.label,
            value: _moneyLabel(animated, compact: true),
            footerLabel: card.footerLabel,
            footerProgress: card.footerProgress * _countAnim.value,
            icon: card.icon,
            gradient: card.gradient,
          );
        },
      );
    }
    return GisEdukaSummaryCard(
      label: card.label,
      value: card.value,
      footerLabel: card.footerLabel,
      footerProgress: card.footerProgress,
      icon: card.icon,
      gradient: card.gradient,
    );
  }

  Widget _buildEdukaMainContent() {
    final isWide = ResponsiveUtils.isKpiRowWide(context);
    final horizontalPad = isWide ? 24.0 : 16.0;
    final left = _buildEdukaSalesPanel();
    final right = Column(
      children: [
        _buildEdukaEvolutionChart(),
        const SizedBox(height: 12),
        _buildEdukaPaymentDonut(),
      ],
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPad, 0, horizontalPad, 8),
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

  Widget _buildEdukaEvolutionChart() {
    final caParJour = List<Map<String, dynamic>>.from(_data['ca_par_jour'] ?? []);
    String? trendLabel;
    if (caParJour.length >= 2) {
      final last = (caParJour.last['value'] as num?)?.toDouble() ?? 0;
      final prev = (caParJour[caParJour.length - 2]['value'] as num?)?.toDouble() ?? 0;
      if (prev > 0) {
        final pct = ((last - prev) / prev * 100);
        trendLabel = '${pct >= 0 ? '+' : ''}${pct.toStringAsFixed(0)}% vs hier';
      }
    }

    return EvolutionAreaChartWidget(
      theme: _chartTheme,
      data: caParJour,
      title: 'Évolution des ventes',
      subtitle: '7 derniers jours',
      trendLabel: trendLabel,
      height: 220,
    );
  }

  Widget _buildEdukaPaymentDonut() {
    final comptant = _d('ca_comptant_jour');
    final credit = _d('ca_credit_jour');
    final sections = <Map<String, dynamic>>[];
    if (comptant > 0) sections.add({'label': 'Comptant', 'value': comptant});
    if (credit > 0) sections.add({'label': 'Crédit', 'value': credit});

    return GisEdukaPanel(
      title: 'Répartition du jour',
      subtitle: 'Comptant vs crédit',
      child: DonutChartWidget(
        theme: _chartTheme,
        compact: true,
        embedded: true,
        title: '',
        centerLabel: 'CA jour',
        centerValue: _formatMoney(_d('ca_jour'), compact: true),
        sections: sections,
        colors: [_p.success, _p.warning],
      ),
    );
  }

  Widget _buildEdukaSalesPanel() {
    final ventes = List<Map<String, dynamic>>.from(_data['ventes_recentes'] ?? []);
    final filtered = ventes.where((v) {
      if (_salesFilter == 'comptant') return v['est_credit'] != true;
      if (_salesFilter == 'credit') return v['est_credit'] == true;
      return true;
    }).toList();

    return GisEdukaPanel(
      title: 'Dernières ventes',
      subtitle: '${_i('ventes_jour')} vente${_i('ventes_jour') > 1 ? 's' : ''} aujourd\'hui',
      trailing: GestureDetector(
        onTap: () => _go(4),
        child: Text(
          'Voir tout →',
          style: TextStyle(color: _p.success, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEdukaSalesTabs(),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.receipt_long_outlined, size: 40, color: _p.textDim),
                    const SizedBox(height: 10),
                    Text(
                      'Aucune vente — lancez une vente depuis la caisse.',
                      style: TextStyle(color: _p.textMute, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    FilledButton.icon(
                      onPressed: () => _go(1),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Nouvelle vente'),
                      style: FilledButton.styleFrom(
                        backgroundColor: _p.success,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filtered.map((v) => _buildEdukaSaleRow(v)),
        ],
      ),
    );
  }

  Widget _buildEdukaSalesTabs() {
    const tabs = [('all', 'Toutes'), ('comptant', 'Comptant'), ('credit', 'Crédit')];

    return Row(
      children: tabs.map((tab) {
        final selected = _salesFilter == tab.$1;
        return Padding(
          padding: const EdgeInsets.only(right: 20),
          child: GestureDetector(
            onTap: () => setState(() => _salesFilter = tab.$1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tab.$2,
                  style: TextStyle(
                    color: selected ? _p.success : _p.textMute,
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 3,
                  width: selected ? 36 : 0,
                  decoration: BoxDecoration(
                    color: _p.success,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEdukaSaleRow(Map<String, dynamic> v) {
    final nom = v['nom_produit']?.toString() ?? 'Vente';
    final total = (v['total'] as num?)?.toDouble() ?? 0;
    final credit = v['est_credit'] == true;
    final client = v['client_nom']?.toString();
    final parsed = DateTime.tryParse(v['date_vente']?.toString() ?? '');
    final timeLabel = parsed != null ? DateFormat('dd/MM · HH:mm', 'fr_FR').format(parsed.toLocal()) : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: (credit ? _p.warning : _p.success).withValues(alpha: 0.12),
            child: Icon(
              credit ? Icons.credit_card_rounded : Icons.payments_rounded,
              size: 18,
              color: credit ? _p.warning : _p.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nom,
                  style: TextStyle(color: _p.text, fontSize: 13, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (client != null && client.isNotEmpty)
                  Text(client, style: TextStyle(color: _p.textMute, fontSize: 11), maxLines: 1),
                if (timeLabel.isNotEmpty)
                  Text(timeLabel, style: TextStyle(color: _p.textDim, fontSize: 10)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _moneyLabel(total, compact: true),
                style: TextStyle(color: _p.text, fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (credit ? _p.warning : _p.success).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  credit ? 'Crédit' : 'Comptant',
                  style: TextStyle(
                    color: credit ? _p.warning : _p.success,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeBlock() {
    final displayName = proprietaire?.isNotEmpty == true ? proprietaire! : userName ?? 'Gérant';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GisDashboardWelcome(
          userName: displayName,
          shopName: shopName,
          onRefresh: _loadData,
        ),
        _buildHero(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              GisDashboardAction(
                label: 'Nouvelle vente',
                icon: Icons.add_rounded,
                primary: true,
                onTap: () => _go(1),
              ),
              GisDashboardAction(
                label: 'Statistiques',
                icon: Icons.insights_rounded,
                onTap: () => _go(5),
              ),
              GisDashboardAction(
                label: 'Historique',
                icon: Icons.history_rounded,
                onTap: () => _go(4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMainKpiGrid() {
    final totalProd = _i('total_produits');
    final stockPct = totalProd > 0 ? _i('stock_ok') / totalProd : 0.0;
    final objectifPct = (_d('objectif_jour_percent') / 100).clamp(0.0, 1.0);

    return GisStatCardGrid(
      cards: [
        GisGradientStatCard(
          label: 'Ventes aujourd\'hui',
          value: '${_i('ventes_jour')}',
          subtitle: '${_i('ventes_comptant_jour')} comptant · ${_i('ventes_credit_jour')} crédit',
          icon: Icons.receipt_long_rounded,
          gradient: const [Color(0xFF7C5CFF), Color(0xFF5B3FE6)],
          progress: objectifPct,
        ),
        GisGradientStatCard(
          label: 'Chiffre d\'affaires',
          value: _formatMoney(_d('ca_jour')),
          subtitle: 'Bénéfice ${_moneyLabel(_d('benefice_jour'), compact: true)}',
          icon: Icons.payments_rounded,
          gradient: const [Color(0xFF22C55E), Color(0xFF16A34A)],
        ),
        GisGradientStatCard(
          label: 'Stock sain',
          value: totalProd > 0 ? '${_i('stock_ok')}/$totalProd' : '—',
          subtitle: '${_i('stock_rupture')} rupture · ${_i('stock_faible')} faible',
          icon: Icons.inventory_2_rounded,
          gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
          progress: stockPct,
        ),
        GisGradientStatCard(
          label: 'Crédits en cours',
          value: '${_i('credits_en_cours')}',
          subtitle: 'Reste ${_moneyLabel(_d('credits_reste_total'), compact: true)}',
          icon: Icons.credit_card_rounded,
          gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
      ],
    );
  }

  Widget _buildPerformanceStrip() {
    final marge = _d('marge_mois_percent');
    final caSemaine = _d('ca_semaine');
    final ventesMois = _i('ventes_mois');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: GisChartPanel(
        title: 'Performance du mois',
        subtitle: 'Marge · activité · chiffre clé',
        child: LayoutBuilder(
          builder: (context, constraints) {
            final narrow = constraints.maxWidth < 520;
            final insights = [
              _MiniInsight(
                label: 'Marge nette',
                value: '${marge.toStringAsFixed(0)}%',
                color: _p.success,
                icon: Icons.trending_up_rounded,
              ),
              _MiniInsight(
                label: 'CA 7 jours',
                value: _moneyLabel(caSemaine, compact: true),
                color: _p.info,
                icon: Icons.calendar_view_week_rounded,
              ),
              _MiniInsight(
                label: 'Ventes mois',
                value: '$ventesMois',
                color: _p.accent,
                icon: Icons.shopping_bag_outlined,
              ),
            ];
            if (narrow) {
              return Column(
                children: [
                  for (var i = 0; i < insights.length; i++) ...[
                    insights[i],
                    if (i < insights.length - 1) const SizedBox(height: 8),
                  ],
                ],
              );
            }
            return Row(
              children: [
                for (var i = 0; i < insights.length; i++)
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: i < insights.length - 1 ? 10 : 0),
                      child: insights[i],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(DateTime.now());
    final dateLabel = dateStr.isNotEmpty ? '${dateStr[0].toUpperCase()}${dateStr.substring(1)}' : '';
    final displayName = proprietaire?.isNotEmpty == true ? proprietaire! : userName ?? 'Gérant';

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 4),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [_p.accent.withValues(alpha: 0.35), _p.accent.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _p.accent.withValues(alpha: 0.3)),
            ),
            child:  Icon(Icons.dashboard_rounded, color: _p.accentSoft, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel.isNotEmpty ? dateLabel : 'Tableau de bord',
                  style: TextStyle(color: _p.textMute, fontSize: 12, letterSpacing: 0.3, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$_greeting, $displayName',
                  style: GoogleFonts.plusJakartaSans(
                    color: _p.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    height: 1.15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  shopName ?? 'Ma boutique',
                  style: TextStyle(color: _p.textMute, fontSize: 12, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          _TipIconButton(
            icon: Icons.refresh_rounded,
            tooltip: 'Actualiser toutes les données du dashboard',
            onTap: _loadData,
          ),
        ],
      ),
    );
  }

  Widget _buildHero() {
    final caJour = _d('ca_jour');
    final objectif = _d('objectif_jour_percent');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: _p.heroDecoration(context, radius: 16),
        child: Row(
          children: [
            if (!isDark)
              Container(
                width: 4,
                height: 72,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [_p.accent, _p.accentSoft],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip('Aujourd\'hui', isDark ? _p.accentSoft : _p.accent),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                        child: Icon(Icons.calendar_today_rounded, size: 13, color: _p.textMute),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Tooltip(
                    message: 'Somme de toutes les ventes validées aujourd\'hui (hors annulations).',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chiffre d\'affaires',
                          style: TextStyle(
                            color: _p.textMute,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _countAnim,
                          builder: (context, _) {
                            final animatedCa = caJour * _countAnim.value;
                            return Text(
                              _moneyLabel(animatedCa),
                              style: GoogleFonts.plusJakartaSans(
                                color: _p.text,
                                fontSize: 32,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1.2,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_i('ventes_jour')} vente${_i('ventes_jour') > 1 ? 's' : ''} · '
                    'Bénéfice ${_moneyLabel(_d('benefice_jour'), compact: true)}',
                    style: TextStyle(color: _p.textMute, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Tooltip(
              message: 'Progression vs votre moyenne journalière du mois '
                  '(${_moneyLabel(_d('ca_moyen_jour_mois'), compact: true)} / jour).',
              child: AnimatedBuilder(
                animation: _countAnim,
                builder: (context, _) {
                  final animObjectif = objectif * _countAnim.value;
                  return SizedBox(
                    width: 72,
                    height: 72,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 6,
                            color: _p.border,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: (animObjectif / 100).clamp(0.0, 1.0),
                            strokeWidth: 6,
                            color: objectif >= 100 ? _p.success : _p.accent,
                            backgroundColor: Colors.transparent,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${animObjectif.toStringAsFixed(0)}%',
                              style: TextStyle(color: _p.text, fontSize: 14, fontWeight: FontWeight.w800),
                            ),
                            Text('Objectif', style: TextStyle(color: _p.textMute, fontSize: 10, fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCircularSection() {
    final marge = _d('marge_mois_percent');
    final tauxCredit = _i('ventes_jour') > 0
        ? (_i('ventes_credit_jour') / _i('ventes_jour') * 100)
        : 0.0;
    final totalProd = _i('total_produits');
    final santeStock = totalProd > 0 ? (_i('stock_ok') / totalProd * 100) : 100.0;
    final activite = _i('ventes_semaine') > 0 ? (_i('ventes_semaine') / 7.0 * 14).clamp(0, 100).toDouble() : 0.0;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: _Panel(
        child: Column(
          children: [
            _SectionTitle(
              title: 'Indicateurs circulaires',
              tooltip: 'Vue synthétique de la performance : marge, crédits, stock et activité.',
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: marge,
                  label: 'Marge mois',
                  value: _moneyLabel(_d('benefice_mois'), compact: true),
                  explanation: 'Bénéfice ÷ CA',
                  color: _p.success,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: tauxCredit,
                  label: 'Crédit jour',
                  value: '${_i('ventes_credit_jour')}/${_i('ventes_jour')}',
                  explanation: 'Ventes à crédit',
                  color: _p.warning,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: santeStock,
                  label: 'Stock OK',
                  value: '${_i('stock_ok')}/$totalProd',
                  explanation: 'Produits sains',
                  color: _p.info,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: activite.toDouble(),
                  label: 'Activité',
                  value: '${_i('ventes_semaine')}/sem',
                  explanation: 'Rythme ventes',
                  color: _p.accent,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDonutSection() {
    final comptant = _d('ca_comptant_jour');
    final credit = _d('ca_credit_jour');
    final stockOk = _i('stock_ok').toDouble();
    final stockAlert = (_i('stock_rupture') + _i('stock_faible')).toDouble();

    final paymentSections = <Map<String, dynamic>>[];
    if (comptant > 0) paymentSections.add({'label': 'Comptant', 'value': comptant});
    if (credit > 0) paymentSections.add({'label': 'Crédit', 'value': credit});

    final stockSections = <Map<String, dynamic>>[];
    if (stockOk > 0) stockSections.add({'label': 'En stock', 'value': stockOk});
    if (stockAlert > 0) stockSections.add({'label': 'Alerte', 'value': stockAlert});
    final totalProd = _i('total_produits');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: GisChartPanel(
        title: 'Répartitions du jour',
        subtitle: 'Total : ${_i('ventes_jour')} vente${_i('ventes_jour') > 1 ? 's' : ''} · ${_moneyLabel(_d('ca_jour'), compact: true)}',
        child: GisDashboardSplit(
          left: DonutChartWidget(
            theme: _chartTheme,
            compact: true,
            embedded: true,
            title: 'Paiements',
            subtitle: 'Comptant vs crédit',
            centerLabel: 'CA jour',
            centerValue: _formatMoney(_d('ca_jour'), compact: true),
            sections: paymentSections,
            colors: [_p.success, _p.warning],
          ),
          right: DonutChartWidget(
            theme: _chartTheme,
            compact: true,
            embedded: true,
            title: 'Stock',
            subtitle: 'OK vs alertes',
            centerLabel: 'Total',
            centerValue: '$totalProd',
            sections: stockSections,
            colors: [_p.success, _p.danger],
          ),
        ),
      ),
    );
  }

  List<_PersonalAction> _buildActionList() {
    final totalProd = _i('total_produits');
    final stockAlertPct = totalProd > 0
        ? ((_i('stock_rupture') + _i('stock_faible')) / totalProd * 100).clamp(0, 100).toDouble()
        : 0.0;
    final stockOkPct = totalProd > 0 ? (_i('stock_ok') / totalProd * 100).clamp(0, 100).toDouble() : 100.0;
    final marge = _d('marge_mois_percent');
    final activitePct = (_i('ventes_semaine') / 7.0 * 14).clamp(0, 100).toDouble();
    final creditUrgency = (_i('credits_en_cours') * 12.0).clamp(0, 100).toDouble();

    final actions = <_PersonalAction>[
      _PersonalAction(
        title: 'Nouvelle vente',
        subtitle: _i('ventes_jour') == 0
            ? 'Commencer votre journée'
            : '${_i('ventes_jour')} vente${_i('ventes_jour') > 1 ? 's' : ''} · ${_moneyLabel(_d('ca_jour'), compact: true)}',
        icon: Icons.point_of_sale_rounded,
        colors: [_p.accent, Color(0xFF5B3FD4)],
        navIndex: 1,
        featured: true,
        badge: _i('ventes_jour') == 0 ? '!' : null,
        ringPercent: _d('objectif_jour_percent'),
        ringCenter: '${_d('objectif_jour_percent').toStringAsFixed(0)}%',
        tooltip: 'Accéder à la caisse pour enregistrer une vente comptant ou crédit.',
      ),
    ];

    if (_i('credits_en_cours') > 0) {
      actions.add(_PersonalAction(
        title: 'Encaisser crédits',
        subtitle: 'Reste ${_moneyLabel(_d('credits_reste_total'), compact: true)}',
        icon: Icons.payments_rounded,
        colors: [_p.warning, Color(0xFFD97706)],
        navIndex: 3,
        badge: '${_i('credits_en_cours')}',
        ringPercent: creditUrgency,
        ringCenter: '${_i('credits_en_cours')}',
        tooltip: '${_i('credits_en_cours')} dossier(s) en attente de paiement.',
      ));
    }

    if (_i('stock_rupture') > 0 || _i('stock_faible') > 0) {
      actions.add(_PersonalAction(
        title: 'Gérer le stock',
        subtitle: _i('stock_rupture') > 0
            ? '${_i('stock_rupture')} rupture${_i('stock_rupture') > 1 ? 's' : ''}'
            : '${_i('stock_faible')} stock faible',
        icon: Icons.inventory_2_rounded,
        colors: [_p.danger, Color(0xFFDC2626)],
        navIndex: 2,
        badge: '${_i('stock_rupture') + _i('stock_faible')}',
        ringPercent: stockAlertPct,
        ringCenter: '${_i('stock_rupture') + _i('stock_faible')}',
        tooltip: 'Réapprovisionner les produits en rupture ou stock faible.',
      ));
    }

    actions.addAll([
      _PersonalAction(
        title: 'Analyses',
        subtitle: 'CA mois ${_moneyLabel(_d('ca_mois'), compact: true)}',
        icon: Icons.insights_rounded,
        colors: [_p.info, Color(0xFF2563EB)],
        navIndex: 5,
        ringPercent: marge,
        ringCenter: '${marge.toStringAsFixed(0)}%',
        tooltip: 'Graphiques, calendrier et statistiques détaillées.',
      ),
      _PersonalAction(
        title: 'Historique',
        subtitle: '${_i('ventes_mois')} ventes ce mois',
        icon: Icons.receipt_long_rounded,
        colors: [_p.textMute, _p.textDim],
        navIndex: 4,
        ringPercent: activitePct,
        ringCenter: '${_i('ventes_semaine')}',
        tooltip: 'Journal complet des ventes et annulations.',
      ),
      _PersonalAction(
        title: 'Mon profil',
        subtitle: shopName ?? 'Ma boutique',
        icon: Icons.store_rounded,
        colors: [_p.accentSoft, _p.accent],
        navIndex: 6,
        ringPercent: stockOkPct,
        ringCenter: '${_i('stock_ok')}',
        tooltip: 'Paramètres du compte et de la boutique.',
      ),
    ]);

    return actions;
  }

  Widget _buildPersonalizedActions() {
    final actions = _buildActionList();
    final featured = actions.firstWhere((a) => a.featured, orElse: () => actions.first);
    final others = actions.where((a) => !a.featured).take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            title: 'Actions pour vous',
            tooltip: 'Raccourcis adaptés à l\'état actuel de votre boutique (crédits, stock, ventes…).',
          ),
          const SizedBox(height: 10),
          _FeaturedActionCard(action: featured, onTap: () => _go(featured.navIndex)),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 6,
              mainAxisSpacing: 6,
              childAspectRatio: 2.55,
            ),
            itemCount: others.length,
            itemBuilder: (_, i) => _ActionCard(action: others[i], onTap: () => _go(others[i].navIndex)),
          ),
        ],
      ),
    );
  }

  Widget _buildKpiStrip() {
    final kpis = [
      ('Panier moy.', _moneyLabel(_d('panier_moyen_jour'), compact: true), _p.gold,
          'Montant moyen par transaction aujourd\'hui.'),
      ('7 jours', _moneyLabel(_d('ca_semaine'), compact: true), _p.info,
          '${_i('ventes_semaine')} ventes sur la semaine glissante.'),
      ('Ce mois', _moneyLabel(_d('ca_mois'), compact: true), _p.accentSoft,
          'Marge ${ _d('marge_mois_percent').toStringAsFixed(0)}% · ${_i('ventes_mois')} ventes.'),
      ('Catalogue', '${_i('total_produits')}', _p.accent,
          '${_i('stock_ok')} produits en stock sain.'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: _SectionTitle(title: 'En un coup d\'œil', tooltip: 'Indicateurs complémentaires du dashboard.'),
        ),
        SizedBox(
          height: 58,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: kpis.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final k = kpis[i];
              return _KpiChip(label: k.$1, value: k.$2, color: k.$3, tooltip: k.$4);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlerts() {
    final creditsCount = _i('credits_en_cours');
    final creditsReste = _d('credits_reste_total');
    final rupture = _i('stock_rupture');
    final faible = _i('stock_faible');
    final alertes = List<Map<String, dynamic>>.from(_data['produits_alerte'] ?? []);

    if (creditsCount == 0 && rupture == 0 && faible == 0) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
        child: Tooltip(
          message: 'Stock et crédits sous contrôle.',
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _p.success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _p.success.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: _p.success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Boutique opérationnelle — aucune alerte',
                    style: TextStyle(color: _p.success.withValues(alpha: 0.9), fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(title: 'Priorités', tooltip: 'Actions urgentes recommandées.'),
          const SizedBox(height: 6),
          if (creditsCount > 0)
            _CompactAlert(
              icon: Icons.credit_score_rounded,
              color: _p.warning,
              text: '$creditsCount crédit${creditsCount > 1 ? 's' : ''} · ${_moneyLabel(creditsReste, compact: true)} à encaisser',
              tooltip: 'Relancer ou encaisser les paiements clients.',
              onTap: () => _go(3),
            ),
          if (rupture > 0) ...[
            if (creditsCount > 0) const SizedBox(height: 6),
            _CompactAlert(
              icon: Icons.error_outline_rounded,
              color: _p.danger,
              text: '$rupture rupture${rupture > 1 ? 's' : ''} — réapprovisionner',
              tooltip: alertes.isNotEmpty ? 'Ex: ${alertes.first['nom']}' : 'Voir le catalogue',
              onTap: () => _go(2),
            ),
          ],
          if (faible > 0 && rupture == 0) ...[
            if (creditsCount > 0) const SizedBox(height: 6),
            _CompactAlert(
              icon: Icons.warning_amber_rounded,
              color: _p.warning,
              text: '$faible produit${faible > 1 ? 's' : ''} stock faible',
              tooltip: 'Commander avant rupture.',
              onTap: () => _go(2),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecentSales() {
    final ventes = List<Map<String, dynamic>>.from(_data['ventes_recentes'] ?? []);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: GisChartPanel(
        title: 'Dernières ventes',
        subtitle: 'Transactions récentes avec type de paiement',
        trailing: GestureDetector(
          onTap: () => _go(4),
          child: Text('Voir tout →', style: TextStyle(color: _p.accent, fontSize: 12, fontWeight: FontWeight.w700)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ventes.isEmpty)
              Text(
                'Aucune vente — lancez une vente depuis la caisse.',
                style: TextStyle(color: _p.textMute, fontSize: 13),
              )
            else
              ...ventes.take(5).map((v) {
                final nom = v['nom_produit']?.toString() ?? 'Vente';
                final total = (v['total'] as num?)?.toDouble() ?? 0;
                final credit = v['est_credit'] == true;
                final parsed = DateTime.tryParse(v['date_vente']?.toString() ?? '');
                final timeLabel = parsed != null ? DateFormat('dd/MM · HH:mm', 'fr_FR').format(parsed.toLocal()) : '';

                return Tooltip(
                  message: credit ? 'Vente à crédit' : 'Paiement comptant',
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: (credit ? _p.warning : _p.success).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            credit ? Icons.credit_card_rounded : Icons.payments_rounded,
                            size: 13,
                            color: credit ? _p.warning : _p.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nom, style:  TextStyle(color: _p.text, fontSize: 11, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (timeLabel.isNotEmpty)
                                Text(timeLabel, style:  TextStyle(color: _p.textDim, fontSize: 9)),
                            ],
                          ),
                        ),
                        Text(_moneyLabel(total, compact: true),
                            style:  TextStyle(color: _p.accentSoft, fontSize: 11, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
    );
  }
}

class _EdukaSummaryCardData {
  final String label;
  final String value;
  final String? footerLabel;
  final double footerProgress;
  final IconData icon;
  final List<Color> gradient;
  final double? animateValue;

  const _EdukaSummaryCardData({
    required this.label,
    required this.value,
    required this.icon,
    required this.gradient,
    this.footerLabel,
    this.footerProgress = 0,
    this.animateValue,
  });
}

class _PersonalAction {
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> colors;
  final int navIndex;
  final String tooltip;
  final bool featured;
  final String? badge;
  final double ringPercent;
  final String ringCenter;

  const _PersonalAction({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.colors,
    required this.navIndex,
    required this.tooltip,
    this.featured = false,
    this.badge,
    this.ringPercent = 0,
    this.ringCenter = '',
  });
}

class _MiniInsight extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _MiniInsight({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(height: 8),
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
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: p.textMute, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: p.cardDecoration(context, radius: 14),
      child: child,
    );
  }
}

class _FeaturedActionCard extends StatelessWidget {
  final _PersonalAction action;
  final VoidCallback onTap;

  const _FeaturedActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: action.colors,
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: action.colors.first.withValues(alpha: 0.45),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(action.icon, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(action.title,
                            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        Text(action.subtitle,
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 11)),
                      ],
                    ),
                  ),
                  if (action.badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(action.badge!,
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                    ),
                  const SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, color: Colors.white.withValues(alpha: 0.8), size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final _PersonalAction action;
  final VoidCallback onTap;

  const _ActionCard({required this.action, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: GisPalette.of(context).surface,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: action.colors.first.withValues(alpha: 0.3)),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                action.colors.first.withValues(alpha: 0.12),
                GisPalette.of(context).surface,
              ],
            ),
          ),
          child: Row(
            children: [
              _MiniActionRing(
                percent: action.ringPercent,
                center: action.ringCenter,
                color: action.colors.first,
                size: 34,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      action.title,
                      style: TextStyle(color: GisPalette.of(context).text, fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      action.subtitle,
                      style: TextStyle(color: GisPalette.of(context).textMute, fontSize: 8),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (action.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: action.colors.first.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    action.badge!,
                    style: TextStyle(color: action.colors.first, fontSize: 8, fontWeight: FontWeight.w800),
                  ),
                )
              else
                Icon(Icons.chevron_right_rounded, size: 14, color: action.colors.first.withValues(alpha: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniActionRing extends StatelessWidget {
  final double percent;
  final String center;
  final Color color;
  final double size;

  const _MiniActionRing({
    required this.percent,
    required this.center,
    required this.color,
    this.size = 50,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 100.0) / 100;
    final stroke = size <= 36 ? 3.0 : 4.0;
    final fontSize = size <= 36 ? 9.0 : 11.0;

    return SizedBox(
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
              strokeWidth: stroke,
              color: GisPalette.of(context).border,
              backgroundColor: Colors.transparent,
            ),
          ),
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              value: clamped,
              strokeWidth: stroke,
              color: color,
              backgroundColor: Colors.transparent,
              strokeCap: StrokeCap.round,
            ),
          ),
          Text(
            center,
            style: TextStyle(color: GisPalette.of(context).text, fontSize: fontSize, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatefulWidget {
  const _DashboardSkeleton();

  @override
  State<_DashboardSkeleton> createState() => _DashboardSkeletonState();
}

class _DashboardSkeletonState extends State<_DashboardSkeleton> with SingleTickerProviderStateMixin {
  late AnimationController _shimmer;

  @override
  void initState() {
    super.initState();
    _shimmer = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmer,
      builder: (context, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(width: 220, height: 26, t: _shimmer.value, radius: 8),
              const SizedBox(height: 8),
              _shimmerBox(width: 160, height: 14, t: _shimmer.value, radius: 6),
              const SizedBox(height: 20),
              SizedBox(
                height: 158,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 4,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => _shimmerBox(width: 200, height: 158, t: _shimmer.value, radius: 20),
                ),
              ),
              const SizedBox(height: 16),
              _shimmerBox(width: double.infinity, height: 320, t: _shimmer.value, radius: 20),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 240, t: _shimmer.value, radius: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    double? width,
    required double height,
    required double t,
    double radius = 8,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment(-1 + t * 2, 0),
          end: Alignment(0 + t * 2, 0),
          colors: [
            GisPalette.of(context).surfaceHi,
            GisPalette.of(context).border,
            GisPalette.of(context).surfaceHi,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String tooltip;
  final bool dense;

  const _SectionTitle({required this.title, required this.tooltip, this.dense = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title,
            style: TextStyle(
                color: GisPalette.of(context).text,
                fontSize: dense ? 13 : 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip,
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline_rounded, size: dense ? 14 : 15, color: GisPalette.of(context).textMute),
        ),
      ],
    );
  }
}

class _TipIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _TipIconButton({required this.icon, required this.tooltip, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: GisPalette.of(context).surfaceHi,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: GisPalette.of(context).border),
            ),
            child: Icon(icon, color: GisPalette.of(context).textMute, size: 18),
          ),
        ),
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final String tooltip;

  const _KpiChip({required this.label, required this.value, required this.color, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: GisPalette.of(context).surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
            Text(value,
                style: TextStyle(color: GisPalette.of(context).text, fontSize: 13, fontWeight: FontWeight.w800),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CompactAlert extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final String tooltip;
  final VoidCallback onTap;

  const _CompactAlert({
    required this.icon,
    required this.color,
    required this.text,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: GisPalette.of(context).surface,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              color: color.withValues(alpha: 0.06),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text(text, style: TextStyle(color: GisPalette.of(context).text, fontSize: 11))),
                Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
