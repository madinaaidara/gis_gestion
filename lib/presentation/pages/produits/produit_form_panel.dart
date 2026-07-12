import 'package:flutter/material.dart';
import '../../../core/theme/app_surface.dart';
import '../../../core/theme/gis_palette.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/packaging_utils.dart';
import '../../../core/utils/responsive_utils.dart';
import '../../../data/models/category_model.dart';
import '../../../data/models/produit_model.dart';
import '../../../data/repositories/products_repository.dart';
import '../../../core/services/app_refresh_listener.dart';
import '../../viewmodels/products_viewmodel.dart';
import 'produit_guidance_widgets.dart';

/// Formulaire produit — panneau latéral (desktop) ou plein écran (mobile), 3 étapes.
class ProduitFormPanel extends StatefulWidget {
  final String shopId;
  final String devise;
  final List<CategoryModel> categories;
  final ProduitModel? editProduct;

  const ProduitFormPanel({
    super.key,
    required this.shopId,
    required this.devise,
    required this.categories,
    this.editProduct,
  });

  static Future<bool?> open(
    BuildContext context, {
    required String shopId,
    required String devise,
    required List<CategoryModel> categories,
    ProduitModel? editProduct,
  }) {
    final wide = ResponsiveUtils.isTwoColumnWide(context);

    if (wide) {
      return showGeneralDialog<bool>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Fermer',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, anim, _) => Align(
          alignment: Alignment.centerRight,
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero).animate(
              CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
            ),
            child: Material(
              color: GisPalette.of(context).surface,
              child: SizedBox(
                width: 480,
                height: double.infinity,
                child: ProduitFormPanel(
                  shopId: shopId,
                  devise: devise,
                  categories: categories,
                  editProduct: editProduct,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProduitFormPanel(
          shopId: shopId,
          devise: devise,
          categories: categories,
          editProduct: editProduct,
        ),
      ),
    );
  }

  @override
  State<ProduitFormPanel> createState() => _ProduitFormPanelState();
}

class _ProduitFormPanelState extends State<ProduitFormPanel> {
  GisPalette get _p => GisPalette.of(context);


  final _pageController = PageController();
  late final List<ScrollController> _stepScrollControllers;
  int _step = 0;
  bool _saving = false;
  bool _showIdentityExtras = false;
  bool _showPricingExtras = false;
  bool _showStockExtras = false;

  final nomController = TextEditingController();
  final descriptionController = TextEditingController();
  final barcodeController = TextEditingController();
  final quantiteAchatController = TextEditingController();
  final quantiteIntermediaireParLotController = TextEditingController();
  final quantiteBaseParIntermediaireController = TextEditingController();
  final prixAchatTotalController = TextEditingController();
  final prixVenteUnitaireController = TextEditingController();
  final prixVenteGrosController = TextEditingController();
  final stockActuelController = TextEditingController();
  final fournisseurController = TextEditingController();
  final telephoneFournisseurController = TextEditingController();

  String selectedUniteAchat = 'pièce';
  String selectedUniteVente = 'pièce';
  String selectedModeVente = 'unite';
  String selectedUniteIntermediaire = 'sachet';
  String selectedProfilApprovisionnement = 'detail';
  bool useThreeLevelPackaging = false;
  bool vendEnGros = false;
  String? selectedProductCategoryId;

  static final _numericFormatters = [FilteringTextInputFormatter.allow(RegExp(r'[\d.,]'))];
  static const _unitesAchat = ['pièce', 'carton', 'sac', 'bidon', 'paquet', 'boîte'];
  static const _unitesParMode = {
    'poids': ['kg', 'g'],
    'volume': ['litre', 'ml'],
    'unite': ['pièce', 'sachet', 'bouteille'],
  };

  bool get _isEdit => widget.editProduct != null;

  @override
  void initState() {
    super.initState();
    _stepScrollControllers = List.generate(3, (_) => ScrollController());
    if (_isEdit) _loadFromProduct(widget.editProduct!);
  }

  @override
  void dispose() {
    _pageController.dispose();
    for (final controller in _stepScrollControllers) {
      controller.dispose();
    }
    nomController.dispose();
    descriptionController.dispose();
    barcodeController.dispose();
    quantiteAchatController.dispose();
    quantiteIntermediaireParLotController.dispose();
    quantiteBaseParIntermediaireController.dispose();
    prixAchatTotalController.dispose();
    prixVenteUnitaireController.dispose();
    prixVenteGrosController.dispose();
    stockActuelController.dispose();
    fournisseurController.dispose();
    telephoneFournisseurController.dispose();
    super.dispose();
  }

