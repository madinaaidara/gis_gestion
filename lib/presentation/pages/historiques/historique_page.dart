// lib/presentation/pages/historiques/historique_page.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_surface.dart';
import '../../../core/theme/gis_palette.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/repositories/shops_repository.dart';
import '../../../data/repositories/ventes_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../viewmodels/credits_viewmodel.dart';
import '../../widgets/gis_ui_kit.dart';

class HistoriquePage extends StatefulWidget {
  const HistoriquePage({super.key});

  @override
  State<HistoriquePage> createState() => _HistoriquePageState();
}

class _HistoriquePageState extends State<HistoriquePage> with SingleTickerProviderStateMixin {
  GisPalette get _p => GisPalette.of(context);

  // ===== PALETTE DARK PREMIUM =====

  final searchController = TextEditingController();
  String _searchQuery = '';

  String? shopId;
  String? devise;
  
  List<Map<String, dynamic>> _ventes = [];
  List<Map<String, dynamic>> _credits = [];
  bool _isLoading = true;
  String _selectedType = 'all'; // all, ventes, credits
  String _selectedPeriod = 'all'; // all, today, week, month
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted || !_tabController.indexIsChanging) return;
      setState(() {
        if (_tabController.index == 0) _selectedType = 'all';
        else if (_tabController.index == 1) _selectedType = 'ventes';
        else if (_tabController.index == 2) _selectedType = 'credits';
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      if (!mounted) return;
      final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopRepo.checkAndLoadShop(userId);
      if (!mounted) return;

      if (shopRepo.currentShop != null) {
        shopId = shopRepo.currentShop!.id;
        devise = shopRepo.currentShop?.devise ?? 'FCFA';

        await Future.wait([
          _loadVentes(),
          _loadCredits(),
        ]);
      }

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Erreur chargement historique: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadVentes() async {
    if (shopId == null) return;
    
    try {
      final response = await Supabase.instance.client
          .from('ventes')
          .select('*')
          .eq('shop_id', shopId!)
          .order('created_at', ascending: false);
          
      _ventes = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur loadVentes: $e');
      _ventes = [];
    }
  }

  Future<void> _loadCredits() async {
    if (shopId == null) return;
    
    try {
      final response = await Supabase.instance.client
          .from('credits')
          .select('*')
          .eq('shop_id', shopId!)
          .order('date_credit', ascending: false);
          
      _credits = List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur loadCredits: $e');
      _credits = [];
    }
  }

  // ✅ CORRECTION : Fonction de filtrage par période
  bool _isDateInPeriod(DateTime date, String period) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    switch (period) {
      case 'today':
        return dateOnly == today;
        
      case 'week':
        // Début de la semaine (lundi)
        final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
        return dateOnly.isAfter(startOfWeek.subtract(const Duration(days: 1))) && 
               dateOnly.isBefore(startOfWeek.add(const Duration(days: 7)));
        
      case 'month':
        return dateOnly.year == now.year && dateOnly.month == now.month;
        
      default:
        return true;
    }
  }

  bool _isVenteAnnulee(Map<String, dynamic> v) => (v['status']?.toString() ?? '') == 'annulee';

  bool _peutAnnulerVente(Map<String, dynamic> v) {
    if (v['_type'] != 'vente') return false;
    if (_isVenteAnnulee(v)) return false;
    if (_isVenteCredit(v)) return false;
    return true;
  }

  bool _isCreditAnnule(Map<String, dynamic> c) => (c['statut']?.toString() ?? '') == 'annule';

  bool _peutAnnulerCredit(Map<String, dynamic> c) {
    if (c['_type'] != 'credit') return false;
    return (c['statut']?.toString() ?? '') == 'en_cours';
  }

  Future<void> _confirmerAnnulationCredit(Map<String, dynamic> credit) async {
    final id = credit['id']?.toString();
    if (id == null) return;

    final acompte = (credit['montant_paye'] ?? 0).toDouble();
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _p.border)),
        title:  Text('Annuler ce dossier crédit ?', style: TextStyle(color: _p.text, fontSize: 16)),
        content: Text(
          'Le dossier et la vente liée seront marqués « Annulés ».\n'
          'Le stock sera remis en rayon.${acompte > 0 ? '\n\nAcompte reçu : à rembourser au client manuellement.' : ''}',
          style: TextStyle(color: _p.textMute, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non', style: TextStyle(color: _p.textMute))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Oui, annuler', style: TextStyle(color: _p.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    final creditsVm = Provider.of<CreditsViewModel>(context, listen: false);
    final productsRepo = Provider.of<ProductsRepository>(context, listen: false);
    final ventesRepo = Provider.of<VentesRepository>(context, listen: false);
    final result = await creditsVm.annulerCredit(
      id,
      productsRepository: productsRepo,
      ventesRepository: ventesRepo,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      _showSnackBar(result.message ?? 'Dossier annulé', true);
      await _loadData();
      await Provider.of<ProductsViewModel>(context, listen: false).refreshProducts();
    } else {
      _showSnackBar(result.message ?? 'Annulation impossible', false);
    }
  }

  Future<void> _confirmerAnnulation(Map<String, dynamic> vente) async {
    final id = vente['id']?.toString();
    if (id == null) return;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _p.border)),
        title:  Text('Annuler cette vente ?', style: TextStyle(color: _p.text, fontSize: 16)),
        content: Text(
          'La vente restera visible avec le statut « Annulée ».\n'
          'Le stock sera remis en rayon (ventes récentes uniquement).',
          style: TextStyle(color: _p.textMute, fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Non', style: TextStyle(color: _p.textMute))),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Oui, annuler', style: TextStyle(color: _p.danger, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirme != true || !mounted) return;

    final ventesRepo = Provider.of<VentesRepository>(context, listen: false);
    final productsRepo = Provider.of<ProductsRepository>(context, listen: false);
    final result = await ventesRepo.annulerVente(
      id,
      productsRepository: productsRepo,
      shopId: shopId,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      _showSnackBar(result.message ?? 'Vente annulée', true);
      await _loadData();
      if (shopId != null) {
        await Provider.of<ProductsViewModel>(context, listen: false).reloadForShop(shopId!);
      }
    } else {
      _showSnackBar(result.message ?? 'Annulation impossible', false);
    }
  }

  void _showSnackBar(String message, bool success) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success ? _p.success : _p.danger,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  bool _isVenteCredit(Map<String, dynamic> v) {
    if (v['est_credit'] == true) return true;
    final status = v['status']?.toString() ?? '';
    final methode = v['methode_paiement']?.toString() ?? '';
    return status == 'en_cours' || methode == 'Crédit';
  }

  String _venteStatutLabel(Map<String, dynamic> v) {
    if (_isVenteAnnulee(v)) return 'Annulée';
    if (_isVenteCredit(v)) {
      final reste = (v['reste_a_payer'] ?? v['reste'] ?? 0).toDouble();
      return reste <= 0.0001 ? 'Crédit soldé' : 'Crédit en cours';
    }
    return 'Payé';
  }

  Color _venteStatutColor(Map<String, dynamic> v) {
    if (_isVenteAnnulee(v)) return _p.textDim;
    if (!_isVenteCredit(v)) return _p.success;
    final reste = (v['reste_a_payer'] ?? v['reste'] ?? 0).toDouble();
    return reste <= 0.0001 ? _p.success : _p.warning;
  }

  List<Map<String, dynamic>> get _filteredItems {
    List<Map<String, dynamic>> items = [];

    if (_selectedType == 'all') {
      items = [
        ..._ventes.map((v) => {...v, '_type': 'vente'}),
        ..._credits.map((c) => {...c, '_type': 'credit'}),
      ];
      items.sort((a, b) {
        final dateA = a['created_at'] ?? a['date_credit'] ?? '';
        final dateB = b['created_at'] ?? b['date_credit'] ?? '';
        return dateB.compareTo(dateA);
      });
    } else if (_selectedType == 'ventes') {
      items = _ventes.map((v) => {...v, '_type': 'vente'}).toList();
    } else {
      items = _credits.map((c) => {...c, '_type': 'credit'}).toList();
    }

    if (_selectedPeriod != 'all') {
      items = items.where((item) {
        final dateStr = item['created_at'] ?? item['date_credit'];
        if (dateStr == null) return false;
        final date = DateTime.tryParse(dateStr);
        if (date == null) return false;
        return _isDateInPeriod(date, _selectedPeriod);
      }).toList();
    }

    final q = _searchQuery.trim().toLowerCase();
    if (q.isNotEmpty) {
      items = items.where((item) {
        final client = (item['client_nom'] ?? '').toString().toLowerCase();
        final tel = (item['telephone_client'] ?? '').toString().toLowerCase();
        final produits = (item['nom_produit'] ?? '').toString().toLowerCase();
        return client.contains(q) || tel.contains(q) || produits.contains(q);
      }).toList();
    }

    return items;
  }

  // ✅ CORRECTION : Statistiques filtrées par période
  double get _totalVentes {
    double sum = 0;
    for (var v in _ventes) {
      if (_isVenteAnnulee(v)) continue;
      final dateStr = v['created_at'];
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && (_selectedPeriod == 'all' || _isDateInPeriod(date, _selectedPeriod))) {
          sum += (v['montant_total'] ?? 0).toDouble();
        }
      }
    }
    return sum;
  }

  double get _totalBenefice {
    double sum = 0;
    for (var v in _ventes) {
      if (_isVenteAnnulee(v)) continue;
      final dateStr = v['created_at'];
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && (_selectedPeriod == 'all' || _isDateInPeriod(date, _selectedPeriod))) {
          sum += (v['benefice_reel'] ?? 0).toDouble();
        }
      }
    }
    return sum;
  }

  int get _nbVentes {
    int count = 0;
    for (var v in _ventes) {
      if (_isVenteAnnulee(v)) continue;
      final dateStr = v['created_at'];
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && (_selectedPeriod == 'all' || _isDateInPeriod(date, _selectedPeriod))) {
          count++;
        }
      }
    }
    return count;
  }

  int get _nbCredits {
    int count = 0;
    for (var c in _credits) {
      if (_isCreditAnnule(c)) continue;
      final dateStr = c['date_credit'];
      if (dateStr != null) {
        final date = DateTime.tryParse(dateStr);
        if (date != null && (_selectedPeriod == 'all' || _isDateInPeriod(date, _selectedPeriod))) {
          count++;
        }
      }
    }
    return count;
  }

  String _formatNumber(double value) {
    return NumberFormat.decimalPattern('fr_FR').format(value);
  }

  String _formatDate(String? date) {
    if (date == null) return 'Date inconnue';
    try {
      final parsed = DateTime.parse(date);
      return DateFormat('dd/MM/yyyy à HH:mm').format(parsed);
    } catch (e) {
      return date;
    }
  }

  void _afficherDetails(Map<String, dynamic> item) {
    final isVente = item['_type'] == 'vente';
    final isCreditVente = isVente && _isVenteCredit(item);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _p.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _p.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: _p.borderStrong, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isVente
                        ? (isCreditVente ? _p.warning.withOpacity(0.1) : _p.success.withOpacity(0.1))
                        : _p.warning.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    isVente ? Icons.receipt_long_rounded : Icons.credit_card_rounded,
                    color: isVente ? (isCreditVente ? _p.warning : _p.success) : _p.warning,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isVente ? 'Vente' : 'Dossier crédit',
                        style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _p.text),
                      ),
                      Text(
                        _formatDate(isVente ? item['created_at'] : item['date_credit']),
                        style: TextStyle(fontSize: 12, color: _p.textMute),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isVente ? _venteStatutColor(item) : (item['statut'] == 'paye' ? _p.success : _p.warning)).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isVente ? _venteStatutLabel(item) : (item['statut'] == 'paye' ? 'Soldé' : 'En cours'),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isVente ? _venteStatutColor(item) : (item['statut'] == 'paye' ? _p.success : _p.warning),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: _p.border),
            const SizedBox(height: 16),
            if (isVente) ...[
              _buildDetailRow('Client', item['client_nom'] ?? 'Client comptant', Icons.person_outline),
              const SizedBox(height: 12),
              _buildDetailRow('Produits', item['nom_produit'] ?? '-', Icons.inventory_2),
              const SizedBox(height: 12),
              _buildDetailRow('Quantité', '${item['quantite']?.toString() ?? '-'}', Icons.production_quantity_limits),
              const SizedBox(height: 12),
              _buildDetailRow('Montant', '${_formatNumber(item['montant_total']?.toDouble() ?? 0)} $devise', Icons.receipt_long_rounded, color: _p.success),
              const SizedBox(height: 12),
              _buildDetailRow('Bénéfice', '${_formatNumber(item['benefice_reel']?.toDouble() ?? 0)} $devise', Icons.trending_up, color: _p.gold),
              const SizedBox(height: 12),
              _buildDetailRow('Paiement', item['methode_paiement'] ?? '-', Icons.payment_rounded),
              if (isCreditVente) ...[
                const SizedBox(height: 12),
                _buildDetailRow('Déjà payé', '${_formatNumber(item['montant_paye']?.toDouble() ?? 0)} $devise', Icons.payments, color: _p.success),
                const SizedBox(height: 12),
                _buildDetailRow('Reste', '${_formatNumber(item['reste_a_payer']?.toDouble() ?? item['reste']?.toDouble() ?? 0)} $devise', Icons.account_balance_wallet, color: _p.gold),
              ],
            ] else ...[
              _buildDetailRow('Client', item['client_nom'] ?? '-', Icons.person_outline),
              const SizedBox(height: 12),
              _buildDetailRow('Téléphone', item['telephone_client'] ?? '-', Icons.phone),
              const SizedBox(height: 12),
              _buildDetailRow('Montant total', '${_formatNumber(item['montant_total']?.toDouble() ?? 0)} $devise', Icons.receipt_long_rounded),
              const SizedBox(height: 12),
              _buildDetailRow('Déjà payé', '${_formatNumber(item['montant_paye']?.toDouble() ?? 0)} $devise', Icons.payments, color: _p.success),
              const SizedBox(height: 12),
              _buildDetailRow('Reste', '${_formatNumber(item['reste']?.toDouble() ?? 0)} $devise', Icons.account_balance_wallet, color: _p.gold),
            ],
            const SizedBox(height: 20),
            if (isVente && _peutAnnulerVente(item)) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmerAnnulation(item),
                  icon: Icon(Icons.cancel_outlined, size: 18, color: _p.danger),
                  label: Text('Annuler la vente', style: TextStyle(color: _p.danger, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _p.danger.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (!isVente && _peutAnnulerCredit(item)) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmerAnnulationCredit(item),
                  icon: Icon(Icons.cancel_outlined, size: 18, color: _p.danger),
                  label: Text('Annuler le dossier crédit', style: TextStyle(color: _p.danger, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _p.danger.withOpacity(0.5)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(modalContext),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: _p.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Fermer'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? color}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: _p.accent.withOpacity(0.08), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, size: 16, color: _p.accent),
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(fontSize: 12, color: _p.textMute)),
        const Spacer(),
        Text(
          value,
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color ?? _p.text),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: _p.bg,
      body: SafeArea(
        child: _isLoading
            ?  Center(child: CircularProgressIndicator(color: _p.accent))
            : Column(
                children: [
                  _buildHeader(),
                  _buildStatsRow(isMobile),
                  _buildSearchBar(),
                  _buildPeriodSelector(),
                  _buildTabBar(),
                  Expanded(
                    child: filteredItems.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: EdgeInsets.fromLTRB(12, 8, 12, isMobile ? 24 : 12),
                            itemCount: filteredItems.length,
                            itemBuilder: (_, index) => _buildHistoryCard(filteredItems[index]),
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return GisPageHeader(
      icon: Icons.history_rounded,
      title: 'Historique',
      subtitle: 'Journal des transactions',
      onRefresh: _loadData,
    );
  }

  Widget _buildStatsRow(bool isMobile) {
    final metrics = [
      GisMetricTile(label: 'Ventes', value: _nbVentes.toString(), color: _p.success, icon: Icons.trending_up),
      GisMetricTile(label: 'Crédits', value: _nbCredits.toString(), color: _p.warning, icon: Icons.credit_card),
      GisMetricTile(label: 'CA', value: '${_formatNumber(_totalVentes)} $devise', color: _p.accent, icon: Icons.receipt_long),
      GisMetricTile(label: 'Bénéfice', value: '${_formatNumber(_totalBenefice)} $devise', color: _p.gold, icon: Icons.account_balance_wallet),
    ];

    if (isMobile) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Column(
          children: [
            Row(children: [Expanded(child: metrics[0]), const SizedBox(width: 8), Expanded(child: metrics[1])]),
            const SizedBox(height: 8),
            Row(children: [Expanded(child: metrics[2]), const SizedBox(width: 8), Expanded(child: metrics[3])]),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 4),
      child: Row(
        children: [
          for (var i = 0; i < metrics.length; i++)
            Expanded(child: Padding(padding: EdgeInsets.only(right: i < metrics.length - 1 ? 8 : 0), child: metrics[i])),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return GisSearchField(
      controller: searchController,
      hint: 'Client, téléphone ou produit…',
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      height: 42,
      onChanged: (v) => setState(() => _searchQuery = v.trim()),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, IconData icon) {
    return GisMetricTile(label: label, value: value, color: color, icon: icon);
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GisIconButton(icon: icon, onTap: onTap);
  }

  Widget _buildPeriodSelector() {
    final periods = [
      {'key': 'all', 'label': 'Tout'},
      {'key': 'today', 'label': 'Aujourd\'hui'},
      {'key': 'week', 'label': 'Semaine'},
      {'key': 'month', 'label': 'Mois'},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: periods.map((period) {
            final isSelected = _selectedPeriod == period['key'];
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () => setState(() => _selectedPeriod = period['key'] as String),
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected ? _p.accent.withOpacity(0.15) : _p.surfaceHi,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: isSelected ? _p.accent.withOpacity(0.45) : _p.border),
                  ),
                  child: Text(
                    period['label'] as String,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? _p.accent : _p.textMute,
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

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _p.surfaceHi,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _p.border),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: _p.accent.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _p.accent.withOpacity(0.35)),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: _p.accent,
        unselectedLabelColor: _p.textMute,
        labelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        tabs: const [
          Tab(height: 34, text: 'Tous'),
          Tab(height: 34, text: 'Ventes'),
          Tab(height: 34, text: 'Crédits'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64, height: 64,
            decoration: BoxDecoration(color: _p.surface, borderRadius: BorderRadius.circular(20), border: Border.all(color: _p.border)),
            child: Icon(Icons.history_rounded, size: 28, color: _p.textDim),
          ),
          const SizedBox(height: 16),
           Text("Aucune transaction", style: TextStyle(color: _p.textMute, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
           Text("Les ventes et crédits apparaîtront ici", style: TextStyle(color: _p.textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final isVente = item['_type'] == 'vente';
    final isCreditVente = isVente && _isVenteCredit(item);
    final date = _formatDate(isVente ? item['created_at'] : item['date_credit']);
    final client = item['client_nom'] ?? (isVente ? 'Client comptant' : '-');
    final montant = (item['montant_total'] ?? 0).toDouble();
    final isAnnulee = isVente && _isVenteAnnulee(item);
    final isCreditAnnule = !isVente && _isCreditAnnule(item);
    final statutLabel = isVente
        ? _venteStatutLabel(item)
        : (item['statut'] == 'paye'
            ? 'Soldé'
            : (item['statut'] == 'annule' ? 'Annulé' : 'En cours'));
    final statutColor = isVente
        ? _venteStatutColor(item)
        : (item['statut'] == 'paye' ? _p.success : _p.warning);
    final sousTitre = isVente
        ? (item['nom_produit']?.toString() ?? date)
        : date;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isAnnulee ? _p.border : _p.border),
      ),
      child: Opacity(
        opacity: (isAnnulee || isCreditAnnule) ? 0.55 : 1,
        child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isVente
                ? (isCreditVente ? _p.warning.withOpacity(0.1) : _p.success.withOpacity(0.1))
                : _p.warning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            isVente ? Icons.receipt_long_rounded : Icons.credit_card_rounded,
            color: isVente ? (isCreditVente ? _p.warning : _p.success) : _p.warning,
            size: 22,
          ),
        ),
        title: Text(
          client,
          style:  TextStyle(color: _p.text, fontSize: 14, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sousTitre,
              style: TextStyle(color: _p.textMute, fontSize: 11),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (isVente) ...[
              const SizedBox(height: 2),
              Text(date, style: TextStyle(color: _p.textDim, fontSize: 10)),
            ],
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${_formatNumber(montant)} $devise',
              style: TextStyle(color: statutColor, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(statutLabel, style: TextStyle(color: _p.textDim, fontSize: 9)),
          ],
        ),
        onTap: () => _afficherDetails(item),
        ),
      ),
    );
  }
}