import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../data/models/assistant_message.dart';
import '../../data/repositories/shops_repository.dart';
import '../viewmodels/assistant_viewmodel.dart';

/// Contrôle global de l'assistant (ouverture depuis la barre supérieure).
class GisAssistantScope extends InheritedWidget {
  final VoidCallback toggle;
  final VoidCallback open;
  final VoidCallback close;
  final bool isOpen;

  const GisAssistantScope({
    super.key,
    required this.toggle,
    required this.open,
    required this.close,
    required this.isOpen,
    required super.child,
  });

  static GisAssistantScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<GisAssistantScope>();
  }

  @override
  bool updateShouldNotify(GisAssistantScope oldWidget) => isOpen != oldWidget.isOpen;
}

/// Hôte global : panneau chat overlay uniquement (jamais inline dans une page).
class GisAssistantHost extends StatefulWidget {
  final Widget child;

  const GisAssistantHost({super.key, required this.child});

  @override
  State<GisAssistantHost> createState() => _GisAssistantHostState();
}

class _GisAssistantHostState extends State<GisAssistantHost> {
  bool _isOpen = false;

  Future<void> _ensureInitialized() async {
    final shop = context.read<ShopsRepository>().currentShop;
    if (shop?.id == null) return;
    await context.read<AssistantViewModel>().initialize(
          shopId: shop!.id!,
          shopName: shop.nomBoutique,
          devise: shop.devise,
        );
  }

  void _openPanel() {
    if (_isOpen) return;
    HapticFeedback.selectionClick();
    setState(() => _isOpen = true);
    _ensureInitialized();
  }

  void _closePanel() {
    if (!_isOpen) return;
    setState(() => _isOpen = false);
  }

  void _togglePanel() {
    if (_isOpen) {
      _closePanel();
    } else {
      _openPanel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GisAssistantScope(
      toggle: _togglePanel,
      open: _openPanel,
      close: _closePanel,
      isOpen: _isOpen,
      child: Consumer<ShopsRepository>(
        builder: (context, shopRepo, child) {
          final hasShop = shopRepo.currentShop != null;
          return Stack(
            fit: StackFit.expand,
            children: [
              child!,
              if (hasShop && _isOpen) ...[
                Positioned.fill(
                  child: GestureDetector(
                    onTap: _closePanel,
                    child: Container(color: Colors.black.withValues(alpha: 0.5)),
                  ),
                ),
                _AssistantChatWindow(onClose: _closePanel),
              ],
            ],
          );
        },
        child: widget.child,
      ),
    );
  }
}

/// Bouton discret pour la barre supérieure (desktop + mobile).
class GisAssistantToolbarButton extends StatelessWidget {
  final bool compact;

  const GisAssistantToolbarButton({super.key, this.compact = false});

  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _accentSoft = Color(0xFFB8A4FF);