  void _loadFromProduct(ProduitModel p) {
    nomController.text = p.nom;
    descriptionController.text = p.description ?? '';
    barcodeController.text = p.barcode ?? '';
    prixAchatTotalController.text = p.prixAchatTotal > 0 ? p.prixAchatTotal.toStringAsFixed(0) : '';
    prixVenteUnitaireController.text = p.prixVenteUnitaire > 0 ? p.prixVenteUnitaire.toStringAsFixed(0) : '';
    vendEnGros = p.vendEnGros;
    if (vendEnGros) prixVenteGrosController.text = p.prixVenteGros!.toStringAsFixed(0);
    selectedUniteAchat = p.uniteAchat ?? 'pièce';
    selectedUniteVente = p.uniteVente ?? 'pièce';
    selectedModeVente = _modeForUnite(selectedUniteVente);
    selectedProductCategoryId = p.categoryId;
    fournisseurController.text = p.fournisseur ?? '';
    telephoneFournisseurController.text = p.telephoneFournisseur ?? '';
    useThreeLevelPackaging = p.hasPackagingIntermediaire;
    if (useThreeLevelPackaging) {
      selectedUniteIntermediaire = p.uniteIntermediaire ?? 'sachet';
      quantiteIntermediaireParLotController.text = p.quantiteIntermediaireParLot?.toString() ?? '';
      quantiteBaseParIntermediaireController.text = p.quantiteBaseParIntermediaire?.toString() ?? '';
    } else {
      quantiteAchatController.text = p.quantiteParUnite > 1 ? p.quantiteParUnite.toStringAsFixed(0) : '';
    }
    final perLot = useThreeLevelPackaging ? p.quantiteParUnite : (p.quantiteParUnite > 1 ? p.quantiteParUnite : 1);
    final stockConv = perLot > 1 ? p.stock / perLot : p.stock;
    stockActuelController.text = stockConv.toStringAsFixed(stockConv % 1 == 0 ? 0 : 1);
    selectedProfilApprovisionnement = (fournisseurController.text.isNotEmpty || _estUniteGros(selectedUniteAchat))
        ? 'grossiste'
        : 'detail';
    _showIdentityExtras = (p.description?.trim().isNotEmpty ?? false) || (p.barcode?.trim().isNotEmpty ?? false);
    _showPricingExtras = p.vendEnGros;
    _showStockExtras = p.hasPackagingIntermediaire || fournisseurController.text.isNotEmpty;
  }

  double _parse(String t) => double.tryParse(t.trim().replaceAll(',', '.')) ?? 0;

  bool _estUniteGros(String u) => const {'carton', 'sac', 'bidon', 'paquet', 'boîte'}.contains(u);

  String _modeForUnite(String u) {
    for (final e in _unitesParMode.entries) {
      if (e.value.contains(u)) return e.key;
    }
    return 'unite';
  }

  List<String> _unitesForMode(String mode) => _unitesParMode[mode] ?? _unitesParMode['unite']!;

  double _quantiteParUnite() {
    if (useThreeLevelPackaging) {
      final a = _parse(quantiteIntermediaireParLotController.text);
      final b = _parse(quantiteBaseParIntermediaireController.text);
      if (a > 0 && b > 0) return a * b;
    }
    final q = _parse(quantiteAchatController.text);
    return q > 0 ? q : 1;
  }

  double _stockBase() => _parse(stockActuelController.text) * _quantiteParUnite();

  String _deduireTypeVente() {
    if (selectedUniteVente == 'kg' || selectedUniteVente == 'g') return 'poids';
    if (selectedUniteVente == 'litre' || selectedUniteVente == 'ml') return 'volume';
    if (_estUniteGros(selectedUniteAchat) && _quantiteParUnite() > 1) return 'colis';
    return 'unite';
  }

  String? _opt(String v) {
    final t = v.trim();
    return t.isEmpty ? null : t;
  }

  double _coutUnitaire() {
    final q = _quantiteParUnite();
    final p = _parse(prixAchatTotalController.text);
    return q > 0 && p > 0 ? p / q : 0;
  }

  double _marge() => _parse(prixVenteUnitaireController.text) - _coutUnitaire();

