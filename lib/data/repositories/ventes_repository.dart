import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vente_model.dart';

class VentesRepository extends ChangeNotifier {
  final _supabase = Supabase.instance.client;
  List<VenteModel> _sales = [];
  bool _isLoading = false;

  List<VenteModel> get sales => _sales;
  bool get isLoading => _isLoading;

  Future<void> fetchSales(String shopId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final response = await _supabase
          .from('ventes')
          .select('*')
          .eq('shop_id', shopId)
          .order('date_vente', ascending: false);
          
      _sales = (response as List).map((json) => VenteModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Erreur fetchSales: $e');
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createSale(VenteModel sale) async {
    try {
      await _supabase.from('ventes').insert(sale.toJson());
      _sales.insert(0, sale); // Ajout local fluide immédiat pour la réactivité
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Erreur createSale: $e');
      return false;
    }
  }
}
