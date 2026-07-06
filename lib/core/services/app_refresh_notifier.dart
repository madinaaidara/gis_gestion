import 'package:flutter/foundation.dart';

/// Portée du rafraîchissement des données affichées.
enum AppRefreshScope {
  all,
  dashboard,
  products,
  sales,
  credits,
  history,
  stats,
}

/// Bus léger pour synchroniser l'UI après écritures Supabase
/// (ventes, produits, crédits…) sans recharger toute la page.
class AppRefreshNotifier extends ChangeNotifier {
  int _tick = 0;
  AppRefreshScope _scope = AppRefreshScope.all;

  int get tick => _tick;
  AppRefreshScope get scope => _scope;

  void refresh([AppRefreshScope scope = AppRefreshScope.all]) {
    _scope = scope;
    _tick++;
    notifyListeners();
  }

  bool affects(AppRefreshScope pageScope) =>
      _scope == AppRefreshScope.all || _scope == pageScope;
}
