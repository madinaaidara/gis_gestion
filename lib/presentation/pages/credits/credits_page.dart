// lib/presentation/pages/credits/credits_page.dart
import 'package:flutter/material.dart';
import '../../../core/theme/app_surface.dart';
import '../../../core/theme/gis_palette.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../data/models/credit_model.dart';
import '../../viewmodels/credits_viewmodel.dart';
import '../../../data/repositories/shops_repository.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../data/repositories/ventes_repository.dart';
import '../../viewmodels/products_viewmodel.dart';
import '../../widgets/gis_ui_kit.dart';

class CreditPage extends StatefulWidget {
  const CreditPage({super.key});

  @override
  State<CreditPage> createState() => _CreditPageState();
}

class _CreditPageState extends State<CreditPage> with SingleTickerProviderStateMixin {
  GisPalette get _p => GisPalette.of(context);

  // ===== PALETTE DARK PREMIUM =====

  final searchController = TextEditingController();
  final amountController = TextEditingController();
  
  String? shopId;
  String? devise;
  String _selectedFilter = 'all'; // all, en_cours, paye
  
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      if (!mounted || !_tabController.indexIsChanging) return;
      setState(() {
        if (_tabController.index == 0) _selectedFilter = 'all';
        else if (_tabController.index == 1) _selectedFilter = 'en_cours';
        else if (_tabController.index == 2) _selectedFilter = 'paye';
        context.read<CreditsViewModel>().changeFilter(_selectedFilter);
      });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    searchController.dispose();
    amountController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      if (!mounted) return;
      final shopRepo = Provider.of<ShopsRepository>(context, listen: false);
      await shopRepo.checkAndLoadShop(userId);
      if (!mounted) return;

      if (shopRepo.currentShop != null) {
        shopId = shopRepo.currentShop!.id;
        devise = shopRepo.currentShop!.devise;

        final creditsVm = Provider.of<CreditsViewModel>(context, listen: false);
        await creditsVm.loadCredits(shopId!);
      }

