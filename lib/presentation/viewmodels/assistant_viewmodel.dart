import 'package:flutter/material.dart';

import '../../core/services/assistant_engine.dart';
import '../../data/models/assistant_message.dart';
import '../../data/repositories/assistant_repository.dart';

class AssistantViewModel extends ChangeNotifier {
  final AssistantRepository _repository;
  final AssistantEngine _engine;

  AssistantViewModel(this._repository, {AssistantEngine? engine})
      : _engine = engine ?? AssistantEngine();

  final List<AssistantMessage> _messages = [];
  bool _isLoading = false;
  bool _isThinking = false;
  String? _shopId;
  AssistantContext? _context;

  List<AssistantMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isThinking => _isThinking;
  bool get isReady => _context != null && !_isLoading;
  List<String> get suggestedQuestions => AssistantEngine.suggestedQuestions;

  Future<void> initialize({
    required String shopId,
    required String shopName,
    required String devise,
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh && _shopId == shopId && _context != null) return;

    _shopId = shopId;
    _isLoading = true;
    notifyListeners();

    _context = await _repository.loadContext(
      shopId: shopId,
      shopName: shopName,
      devise: devise,
    );

    if (_messages.isEmpty) {
      _messages.add(AssistantMessage(
        role: AssistantMessageRole.assistant,
        text: 'Bonjour ! Je suis **Assistant Gis**, votre copilote pour **$shopName**. '
            'Je peux analyser votre activité, **prévoir** votre CA de fin de mois, '
            'détecter les **tendances** et anticiper les **ruptures de stock**.',
        createdAt: DateTime.now(),
      ));
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshContext({
    required String shopName,
    required String devise,
  }) async {
    if (_shopId == null) return;
    await initialize(
      shopId: _shopId!,
      shopName: shopName,
      devise: devise,
      forceRefresh: true,
    );
  }

  Future<void> ask(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty || _isThinking) return;

    final ctx = _context;
    if (ctx == null) return;

    _messages.add(AssistantMessage(
      role: AssistantMessageRole.user,
      text: trimmed,
      createdAt: DateTime.now(),
    ));
    _isThinking = true;
    notifyListeners();

    await Future<void>.delayed(const Duration(milliseconds: 350));

    final answer = _engine.answer(trimmed, ctx);
    _messages.add(AssistantMessage(
      role: AssistantMessageRole.assistant,
      text: answer,
      createdAt: DateTime.now(),
    ));
    _isThinking = false;
    notifyListeners();
  }

  void clearHistory() {
    final shopName = _context?.shopName ?? 'votre boutique';
    _messages.clear();
    _messages.add(AssistantMessage(
      role: AssistantMessageRole.assistant,
      text: 'Conversation effacée. Comment puis-je vous aider pour **$shopName** ?',
      createdAt: DateTime.now(),
    ));
    notifyListeners();
  }
}
