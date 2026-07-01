import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OpenSearchIntent extends Intent {
  const OpenSearchIntent();
}

/// Raccourci Ctrl+K / Cmd+K pour ouvrir la recherche globale.
class SearchShortcuts extends StatelessWidget {
  final Widget child;
  final VoidCallback onOpenSearch;

  const SearchShortcuts({
    super.key,
    required this.child,
    required this.onOpenSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.keyK, control: true): OpenSearchIntent(),
        SingleActivator(LogicalKeyboardKey.keyK, meta: true): OpenSearchIntent(),
      },
      child: Actions(
        actions: {
          OpenSearchIntent: CallbackAction<OpenSearchIntent>(
            onInvoke: (_) {
              onOpenSearch();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: false,
          child: child,
        ),
      ),
    );
  }
}