  @override
  Widget build(BuildContext context) {
    final scope = GisAssistantScope.maybeOf(context);
    if (scope == null) return const SizedBox.shrink();

    final isActive = scope.isOpen;

    if (compact) {
      return IconButton(
        onPressed: scope.toggle,
        tooltip: 'Assistant Gis',
        icon: Icon(
          Icons.auto_awesome_rounded,
          color: isActive ? _accentSoft : Colors.white,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: Material(
        color: isActive ? _accent.withValues(alpha: 0.22) : const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: scope.toggle,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isActive ? _accent.withValues(alpha: 0.5) : const Color(0xFF2A2A2E),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 18,
                  color: isActive ? _accentSoft : Colors.white.withValues(alpha: 0.85),
                ),
                const SizedBox(width: 8),
                Text(
                  'Assistant',
                  style: GoogleFonts.plusJakartaSans(
                    color: isActive ? _accentSoft : Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
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

class _AssistantChatWindow extends StatefulWidget {
  final VoidCallback onClose;

  const _AssistantChatWindow({required this.onClose});

  @override
  State<_AssistantChatWindow> createState() => _AssistantChatWindowState();
}

class _AssistantChatWindowState extends State<_AssistantChatWindow> {
  static const Color _bg = Color(0xFF050505);
  static const Color _accent = Color(0xFF7C5CFF);

  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _send(AssistantViewModel vm) {
    final v = _controller.text;
    if (v.trim().isEmpty || !vm.isReady || vm.isThinking) return;
    HapticFeedback.lightImpact();
    vm.ask(v);
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isMobile = size.width < 720;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    final panelWidth = isMobile ? size.width - 24.0 : 380.0;
    final panelHeight = isMobile ? (size.height * 0.78).clamp(420.0, 640.0) : 560.0;
    final bottom = isMobile ? 12.0 + bottomInset : 24.0;
    final right = isMobile ? 12.0 : 24.0;

    return Positioned(
      right: right,
      bottom: bottom,
      child: Material(
        elevation: 28,
        shadowColor: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        color: _bg,
        child: Container(
          width: panelWidth,
          height: panelHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF222226)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Consumer<AssistantViewModel>(
              builder: (context, vm, _) {
                _scrollToBottom();
                return Column(
                  children: [
                    _ChatHeader(
                      onClose: widget.onClose,
                      onClear: vm.clearHistory,
                      isLoading: vm.isLoading,
                    ),
                    if (vm.isLoading)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(strokeWidth: 2, color: _accent),
                        ),
                      )
                    else ...[
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                          itemCount: vm.messages.length + (vm.isThinking ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i >= vm.messages.length) {
                              return const _ThinkingIndicator();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _AssistantBubble(message: vm.messages[i]),
                            );
                          },
                        ),
                      ),
                      _SuggestionChips(
                        questions: vm.suggestedQuestions,
                        enabled: vm.isReady && !vm.isThinking,
                        onTap: vm.ask,
                      ),
                      _ChatInputBar(
                        controller: _controller,
                        enabled: vm.isReady && !vm.isThinking,
                        isThinking: vm.isThinking,
                        onSend: () => _send(vm),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  final VoidCallback onClose;
  final VoidCallback onClear;
  final bool isLoading;

  const _ChatHeader({
    required this.onClose,
    required this.onClear,
    required this.isLoading,
  });

  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _accentSoft = Color(0xFFB8A4FF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: const BoxDecoration(
        color: _surfaceHi,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent.withValues(alpha: 0.35), _accent.withValues(alpha: 0.1)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: _accentSoft, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant Gis',
                  style: GoogleFonts.plusJakartaSans(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  isLoading ? 'Chargement…' : 'Prévisions · Tendances · Conseils',
                  style: const TextStyle(color: _textMute, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: _textMute, size: 20),
            tooltip: 'Effacer',
            onPressed: isLoading ? null : onClear,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: _textMute, size: 22),
            tooltip: 'Fermer',
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SuggestionChips extends StatelessWidget {
  final List<String> questions;
  final bool enabled;
  final void Function(String) onTap;

  const _SuggestionChips({
    required this.questions,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final q = questions[i];
          return ActionChip(
            label: Text(q, style: const TextStyle(fontSize: 10, color: Color(0xFFF5F5F7))),
            backgroundColor: const Color(0xFF0E0E10),
            side: const BorderSide(color: Color(0xFF222226)),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: enabled ? () => onTap(q) : null,
          );
        },
      ),
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool enabled;
  final bool isThinking;
  final VoidCallback onSend;

  const _ChatInputBar({
    required this.controller,
    required this.enabled,
    required this.isThinking,
    required this.onSend,
  });

  static const Color _bg = Color(0xFF050505);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _textMute = Color(0xFF8A8A92);
  static const Color _accent = Color(0xFF7C5CFF);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF0E0E10),
        border: Border(top: BorderSide(color: _border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: enabled,
              style: const TextStyle(color: _text, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Posez votre question…',
                hintStyle: TextStyle(color: _textMute.withValues(alpha: 0.75), fontSize: 12),
                filled: true,
                fillColor: _bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _accent.withValues(alpha: 0.55)),
                ),
              ),
              textInputAction: TextInputAction.send,
              onSubmitted: enabled ? (_) => onSend() : null,
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _accent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: enabled && !isThinking ? onSend : null,
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 46,
                height: 46,
                child: isThinking
                    ? const Padding(
                        padding: EdgeInsets.all(13),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThinkingIndicator extends StatelessWidget {
  const _ThinkingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 4, bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF7C5CFF))),
          SizedBox(width: 8),
          Text('Analyse en cours…', style: TextStyle(color: Color(0xFF8A8A92), fontSize: 12)),
        ],
      ),
    );
  }
}

class _AssistantBubble extends StatelessWidget {
  final AssistantMessage message;

  const _AssistantBubble({required this.message});

  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _accent = Color(0xFF7C5CFF);

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == AssistantMessageRole.user;
    final maxW = MediaQuery.sizeOf(context).width * 0.72;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: maxW.clamp(240, 320)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? _accent.withValues(alpha: 0.2) : _surfaceHi,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isUser ? 14 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 14),
          ),
          border: Border.all(color: isUser ? _accent.withValues(alpha: 0.35) : _border),
        ),
        child: _FormattedAssistantText(text: message.text, color: _text),
      ),
    );
  }
}

class _FormattedAssistantText extends StatelessWidget {
  final String text;
  final Color color;

  const _FormattedAssistantText({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    final spans = <TextSpan>[];
    final parts = text.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: TextStyle(
          color: color,
          fontSize: 13,
          height: 1.45,
          fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w400,
        ),
      ));
    }
    return Text.rich(TextSpan(children: spans));
  }
}
