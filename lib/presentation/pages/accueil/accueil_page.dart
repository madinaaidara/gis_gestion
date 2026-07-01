import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/accueil_repository.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../widgets/custom_charts.dart';

class AccueilPage extends StatefulWidget {
  final void Function(int index)? onNavigate;

  const AccueilPage({super.key, this.onNavigate});

  @override
  State<AccueilPage> createState() => _AccueilPageState();
}

class _AccueilPageState extends State<AccueilPage> with TickerProviderStateMixin {
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _textDim = Color(0xFF5C5C63);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _accentSoft = Color(0xFFB8A4FF);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFFF4D6D);
  static const Color _warning = Color(0xFFF59E0B);
  static const Color _info = Color(0xFF3B82F6);
  static const Color _gold = Color(0xFFFBBF24);

  final _repo = AccueilRepository();

  String? shopId;
  String? shopName;
  String? proprietaire;
  String? devise;
  String? userName;
  bool _loading = true;
  bool _entrancePlayed = false;
  Map<String, dynamic> _data = {};

  late AnimationController _entranceController;
  late AnimationController _ambientController;
  late AnimationController _countController;
  late Animation<double> _entranceAnim;
  late Animation<double> _ambientAnim;
  late Animation<double> _countAnim;

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
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
    _countController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _entranceAnim = CurvedAnimation(parent: _entranceController, curve: Curves.easeOutCubic);
    _ambientAnim = CurvedAnimation(parent: _ambientController, curve: Curves.easeInOut);
    _countAnim = CurvedAnimation(parent: _countController, curve: Curves.easeOutExpo);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _ambientController.dispose();
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
    return TooltipTheme(
      data: TooltipThemeData(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1E),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        textStyle: const TextStyle(color: _text, fontSize: 11, height: 1.35),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        waitDuration: const Duration(milliseconds: 300),
      ),
      child: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
        child: Scaffold(
          backgroundColor: _bg,
          body: Stack(
            children: [
              _AmbientBackground(anim: _ambientAnim),
              SafeArea(
                child: _loading
                    ? const _DashboardSkeleton()
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: _accent,
                        backgroundColor: _surface,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                          slivers: [
                            SliverToBoxAdapter(child: _stagger(0, _buildHeader())),
                            SliverToBoxAdapter(child: _stagger(1, _buildHero())),
                            SliverToBoxAdapter(child: _stagger(2, _buildCircularSection())),
                            SliverToBoxAdapter(child: _stagger(3, _buildDonutSection())),
                            SliverToBoxAdapter(child: _stagger(4, _buildPersonalizedActions())),
                            SliverToBoxAdapter(child: _stagger(5, _buildKpiStrip())),
                            SliverToBoxAdapter(child: _stagger(6, _buildAlerts())),
                            SliverToBoxAdapter(child: _stagger(7, _buildRecentSales())),
                            const SliverToBoxAdapter(child: SizedBox(height: 20)),
                          ],
                        ),
                      ),
              ),
            ],
          ),
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
              gradient: LinearGradient(colors: [_accent.withValues(alpha: 0.35), _accent.withValues(alpha: 0.08)]),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: 0.3)),
            ),
            child: const Icon(Icons.dashboard_rounded, color: _accentSoft, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateLabel.isNotEmpty ? dateLabel : 'Tableau de bord',
                  style: TextStyle(color: _textDim, fontSize: 10, letterSpacing: 0.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  '$_greeting, $displayName',
                  style: GoogleFonts.plusJakartaSans(
                    color: _text,
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
                  style: const TextStyle(color: _accentSoft, fontSize: 11),
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              _accent.withValues(alpha: 0.22),
              const Color(0xFF1A1240).withValues(alpha: 0.9),
              _surfaceHi,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _accent.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _chip('Aujourd\'hui', _accentSoft),
                      const SizedBox(width: 6),
                      Tooltip(
                        message: DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(DateTime.now()),
                        child: Icon(Icons.calendar_today_rounded, size: 12, color: _textDim),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Tooltip(
                    message: 'Somme de toutes les ventes validées aujourd\'hui (hors annulations).',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Chiffre d\'affaires', style: TextStyle(color: _textMute, fontSize: 11)),
                        AnimatedBuilder(
                          animation: _countAnim,
                          builder: (context, _) {
                            final animatedCa = caJour * _countAnim.value;
                            return Text(
                              _moneyLabel(animatedCa),
                              style: GoogleFonts.plusJakartaSans(
                                color: _text,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
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
                    style: const TextStyle(color: _textDim, fontSize: 10),
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
                            color: _border,
                            backgroundColor: Colors.transparent,
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          height: 72,
                          child: CircularProgressIndicator(
                            value: (animObjectif / 100).clamp(0.0, 1.0),
                            strokeWidth: 6,
                            color: objectif >= 100 ? _success : _accent,
                            backgroundColor: Colors.transparent,
                            strokeCap: StrokeCap.round,
                          ),
                        ),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${animObjectif.toStringAsFixed(0)}%',
                              style: const TextStyle(color: _text, fontSize: 13, fontWeight: FontWeight.w800),
                            ),
                            const Text('Objectif', style: TextStyle(color: _textDim, fontSize: 8)),
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
                  color: _success,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: tauxCredit,
                  label: 'Crédit jour',
                  value: '${_i('ventes_credit_jour')}/${_i('ventes_jour')}',
                  explanation: 'Ventes à crédit',
                  color: _warning,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: santeStock,
                  label: 'Stock OK',
                  value: '${_i('stock_ok')}/$totalProd',
                  explanation: 'Produits sains',
                  color: _info,
                ),
                RingMetricWidget(
                  theme: _chartTheme,
                  size: 76,
                  percent: activite.toDouble(),
                  label: 'Activité',
                  value: '${_i('ventes_semaine')}/sem',
                  explanation: 'Rythme ventes',
                  color: _accent,
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

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionTitle(
              title: 'Répartitions du jour',
              tooltip: 'Diagrammes circulaires : encaissements et état du stock en temps réel.',
            ),
            const SizedBox(height: 12),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: DonutChartWidget(
                      theme: _chartTheme,
                      compact: true,
                      embedded: true,
                      title: 'Paiements',
                      subtitle: 'Comptant vs crédit',
                      centerLabel: 'CA jour',
                      centerValue: _formatMoney(_d('ca_jour'), compact: true),
                      sections: paymentSections,
                      colors: const [_success, _warning],
                    ),
                  ),
                  Container(width: 1, margin: const EdgeInsets.symmetric(horizontal: 10), color: _border),
                  Expanded(
                    child: DonutChartWidget(
                      theme: _chartTheme,
                      compact: true,
                      embedded: true,
                      title: 'Stock',
                      subtitle: 'OK vs alertes',
                      centerLabel: 'Total',
                      centerValue: '${_i('total_produits')}',
                      sections: stockSections,
                      colors: const [_success, _danger],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
        colors: [_accent, const Color(0xFF5B3FD4)],
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
        colors: [_warning, const Color(0xFFD97706)],
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
        colors: [_danger, const Color(0xFFDC2626)],
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
        colors: [_info, const Color(0xFF2563EB)],
        navIndex: 5,
        ringPercent: marge,
        ringCenter: '${marge.toStringAsFixed(0)}%',
        tooltip: 'Graphiques, calendrier et statistiques détaillées.',
      ),
      _PersonalAction(
        title: 'Historique',
        subtitle: '${_i('ventes_mois')} ventes ce mois',
        icon: Icons.receipt_long_rounded,
        colors: [_textMute, _textDim],
        navIndex: 4,
        ringPercent: activitePct,
        ringCenter: '${_i('ventes_semaine')}',
        tooltip: 'Journal complet des ventes et annulations.',
      ),
      _PersonalAction(
        title: 'Mon profil',
        subtitle: shopName ?? 'Ma boutique',
        icon: Icons.store_rounded,
        colors: [_accentSoft, _accent],
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
      ('Panier moy.', _moneyLabel(_d('panier_moyen_jour'), compact: true), _gold,
          'Montant moyen par transaction aujourd\'hui.'),
      ('7 jours', _moneyLabel(_d('ca_semaine'), compact: true), _info,
          '${_i('ventes_semaine')} ventes sur la semaine glissante.'),
      ('Ce mois', _moneyLabel(_d('ca_mois'), compact: true), _accentSoft,
          'Marge ${ _d('marge_mois_percent').toStringAsFixed(0)}% · ${_i('ventes_mois')} ventes.'),
      ('Catalogue', '${_i('total_produits')}', _accent,
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
              color: _success.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _success.withValues(alpha: 0.18)),
            ),
            child: Row(
              children: [
                Icon(Icons.verified_rounded, color: _success, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Boutique opérationnelle — aucune alerte',
                    style: TextStyle(color: _success.withValues(alpha: 0.9), fontSize: 11),
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
              color: _warning,
              text: '$creditsCount crédit${creditsCount > 1 ? 's' : ''} · ${_moneyLabel(creditsReste, compact: true)} à encaisser',
              tooltip: 'Relancer ou encaisser les paiements clients.',
              onTap: () => _go(3),
            ),
          if (rupture > 0) ...[
            if (creditsCount > 0) const SizedBox(height: 6),
            _CompactAlert(
              icon: Icons.error_outline_rounded,
              color: _danger,
              text: '$rupture rupture${rupture > 1 ? 's' : ''} — réapprovisionner',
              tooltip: alertes.isNotEmpty ? 'Ex: ${alertes.first['nom']}' : 'Voir le catalogue',
              onTap: () => _go(2),
            ),
          ],
          if (faible > 0 && rupture == 0) ...[
            if (creditsCount > 0) const SizedBox(height: 6),
            _CompactAlert(
              icon: Icons.warning_amber_rounded,
              color: _warning,
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
      child: _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _SectionTitle(
                    title: 'Dernières ventes',
                    tooltip: 'Transactions récentes avec type de paiement.',
                    dense: true,
                  ),
                ),
                GestureDetector(
                  onTap: () => _go(4),
                  child: Tooltip(
                    message: 'Historique complet',
                    child: Text('Voir tout →', style: TextStyle(color: _accentSoft, fontSize: 10, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ventes.isEmpty)
              Text('Aucune vente — touchez « Nouvelle vente » ci-dessus.', style: TextStyle(color: _textDim, fontSize: 11))
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
                            color: (credit ? _warning : _success).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            credit ? Icons.credit_card_rounded : Icons.payments_rounded,
                            size: 13,
                            color: credit ? _warning : _success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(nom, style: const TextStyle(color: _text, fontSize: 11, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (timeLabel.isNotEmpty)
                                Text(timeLabel, style: const TextStyle(color: _textDim, fontSize: 9)),
                            ],
                          ),
                        ),
                        Text(_moneyLabel(total, compact: true),
                            style: const TextStyle(color: _accentSoft, fontSize: 11, fontWeight: FontWeight.w700)),
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
      child: Text(text, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
    );
  }
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

class _Panel extends StatelessWidget {
  final Widget child;

  const _Panel({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0E0E10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222226)),
      ),
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
                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
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
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
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
      color: const Color(0xFF0E0E10),
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
                const Color(0xFF0E0E10),
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
                      style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 11, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      action.subtitle,
                      style: const TextStyle(color: Color(0xFF8A8A92), fontSize: 8),
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
              color: const Color(0xFF222226),
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
            style: TextStyle(color: const Color(0xFFF5F5F7), fontSize: fontSize, fontWeight: FontWeight.w800),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  final Animation<double> anim;

  const _AmbientBackground({required this.anim});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: anim,
      builder: (context, _) {
        final pulse = 0.65 + anim.value * 0.35;
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
                      colors: [
                        const Color(0xFF7C5CFF).withValues(alpha: 0.22),
                        const Color(0xFF7C5CFF).withValues(alpha: 0),
                      ],
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
                      colors: [
                        const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        const Color(0xFF3B82F6).withValues(alpha: 0),
                      ],
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
                      colors: [
                        const Color(0xFF22C55E).withValues(alpha: 0.08),
                        const Color(0xFF22C55E).withValues(alpha: 0),
                      ],
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _shimmerBox(width: 180, height: 22, t: _shimmer.value),
              const SizedBox(height: 6),
              _shimmerBox(width: 240, height: 28, t: _shimmer.value),
              const SizedBox(height: 16),
              _shimmerBox(width: double.infinity, height: 120, t: _shimmer.value, radius: 16),
              const SizedBox(height: 12),
              _shimmerBox(width: double.infinity, height: 140, t: _shimmer.value, radius: 14),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _shimmerBox(height: 56, t: _shimmer.value, radius: 10)),
                  const SizedBox(width: 8),
                  Expanded(child: _shimmerBox(height: 56, t: _shimmer.value, radius: 10)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _shimmerBox(height: 56, t: _shimmer.value, radius: 10)),
                  const SizedBox(width: 8),
                  Expanded(child: _shimmerBox(height: 56, t: _shimmer.value, radius: 10)),
                ],
              ),
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
          colors: const [
            Color(0xFF161618),
            Color(0xFF222226),
            Color(0xFF161618),
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
                color: const Color(0xFFF5F5F7), fontSize: dense ? 12 : 13, fontWeight: FontWeight.w700)),
        const SizedBox(width: 4),
        Tooltip(
          message: tooltip,
          triggerMode: TooltipTriggerMode.tap,
          child: Icon(Icons.info_outline_rounded, size: dense ? 13 : 14, color: const Color(0xFF5C5C63)),
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
        color: const Color(0xFF161618),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF222226)),
            ),
            child: Icon(icon, color: const Color(0xFF8A8A92), size: 18),
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
          color: const Color(0xFF0E0E10),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 12, fontWeight: FontWeight.w800),
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
        color: const Color(0xFF0E0E10),
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
                Expanded(child: Text(text, style: const TextStyle(color: Color(0xFFF5F5F7), fontSize: 11))),
                Icon(Icons.chevron_right_rounded, color: color.withValues(alpha: 0.6), size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
