import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/produit_model.dart';
import '../../data/models/credit_model.dart';
import '../../data/repositories/products_repository.dart';
import '../../data/repositories/credits_repository.dart';
import '../../data/repositories/shops_repository.dart';

/// Recherche globale style Spotify — produits, pages rapides.
class GlobalSearchOverlay extends StatefulWidget {
  final void Function(int navIndex, {String? productQuery, String? clientQuery}) onNavigate;

  const GlobalSearchOverlay({super.key, required this.onNavigate});

  static Future<void> show(
    BuildContext context, {
    required void Function(int navIndex, {String? productQuery, String? clientQuery}) onNavigate,
  }) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Fermer la recherche',
      barrierColor: Colors.black87,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (_, __, ___) => GlobalSearchOverlay(onNavigate: onNavigate),
      transitionBuilder: (_, anim, __, child) {
        return FadeTransition(
          opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0, -0.03), end: Offset.zero)
                .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  State<GlobalSearchOverlay> createState() => _GlobalSearchOverlayState();
}

class _GlobalSearchOverlayState extends State<GlobalSearchOverlay> {
  static const Color _bg = Color(0xFF121212);
  static const Color _surface = Color(0xFF1A1A1A);
  static const Color _border = Color(0xFF282828);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _mute = Color(0xFFB3B3B3);
  static const Color _accent = Color(0xFF7C5CFF);

  final _focusNode = FocusNode();
  final _controller = TextEditingController();
  Timer? _debounce;
  bool _loading = false;
  List<ProduitModel> _productResults = [];
  List<CreditModel> _clientResults = [];

  static const _quickPages = [
    (Icons.home_rounded, 'Accueil', 0),
    (Icons.point_of_sale_rounded, 'Caisse / Vente', 1),
    (Icons.inventory_2_rounded, 'Produits', 2),
    (Icons.credit_card_rounded, 'Crédits', 3),
    (Icons.history_rounded, 'Historique', 4),
    (Icons.bar_chart_rounded, 'Statistiques', 5),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusNode.requestFocus());
    _controller.addListener(_onQueryChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged() {
    if (mounted) {
      setState(() {});
    }
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), _runSearch);
  }

  Future<void> _runSearch() async {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      if (mounted) {
        setState(() {
          _productResults = [];
          _clientResults = [];
          _loading = false;
        });
      }
      return;
    }

    setState(() => _loading = true);
    final shopId = context.read<ShopsRepository>().currentShop?.id;
    if (shopId == null) {
      if (mounted) {
        setState(() => _loading = false);
      }
      return;
    }

    try {
      final productsRepo = context.read<ProductsRepository>();
      final creditsRepo = context.read<CreditsRepository>();
      final results = await Future.wait([
        productsRepo.fetchProducts(shopId: shopId, searchPattern: q),
        creditsRepo.searchClients(shopId, q),
      ]);
      if (mounted) {
        setState(() {
          _productResults = (results[0] as List<ProduitModel>).take(8).toList();
          _clientResults = results[1] as List<CreditModel>;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  void _closeAndNavigate(int index, {String? productQuery, String? clientQuery}) {
    Navigator.of(context).pop();
    widget.onNavigate(index, productQuery: productQuery, clientQuery: clientQuery);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= 700;

    return Material(
      color: _bg,
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWide ? 680 : double.infinity),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 24 : 16, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _border),
                          ),
                          child: Row(
                            children: [
                              const SizedBox(width: 16),
                              const Icon(Icons.search_rounded, color: _mute, size: 22),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  focusNode: _focusNode,
                                  style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 15),
                                  decoration: InputDecoration(
                                    hintText: 'Produits, clients, pages…',
                                    hintStyle: TextStyle(color: _mute.withValues(alpha: 0.7), fontSize: 15),
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  onSubmitted: (_) => _runSearch(),
                                ),
                              ),
                              if (_controller.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(Icons.close_rounded, color: _mute, size: 20),
                                  onPressed: () {
                                    _controller.clear();
                                    setState(() {
                                      _productResults = [];
                                      _clientResults = [];
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _text, size: 28),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (_controller.text.trim().isEmpty) ...[
                    Text('Pages', style: GoogleFonts.plusJakartaSans(color: _mute, fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _quickPages.map((p) {
                        return ActionChip(
                          backgroundColor: _surface,
                          side: const BorderSide(color: _border),
                          label: Text(p.$2, style: const TextStyle(color: _text, fontSize: 12)),
                          avatar: Icon(p.$1, size: 16, color: _accent),
                          onPressed: () => _closeAndNavigate(p.$3),
                        );
                      }).toList(),
                    ),
                  ] else ...[
                    if (_loading)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _accent)),
                      )
                    else if (_productResults.isEmpty && _clientResults.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'Aucun résultat',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: _mute.withValues(alpha: 0.8), fontSize: 14),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView(
                          children: [
                            if (_clientResults.isNotEmpty) ...[
                              Text('Clients crédit', style: GoogleFonts.plusJakartaSans(color: _mute, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ..._clientResults.map((c) => _clientTile(c)),
                              const SizedBox(height: 16),
                            ],
                            if (_productResults.isNotEmpty) ...[
                              Text('Produits', style: GoogleFonts.plusJakartaSans(color: _mute, fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 8),
                              ..._productResults.map((p) => _productTile(p)),
                            ],
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _productTile(ProduitModel p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _closeAndNavigate(2, productQuery: p.nom),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.inventory_2_outlined, color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nom, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        'Stock: ${p.stock.toStringAsFixed(0)} · ${p.prixVenteUnitaire.toStringAsFixed(0)} FCFA',
                        style: TextStyle(color: _mute.withValues(alpha: 0.85), fontSize: 11),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _closeAndNavigate(1),
                  child: const Text('Caisse', style: TextStyle(color: _accent, fontSize: 12)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _clientTile(CreditModel c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: _surface,
        borderRadius: BorderRadius.circular(8),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _closeAndNavigate(3, clientQuery: c.clientNom),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.person_outline_rounded, color: Color(0xFFF59E0B), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.clientNom, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: _text, fontWeight: FontWeight.w600, fontSize: 14)),
                      Text(
                        '${c.telephoneClient ?? '—'} · Reste ${c.reste.toStringAsFixed(0)} FCFA',
                        style: TextStyle(color: _mute.withValues(alpha: 0.85), fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