      if (mounted) setState(() {});
    } catch (e) {
      debugPrint('Erreur chargement crédits: $e');
      if (mounted) _showSnackBar('Erreur de chargement', false);
    }
  }

  Future<void> _effectuerPaiement(CreditModel credit) async {
    final montant = double.tryParse(amountController.text.trim()) ?? 0;
    
    if (montant <= 0) {
      _showSnackBar("Montant invalide", false);
      return;
    }
    
    if (montant > credit.reste) {
      _showSnackBar("Le montant dépasse le reste à payer", false);
      return;
    }
    
    final vm = Provider.of<CreditsViewModel>(context, listen: false);
    final success = await vm.effectuerVersement(credit.id!, montant);

    if (!mounted) return;

    if (success) {
      amountController.clear();
      Navigator.pop(context);
      _showSnackBar('Paiement enregistré', true);
      await _loadData();
    } else {
      _showSnackBar('Erreur lors du paiement', false);
    }
  }

  bool _peutAnnulerCredit(CreditModel credit) => credit.statut == 'en_cours';

  String _creditStatutLabel(CreditModel credit) {
    switch (credit.statut) {
      case 'paye':
        return 'Soldé';
      case 'annule':
        return 'Annulé';
      default:
        return 'En cours';
    }
  }

  Color _creditStatutColor(CreditModel credit) {
    switch (credit.statut) {
      case 'paye':
        return _p.success;
      case 'annule':
        return _p.textDim;
      default:
        return _p.warning;
    }
  }

  Future<void> _confirmerAnnulationCredit(CreditModel credit) async {
    if (credit.id == null) return;

    final acompte = credit.montantPaye;
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: _p.border)),
        title:  Text('Annuler ce dossier crédit ?', style: TextStyle(color: _p.text, fontSize: 16)),
        content: Text(
          'Le dossier et la vente liée seront marqués « Annulés ».\n'
          'Le stock sera remis en rayon.${acompte > 0 ? '\n\nAcompte déjà reçu : ${_formatNumber(acompte)} ${devise ?? 'FCFA'} — à rembourser au client.' : ''}',
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

    final vm = Provider.of<CreditsViewModel>(context, listen: false);
    final productsRepo = Provider.of<ProductsRepository>(context, listen: false);
    final ventesRepo = Provider.of<VentesRepository>(context, listen: false);
    final result = await vm.annulerCredit(
      credit.id!,
      productsRepository: productsRepo,
      ventesRepository: ventesRepo,
    );

    if (!mounted) return;

    if (result.success) {
      Navigator.pop(context);
      _showSnackBar(result.message ?? 'Dossier annulé', true);
      await _loadData();
      if (shopId != null) {
        await Provider.of<ProductsViewModel>(context, listen: false).reloadForShop(shopId!);
      }
    } else {
      _showSnackBar(result.message ?? 'Annulation impossible', false);
    }
  }

  void _ouvrirModalPaiement(CreditModel credit) {
    amountController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => StatefulBuilder(
        builder: (ctx, setModalState) {
          final montantSaisi = double.tryParse(amountController.text.replaceAll(',', '.')) ?? 0;
          final nouveauReste = (credit.reste - montantSaisi).clamp(0.0, credit.reste);
          final peutEncaisser = montantSaisi > 0 && montantSaisi <= credit.reste + 0.0001;

          void remplirReste() {
            amountController.text = credit.reste.toStringAsFixed(0);
            setModalState(() {});
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
              decoration:  BoxDecoration(
                color: _p.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                border: Border(top: BorderSide(color: _p.border)),
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
                          color: _p.gold.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _p.gold.withOpacity(0.2)),
                        ),
                        child:  Icon(Icons.payments_rounded, color: _p.gold, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              credit.clientNom,
                              style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _p.text),
                            ),
                            Text(
                              'Reste : ${_formatNumber(credit.reste)} ${devise ?? 'FCFA'}',
                              style:  TextStyle(fontSize: 12, color: _p.gold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                       Text(
                        'Montant du paiement',
                        style: TextStyle(color: _p.textMute, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: remplirReste,
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: _p.gold.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: _p.gold.withOpacity(0.25)),
                          ),
                          child: Text(
                            'Tout payer',
                            style: TextStyle(color: _p.gold, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    autofocus: true,
                    style:  TextStyle(color: _p.text, fontSize: 16, fontWeight: FontWeight.bold),
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: '0',
                      hintStyle: TextStyle(color: _p.textDim, fontSize: 16),
                      prefixText: '${devise ?? 'FCFA'} ',
                      prefixStyle:  TextStyle(color: _p.accent, fontSize: 14, fontWeight: FontWeight.bold),
                      filled: true,
                      fillColor: _p.surfaceHi,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _p.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: _p.accent),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _p.gold.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _p.gold.withOpacity(0.1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                         Text('Nouveau reste', style: TextStyle(color: _p.textMute, fontSize: 12)),
                        Text(
                          _formatNumber(nouveauReste),
                          style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _p.gold),
                        ),
                      ],
                    ),
                  ),
                  if (montantSaisi > credit.reste + 0.0001)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Le montant dépasse le reste à payer',
                        style: TextStyle(color: _p.danger, fontSize: 11),
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(modalContext),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(color: _p.border),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Annuler'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: peutEncaisser ? () => _effectuerPaiement(credit) : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: _p.gold,
                            disabledBackgroundColor: _p.surfaceHi,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: Text('Encaisser', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _afficherDetails(CreditModel credit) {
    final statutColor = _creditStatutColor(credit);
    final peutAnnuler = _peutAnnulerCredit(credit);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
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
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    credit.statut == 'paye' ? Icons.check_circle_rounded : Icons.credit_card_rounded,
                    color: statutColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(credit.clientNom, style:  TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: _p.text)),
                      Text(
                        credit.telephoneClient ?? 'Pas de téléphone',
                        style: TextStyle(fontSize: 12, color: _p.textMute),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statutColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _creditStatutLabel(credit),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: statutColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(color: _p.border),
            const SizedBox(height: 16),
            _buildDetailRow("Montant total", "${_formatNumber(credit.montantTotal)} $devise", Icons.receipt_long_rounded),
            const SizedBox(height: 12),
            _buildDetailRow("Déjà payé", "${_formatNumber(credit.montantPaye)} $devise", Icons.payments_rounded, color: _p.success),
            const SizedBox(height: 12),
            _buildDetailRow("Reste à payer", "${_formatNumber(credit.reste)} $devise", Icons.account_balance_wallet_rounded, color: _p.gold),
            const SizedBox(height: 12),
            _buildDetailRow("Date", _formatDate(credit.dateCredit), Icons.calendar_today_rounded),
            const SizedBox(height: 20),
            if (credit.statut == 'en_cours') ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(modalContext);
                    _ouvrirModalPaiement(credit);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _p.gold,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Encaisser un paiement', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (peutAnnuler) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmerAnnulationCredit(credit),
                  icon: Icon(Icons.cancel_outlined, size: 18, color: _p.danger),
                  label: Text('Annuler le dossier', style: TextStyle(color: _p.danger, fontWeight: FontWeight.w600)),
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
                style: OutlinedButton.styleFrom(side: BorderSide(color: _p.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: Text("Fermer"),
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

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _p.success : _p.danger,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<CreditsViewModel>(context);
    final filteredCredits = vm.filteredCredits;
    final isMobile = MediaQuery.of(context).size.width < 800;

    return Scaffold(
      backgroundColor: _p.bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(vm, isMobile),
            _buildSearchBar(),
            _buildTabBar(),
            Expanded(
              child: vm.isLoading
                  ?  Center(child: CircularProgressIndicator(color: _p.accent))
                  : filteredCredits.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(12, 8, 12, isMobile ? 24 : 12),
                          itemCount: filteredCredits.length,
                          itemBuilder: (_, index) => _buildCreditCard(filteredCredits[index]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(CreditsViewModel vm, bool isMobile) {
    return GisPageHeader(
      icon: Icons.credit_card_rounded,
      title: 'Crédits',
      subtitle: 'Suivi des dettes clients',
      onRefresh: _loadData,
      metrics: [
        GisMetricTile(label: 'Dossiers', value: vm.totalDossiers.toString(), color: _p.accent),
        GisMetricTile(label: 'En cours', value: vm.dossiersEnCours.toString(), color: _p.warning),
        GisMetricTile(label: 'Soldés', value: vm.dossiersPayes.toString(), color: _p.success),
        GisMetricTile(
          label: 'Dette totale',
          value: '${_formatNumber(vm.detteTotale)} ${devise ?? ''}',
          color: _p.gold,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return GisMetricTile(label: label, value: value, color: color);
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap) {
    return GisIconButton(icon: icon, onTap: onTap);
  }

  Widget _buildSearchBar() {
    return GisSearchField(
      controller: searchController,
      hint: 'Rechercher par nom ou téléphone…',
      padding: const EdgeInsets.all(12),
      height: 42,
      onChanged: (v) => context.read<CreditsViewModel>().updateSearchQuery(v.trim()),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
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
          Tab(height: 34, text: 'En cours'),
          Tab(height: 34, text: 'Soldés'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const GisEmptyState(
      icon: Icons.credit_card_off_rounded,
      title: 'Aucun crédit',
      subtitle: 'Les crédits clients apparaîtront ici',
    );
  }

  Widget _buildCreditCard(CreditModel credit) {
    final isPaye = credit.statut == 'paye';
    final isAnnule = credit.statut == 'annule';
    final isEnCours = credit.statut == 'en_cours';
    final statutColor = _creditStatutColor(credit);
    final pourcentage = credit.montantTotal > 0 ? (credit.montantPaye / credit.montantTotal) : 0;

    return Opacity(
      opacity: isAnnule ? 0.55 : 1,
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _p.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _p.border),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            leading: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: statutColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isPaye ? Icons.check_circle_rounded : Icons.credit_card_rounded,
                color: statutColor,
                size: 22,
              ),
            ),
            title: Text(
              credit.clientNom,
              style:  TextStyle(color: _p.text, fontSize: 14, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  credit.telephoneClient ?? 'Pas de téléphone',
                  style: TextStyle(color: _p.textMute, fontSize: 11),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(credit.dateCredit),
                  style: TextStyle(color: _p.textDim, fontSize: 10),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isAnnule ? _creditStatutLabel(credit) : '${_formatNumber(credit.reste)} $devise',
                  style: TextStyle(
                    color: statutColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isAnnule ? 'Dossier clos' : 'sur ${_formatNumber(credit.montantTotal)} $devise',
                  style:  TextStyle(color: _p.textDim, fontSize: 9),
                ),
              ],
            ),
            onTap: () => _afficherDetails(credit),
          ),
          if (isEnCours) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _p.surfaceHi,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pourcentage.clamp(0.0, 1.0).toDouble(),
                        backgroundColor: _p.border,
                        color: _p.gold,
                        minHeight: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${(pourcentage * 100).toStringAsFixed(0)}%",
                    style: TextStyle(color: _p.gold, fontSize: 10, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () => _ouvrirModalPaiement(credit),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _p.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.payments_rounded, size: 12, color: _p.gold),
                          const SizedBox(width: 4),
                          Text("Payer", style: TextStyle(color: _p.gold, fontSize: 11, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}