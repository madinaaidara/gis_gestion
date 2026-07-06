import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_refresh_notifier.dart';

/// Écoute [AppRefreshNotifier] et déclenche [onAppRefresh] quand la portée correspond.
mixin AppRefreshListener<T extends StatefulWidget> on State<T> {
  AppRefreshNotifier? _refreshBus;

  AppRefreshScope get refreshScope;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attachRefreshListener());
  }

  void _attachRefreshListener() {
    if (!mounted) return;
    _refreshBus = context.read<AppRefreshNotifier>();
    _refreshBus!.addListener(_handleRefreshSignal);
  }

  @override
  void dispose() {
    _refreshBus?.removeListener(_handleRefreshSignal);
    super.dispose();
  }

  void _handleRefreshSignal() {
    if (!mounted || _refreshBus == null) return;
    if (_refreshBus!.affects(refreshScope)) {
      onAppRefresh();
    }
  }

  void onAppRefresh();
}

/// Déclenche un rafraîchissement global depuis n'importe quel écran.
void refreshAppData(BuildContext context, [AppRefreshScope scope = AppRefreshScope.all]) {
  context.read<AppRefreshNotifier>().refresh(scope);
}