  void _goStep(int i) {
    setState(() => _step = i);
    _pageController.animateToPage(i, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final controller = _stepScrollControllers[i];
      if (controller.hasClients) controller.jumpTo(0);
    });
  }

  bool _validateStep(int step) {
    if (step == 0) {
      if (nomController.text.trim().isEmpty) {
        _toast('Indiquez le nom du produit');
        return false;
      }
      return true;
    }
    if (step == 1) {
      if (_quantiteParUnite() <= 0) {
        _toast(useThreeLevelPackaging ? 'Renseignez le conditionnement' : 'Indiquez le contenu du lot');
        return false;
      }
      if (_parse(prixVenteUnitaireController.text) <= 0) {
        _toast('Indiquez le prix de vente');
        return false;
      }
      return true;
    }
    return true;
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating, backgroundColor: _p.surface),
    );
  }

  Future<void> _save() async {
    if (!_validateStep(0) || !_validateStep(1)) return;
    if (vendEnGros && _showPricingExtras && _parse(prixVenteGrosController.text) <= 0) {
      _toast('Indiquez le prix de vente en gros');
      return;
    }

    setState(() => _saving = true);
    final repo = context.read<ProductsRepository>();
    final vm = context.read<ProductsViewModel>();
    final prixGros = vendEnGros && _showPricingExtras ? (_parse(prixVenteGrosController.text) > 0 ? _parse(prixVenteGrosController.text) : null) : null;

    try {
      bool ok;
      if (_isEdit) {
        ok = await repo.updateProduct(widget.editProduct!.id!, {
          'nom': nomController.text.trim(),
          'description': _opt(descriptionController.text),
          'category_id': selectedProductCategoryId,
          'type_vente': _deduireTypeVente(),
          'prix_achat_total': _parse(prixAchatTotalController.text),
          'prix_vente_unitaire': _parse(prixVenteUnitaireController.text),
          'prix_vente_gros': prixGros,
          'unite_achat': selectedUniteAchat,
          'unite_vente': selectedUniteVente,
          'quantite_par_unite': _quantiteParUnite(),
          'unite_intermediaire': useThreeLevelPackaging ? selectedUniteIntermediaire : null,
          'quantite_base_par_intermediaire': useThreeLevelPackaging ? _parse(quantiteBaseParIntermediaireController.text) : null,
          'quantite_intermediaire_par_lot': useThreeLevelPackaging ? _parse(quantiteIntermediaireParLotController.text) : null,
          'stock': _stockBase(),
          'fournisseur': _opt(fournisseurController.text),
          'telephone_fournisseur': _opt(telephoneFournisseurController.text),
          'barcode': _opt(barcodeController.text),
          'updated_at': DateTime.now().toIso8601String(),
        });
      } else {
        final product = ProduitModel(
          shopId: widget.shopId,
          categoryId: selectedProductCategoryId,
          nom: nomController.text.trim(),
          description: _opt(descriptionController.text),
          typeVente: _deduireTypeVente(),
          prixAchatTotal: _parse(prixAchatTotalController.text),
          prixVenteUnitaire: _parse(prixVenteUnitaireController.text),
          prixVenteGros: prixGros,
          uniteAchat: selectedUniteAchat,
          uniteVente: selectedUniteVente,
          quantiteParUnite: _quantiteParUnite(),
          uniteIntermediaire: useThreeLevelPackaging ? selectedUniteIntermediaire : null,
          quantiteBaseParIntermediaire: useThreeLevelPackaging ? _parse(quantiteBaseParIntermediaireController.text) : null,
          quantiteIntermediaireParLot: useThreeLevelPackaging ? _parse(quantiteIntermediaireParLotController.text) : null,
          stock: _stockBase(),
          fournisseur: _opt(fournisseurController.text),
          telephoneFournisseur: _opt(telephoneFournisseurController.text),
          barcode: _opt(barcodeController.text),
        );
        ok = await repo.addProduct(product);
      }

      if (!mounted) return;
      if (ok) {
        await vm.refreshProducts();
        if (mounted) {
          refreshAppData(context);
          Navigator.of(context).pop(true);
        }
      } else {
        _toast(repo.errorMessage.isNotEmpty ? repo.errorMessage : 'Erreur enregistrement');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _p.bg,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTopBar(),
            _buildStepIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _buildStepIdentity(),
                  _buildStepPricing(),
                  _buildStepStock(),
                ],
              ),
            ),
            _buildBottomBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon:  Icon(Icons.close_rounded, color: _p.textMute),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEdit ? 'Modifier le produit' : 'Nouveau produit',
                  style: GoogleFonts.plusJakartaSans(color: _p.text, fontSize: 17, fontWeight: FontWeight.w800),
                ),
                Text(
                  _stepSubtitle,
                  style:  TextStyle(color: _p.textDim, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String get _stepSubtitle {
    switch (_step) {
      case 0:
        return 'Étape 1 · Comment s\'appelle le produit ?';
      case 1:
        return 'Étape 2 · Combien vous payez et vendez';
      default:
        return 'Étape 3 · Combien il en reste';
    }
  }

  Widget _buildStepIndicator() {
    const labels = ['Le produit', 'Les prix', 'La quantité'];
    final colors = [ProduitUi.accent, ProduitUi.achat, ProduitUi.stock];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: List.generate(3, (i) {
          final active = i <= _step;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 2 ? 6 : 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 3,
                    decoration: BoxDecoration(
                      color: active ? colors[i] : _p.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: i == _step ? FontWeight.w700 : FontWeight.w500,
                      color: i == _step ? colors[i] : _p.textDim,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepIdentity() {
    return ColoredBox(
      color: _p.bg,
      child: ListView(
        controller: _stepScrollControllers[0],
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
        ProduitHelpTip(
          title: 'C\'est simple',
          message: 'Mettez le nom comme vous le dites à vos clients. '
              'Exemple : « Riz 25 kg », « Huile », « Savon ».',
          color: ProduitUi.accent,
        ),
        const SizedBox(height: 16),
        _field(nomController, 'Nom du produit *', 'Ex : Riz, Huile, Savon…', Icons.label_outline_rounded, autofocus: !_isEdit, accent: _p.accent),
        const SizedBox(height: 20),
        Text('Rayon (facultatif)', style: _labelStyle()),
        const SizedBox(height: 8),
        _categoryChips(),
        const SizedBox(height: 20),
        InkWell(
          onTap: () => setState(() => _showIdentityExtras = !_showIdentityExtras),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_showIdentityExtras ? Icons.expand_less : Icons.tune_rounded, size: 18, color: _p.textMute),
                const SizedBox(width: 8),
                Text(
                  _showIdentityExtras ? 'Masquer le plus (facultatif)' : 'Plus d\'options (facultatif)',
                  style:  TextStyle(color: _p.textMute, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (_showIdentityExtras) ...[
          const SizedBox(height: 12),
          _field(descriptionController, 'Description', 'Optionnel', Icons.notes_outlined, maxLines: 2),
          const SizedBox(height: 14),
          _field(barcodeController, 'Code-barres', 'EAN / QR', Icons.qr_code_2_outlined, keyboard: TextInputType.number),
        ],
      ],
    ),
    );
  }

  Widget _buildStepPricing() {
    final cout = _coutUnitaire();
    return ColoredBox(
      color: _p.bg,
      child: ListView(
        controller: _stepScrollControllers[1],
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
        ProduitHelpTip(
          title: 'Comment ça marche ?',
          message: '1) Dites comment vous achetez (carton, sac…)\n'
              '2) Combien vous avez payé\n'
              '3) Combien vous vendez au client',
          color: ProduitUi.achat,
          icon: Icons.payments_outlined,
        ),
        const SizedBox(height: 16),
        Text('J\'achète en…', style: _labelStyle(color: _p.warning)),
        const SizedBox(height: 8),
        _chipRow(_unitesAchat, selectedUniteAchat, (v) => setState(() => selectedUniteAchat = v)),
        if (selectedUniteAchat != 'pièce') ...[
          const SizedBox(height: 12),
          ProduitHelpTip(
            title: 'Important',
            message: 'Dans 1 $selectedUniteAchat, il y a combien de $selectedUniteVente ? '
                'Exemple : 1 carton = 12 bouteilles → mettez 12.',
            color: _p.warning,
            icon: Icons.info_outline_rounded,
          ),
          const SizedBox(height: 12),
          _field(
            quantiteAchatController,
            'Combien de $selectedUniteVente dans 1 $selectedUniteAchat ?',
            'Ex : 12',
            Icons.inventory_2_outlined,
            keyboard: const TextInputType.numberWithOptions(decimal: true),
            formatters: _numericFormatters,
            suffix: selectedUniteVente,
            accent: _p.warning,
            onChanged: (_) => setState(() {}),
          ),
        ],
        const SizedBox(height: 20),
        Text('Je vends comment ?', style: _labelStyle()),
        const SizedBox(height: 8),
        _modeSelector(),
        const SizedBox(height: 10),
        _chipRow(_unitesForMode(selectedModeVente), selectedUniteVente, (v) => setState(() => selectedUniteVente = v)),
        const SizedBox(height: 20),
        _field(
          prixAchatTotalController,
          'Combien j\'ai payé pour 1 $selectedUniteAchat ?',
          'Montant au fournisseur',
          Icons.shopping_bag_outlined,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          formatters: _numericFormatters,
          suffix: widget.devise,
          accent: _p.warning,
          onChanged: (_) => setState(() {}),
        ),
        if (cout > 0) ...[
          const SizedBox(height: 8),
          Text(
            '→ Chaque $selectedUniteVente vous coûte ${cout.toStringAsFixed(0)} ${widget.devise}',
            style: TextStyle(color: _p.warning, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 14),
        _field(
          prixVenteUnitaireController,
          'Combien je vends 1 $selectedUniteVente au client ?',
          'Prix en boutique',
          Icons.sell_outlined,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          formatters: _numericFormatters,
          suffix: widget.devise,
          accent: _p.success,
          onChanged: (_) => setState(() {}),
        ),
        if (_coutUnitaire() > 0 || _parse(prixVenteUnitaireController.text) > 0) ...[
          const SizedBox(height: 16),
          _margePreview(),
        ],
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _showPricingExtras = !_showPricingExtras),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_showPricingExtras ? Icons.expand_less : Icons.storefront_outlined, size: 18, color: _p.textMute),
                const SizedBox(width: 8),
                Text(
                  _showPricingExtras ? 'Masquer vente en gros' : 'Plus d\'options (vente en gros)',
                  style: TextStyle(color: _p.textMute, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (_showPricingExtras) ...[
          const SizedBox(height: 14),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: vendEnGros,
            activeTrackColor: _p.accent.withValues(alpha: 0.5),
            activeThumbColor: _p.accent,
            title:  Text('Vente en gros', style: TextStyle(color: _p.text, fontSize: 13)),
            subtitle: Text('Prix revendeur / $selectedUniteAchat', style:  TextStyle(color: _p.textDim, fontSize: 11)),
            onChanged: (v) => setState(() {
              vendEnGros = v;
              if (!v) prixVenteGrosController.clear();
            }),
          ),
          if (vendEnGros)
            _field(
              prixVenteGrosController,
              'Prix gros',
              'Montant',
              Icons.storefront_outlined,
              keyboard: const TextInputType.numberWithOptions(decimal: true),
              formatters: _numericFormatters,
              suffix: widget.devise,
            ),
        ],
      ],
    ),
    );
  }

  Widget _buildStepStock() {
    return ColoredBox(
      color: _p.bg,
      child: ListView(
        controller: _stepScrollControllers[2],
        primary: false,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
        ProduitHelpTip(
          title: 'Comptez ce qu\'il reste',
          message: 'Regardez en rayon ou en réserve : combien de cartons, sacs ou pièces il vous reste aujourd\'hui.',
          color: ProduitUi.stock,
          icon: Icons.warehouse_outlined,
        ),
        const SizedBox(height: 16),
        _field(
          stockActuelController,
          'Il m\'en reste combien ?',
          'Nombre en $selectedUniteAchat',
          Icons.warehouse_outlined,
          keyboard: const TextInputType.numberWithOptions(decimal: true),
          formatters: _numericFormatters,
          suffix: selectedUniteAchat,
          accent: _p.info,
          onChanged: (_) => setState(() {}),
        ),
        if (_parse(stockActuelController.text) > 0 && _quantiteParUnite() > 1) ...[
          const SizedBox(height: 8),
          Text(
            '≈ ${_stockBase().toStringAsFixed(0)} $selectedUniteVente au total',
            style:  TextStyle(color: _p.success, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
        const SizedBox(height: 8),
        InkWell(
          onTap: () => setState(() => _showStockExtras = !_showStockExtras),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Icon(_showStockExtras ? Icons.expand_less : Icons.local_shipping_outlined, size: 18, color: _p.textMute),
                const SizedBox(width: 8),
                Text(
                  _showStockExtras ? 'Masquer approvisionnement' : 'Plus d\'options (approvisionnement)',
                  style: TextStyle(color: _p.textMute, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        if (_showStockExtras) ...[
          const SizedBox(height: 12),
          Text('Approvisionnement', style: _labelStyle()),
          const SizedBox(height: 8),
          _chipRow(['detail', 'grossiste'], selectedProfilApprovisionnement, (v) => setState(() => selectedProfilApprovisionnement = v), labels: const {
            'detail': 'Détail',
            'grossiste': 'Grossiste',
          }),
          if (selectedProfilApprovisionnement == 'grossiste') ...[
            const SizedBox(height: 14),
            _field(fournisseurController, 'Nom grossiste', 'Optionnel', Icons.local_shipping_outlined),
            const SizedBox(height: 12),
            _field(telephoneFournisseurController, 'Téléphone', 'Optionnel', Icons.phone_outlined, keyboard: TextInputType.phone),
          ],
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: useThreeLevelPackaging,
            activeTrackColor: _p.accent.withValues(alpha: 0.5),
            activeThumbColor: _p.accent,
            title:  Text('Conditionnement 3 niveaux', style: TextStyle(color: _p.text, fontSize: 13)),
            subtitle:  Text('Paquet → sachet → pièce', style: TextStyle(color: _p.textDim, fontSize: 11)),
            onChanged: (v) => setState(() {
              useThreeLevelPackaging = v;
              if (v) quantiteAchatController.clear();
            }),
          ),
          if (useThreeLevelPackaging) ...[
            _field(quantiteIntermediaireParLotController, 'Par $selectedUniteAchat', 'Nb sachets', Icons.layers_outlined, formatters: _numericFormatters, onChanged: (_) => setState(() {})),
            const SizedBox(height: 10),
            _field(quantiteBaseParIntermediaireController, 'Par $selectedUniteIntermediaire', 'Nb pièces', Icons.grid_view_rounded, formatters: _numericFormatters, onChanged: (_) => setState(() {})),
          ],
        ],
        const SizedBox(height: 20),
        _recapCard(),
      ],
    ),
    );
  }

  Widget _recapCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _p.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: _p.border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Avant d\'enregistrer', style: GoogleFonts.plusJakartaSans(color: _p.text, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(height: 10),
          _recapLine('Produit', nomController.text.trim().isEmpty ? '—' : nomController.text.trim(), _p.accent),
          _recapLine('Prix client', '${_parse(prixVenteUnitaireController.text).toStringAsFixed(0)} ${widget.devise} / $selectedUniteVente', _p.success),
          _recapLine('Il en reste', PackagingUtils.formatStock(ProduitModel(nom: '', stock: _stockBase(), quantiteParUnite: _quantiteParUnite(), uniteAchat: selectedUniteAchat, uniteVente: selectedUniteVente)), _p.info),
          if (_marge() != 0 || _parse(prixVenteUnitaireController.text) > 0)
            _recapLine('Gain', ProduitUi.gainSimple(_marge(), widget.devise, selectedUniteVente), _marge() >= 0 ? _p.success : _p.danger),
        ],
      ),
    );
  }

  Widget _recapLine(String k, String v, Color c) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 4, height: 32, decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k, style: TextStyle(color: c, fontSize: 10, fontWeight: FontWeight.w700)),
                  Text(v, style:  TextStyle(color: _p.text, fontSize: 12, fontWeight: FontWeight.w600, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _margePreview() {
    final m = _marge();
    final ok = m >= 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (ok ? _p.success : _p.danger).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: (ok ? _p.success : _p.danger).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Icon(ok ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: ok ? _p.success : _p.danger, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              ProduitUi.gainSimple(m, widget.devise, selectedUniteVente),
              style: TextStyle(color: ok ? _p.success : _p.danger, fontSize: 12, fontWeight: FontWeight.w600, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.paddingOf(context).bottom),
      decoration:  BoxDecoration(
        color: _p.surface,
        border: Border(top: BorderSide(color: _p.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
              onPressed: _saving ? null : () => _goStep(_step - 1),
              child:  Text('Retour', style: TextStyle(color: _p.textMute)),
            )
          else
            const SizedBox(width: 8),
          const Spacer(),
          if (_step < 2)
            FilledButton(
              onPressed: _saving
                  ? null
                  : () {
                      if (_validateStep(_step)) _goStep(_step + 1);
                    },
              style: FilledButton.styleFrom(backgroundColor: _p.accent, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: Text('Continuer'),
            )
          else
            FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: _p.accent, padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: _saving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(_isEdit ? 'Enregistrer' : 'Ajouter au catalogue'),
            ),
        ],
      ),
    );
  }

  TextStyle _labelStyle({Color? color}) =>
      GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color ?? _p.textMute);

  Widget _field(
    TextEditingController c,
    String label,
    String hint,
    IconData icon, {
    TextInputType? keyboard,
    List<TextInputFormatter>? formatters,
    String? suffix,
    int maxLines = 1,
    bool autofocus = false,
    Color? accent,
    ValueChanged<String>? onChanged,
  }) {
    final fieldAccent = accent ?? _p.accent;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: _labelStyle(color: fieldAccent)),
        const SizedBox(height: 6),
        TextField(
          controller: c,
          autofocus: autofocus,
          maxLines: maxLines,
          keyboardType: keyboard,
          inputFormatters: formatters,
          style:  TextStyle(color: _p.text, fontSize: 15),
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:  TextStyle(color: _p.textDim, fontSize: 13),
            filled: true,
            fillColor: _p.surface,
            prefixIcon: Icon(icon, size: 18, color: fieldAccent),
            suffixText: suffix,
            suffixStyle: TextStyle(color: fieldAccent.withValues(alpha: 0.85), fontSize: 12, fontWeight: FontWeight.w600),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldAccent.withValues(alpha: 0.28))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: fieldAccent, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }

  Widget _chipRow(
    List<String> values,
    String selected,
    ValueChanged<String> onSelect, {
    Map<String, String>? labels,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((v) {
        final active = selected == v;
        final label = labels?[v] ?? v;
        return FilterChip(
          label: Text(label, style: TextStyle(fontSize: 12, color: active ? _p.accentSoft : _p.textMute)),
          selected: active,
          onSelected: (_) => onSelect(v),
          backgroundColor: _p.surface,
          selectedColor: _p.accent.withValues(alpha: 0.18),
          checkmarkColor: _p.accentSoft,
          side: BorderSide(color: active ? _p.accent.withValues(alpha: 0.45) : _p.border),
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
        );
      }).toList(),
    );
  }

  Widget _categoryChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: Text('Sans catégorie', style: TextStyle(fontSize: 12)),
          selected: selectedProductCategoryId == null,
          onSelected: (_) => setState(() => selectedProductCategoryId = null),
          backgroundColor: _p.surface,
          selectedColor: _p.accent.withValues(alpha: 0.18),
          side: BorderSide(color: selectedProductCategoryId == null ? _p.accent.withValues(alpha: 0.45) : _p.border),
        ),
        ...widget.categories.where((c) => c.id != null).map(
              (cat) => FilterChip(
                label: Text(cat.nom, style: TextStyle(fontSize: 12)),
                selected: selectedProductCategoryId == cat.id,
                onSelected: (_) => setState(() => selectedProductCategoryId = cat.id),
                backgroundColor: _p.surface,
                selectedColor: _p.accent.withValues(alpha: 0.18),
                side: BorderSide(color: selectedProductCategoryId == cat.id ? _p.accent.withValues(alpha: 0.45) : _p.border),
              ),
            ),
      ],
    );
  }

  Widget _modeSelector() {
    const modes = [
      ('unite', 'Un par un', Icons.category_outlined),
      ('poids', 'Au kilo', Icons.scale_outlined),
      ('volume', 'Au litre', Icons.water_drop_outlined),
    ];
    return Row(
      children: modes.map((m) {
        final (id, label, icon) = m;
        final active = selectedModeVente == id;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: id != 'volume' ? 8 : 0),
            child: InkWell(
              onTap: () => setState(() {
                selectedModeVente = id;
                selectedUniteVente = _unitesForMode(id).first;
              }),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: active ? _p.accent.withValues(alpha: 0.12) : _p.surface,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: active ? _p.accent.withValues(alpha: 0.4) : _p.border),
                ),
                child: Column(
                  children: [
                    Icon(icon, size: 16, color: active ? _p.accentSoft : _p.textMute),
                    const SizedBox(height: 4),
                    Text(label, style: TextStyle(fontSize: 10, color: active ? _p.accentSoft : _p.textMute, fontWeight: active ? FontWeight.w600 : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
