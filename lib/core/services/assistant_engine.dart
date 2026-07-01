import 'package:intl/intl.dart';

import '../../data/models/assistant_message.dart';
import 'assistant_predictions.dart';

/// Moteur de réponses de l'Assistant Gis — analyse les questions en français
/// et répond à partir du contexte métier réel de la boutique.
class AssistantEngine {
  static const suggestedQuestions = [
    'Quel est mon CA aujourd\'hui ?',
    'Projection CA fin de mois ?',
    'Quelle est la tendance sur 7 jours ?',
    'Quels produits vont bientôt être en rupture ?',
    'Fais-moi un bilan du mois',
  ];

  String answer(String question, AssistantContext ctx) {
    final q = _normalize(question);
    if (q.isEmpty) {
      return 'Posez-moi une question sur votre boutique : chiffre d\'affaires, stock, crédits, bénéfices…';
    }

    if (_matches(q, ['bonjour', 'salut', 'bonsoir', 'hello', 'coucou'])) {
      return _greeting(ctx);
    }
    if (_matches(q, ['aide', 'help', 'comment', 'peux tu', 'que peux'])) {
      return _help(ctx);
    }
    if (_matches(q, ['bilan', 'resume', 'résumé', 'synthese', 'synthèse', 'situation'])) {
      return _monthlySummary(ctx);
    }
    if (_matches(q, ['predire', 'prediction', 'prevision', 'prevoir', 'projection', 'projette', 'estimation', 'fin de mois', 'fin du mois', 'extrapol'])) {
      return _caProjection(ctx);
    }
    if (_matches(q, ['tendance', 'evolution', 'evolue', 'hausse', 'baisse', 'compare', 'comparaison'])) {
      return _trendAnalysis(ctx, q);
    }
    final isPredictiveStock = _matches(q, [
      'bientot',
      'vont',
      'dans combien',
      'quand',
      'predire',
      'prevision',
      'estime',
      'combien de jour',
      'epuiser',
    ]);
    if (isPredictiveStock && _matches(q, ['rupture', 'stock', 'produit'])) {
      return _stockProjection(ctx);
    }
    if (_matches(q, ['combien de jour', 'dans combien', 'quand', 'epuiser', 'bientot rupture', 'va rupture', 'predire stock', 'prevision stock'])) {
      return _stockProjection(ctx);
    }
    if (_matches(q, ['rupture', 'stock faible', 'stock bas', 'réappro', 'reappro'])) {
      return _stockAlerts(ctx);
    }
    if (_matches(q, ['top', 'meilleur', 'plus vendu', 'star', 'populaire', 'vendu'])) {
      if (_matches(q, ['stock', 'rupture', 'inventaire']) && !_matches(q, ['vendu', 'top', 'meilleur'])) {
        return _stockAlerts(ctx);
      }
      return _topProducts(ctx);
    }
    if (_matches(q, ['stock', 'inventaire', 'produit'])) {
      if (_matches(q, ['combien', 'nombre', 'total', 'catalogue'])) {
        return _productCount(ctx);
      }
      return _stockAlerts(ctx);
    }
    if (_matches(q, ['credit', 'crédit', 'dette', 'doivent', 'impayé', 'impaye'])) {
      return _credits(ctx);
    }
    if (_matches(q, ['benefice', 'bénéfice', 'marge', 'profit', 'gain'])) {
      return _profit(ctx);
    }
    if (_matches(q, ['vente', 'transaction', 'panier'])) {
      if (_matches(q, ['panier', 'moyen'])) return _averageBasket(ctx);
      return _sales(ctx);
    }
    if (_matches(q, ['ca', 'chiffre', 'affaire', 'revenu', 'recette', 'encaisse'])) {
      return _revenue(ctx, q);
    }
    if (_matches(q, ['objectif', 'performance', 'progression'])) {
      return _dailyGoal(ctx);
    }
    if (_matches(q, ['semaine', '7 jour'])) {
      return _weekSummary(ctx);
    }

    return _fallback(ctx);
  }

  String _greeting(AssistantContext ctx) {
    final ca = _d(ctx.summary, 'ca_jour');
    final ventes = _i(ctx.summary, 'ventes_jour');
    if (ventes == 0) {
      return 'Bonjour ! Je suis l\'Assistant Gis pour **${ctx.shopName}**. '
          'Aucune vente enregistrée aujourd\'hui pour l\'instant. '
          'Demandez-moi votre stock, vos crédits ou un bilan du mois.';
    }
    return 'Bonjour ! Pour **${ctx.shopName}**, vous avez déjà '
        '${_money(ca, ctx.devise)} de CA aujourd\'hui ($ventes vente${ventes > 1 ? 's' : ''}). '
        'Que souhaitez-vous analyser ?';
  }

  String _help(AssistantContext ctx) {
    return 'Je peux répondre en français sur :\n'
        '• **Chiffre d\'affaires** (jour, semaine, mois)\n'
        '• **Prévisions** (projection fin de mois)\n'
        '• **Tendances** (7 jours / 30 jours)\n'
        '• **Stock** (ruptures, alertes, jours restants)\n'
        '• **Crédits clients** en cours\n'
        '• **Top produits** et ventes\n'
        '• **Bilan** global de la boutique\n\n'
        'Exemple : « Projection CA fin de mois ? » ou « Tendance sur 7 jours »';
  }

  String _revenue(AssistantContext ctx, String q) {
    if (_matches(q, ['semaine', '7 jour', 'sept jour'])) {
      final ca = _d(ctx.summary, 'ca_semaine');
      final n = _i(ctx.summary, 'ventes_semaine');
      return 'Sur les **7 derniers jours**, votre CA est de **${_money(ca, ctx.devise)}** '
          '($n vente${n > 1 ? 's' : ''}).';
    }
    if (_matches(q, ['mois', 'mensuel', 'ce mois'])) {
      final ca = _d(ctx.summary, 'ca_mois');
      final n = _i(ctx.summary, 'ventes_mois');
      final evo = ctx.evolutionCaMois;
      final evoTxt = evo.abs() >= 0.5
          ? ' (${evo >= 0 ? '+' : ''}${evo.toStringAsFixed(1)} % vs période précédente)'
          : '';
      return 'Ce **mois**, votre CA atteint **${_money(ca, ctx.devise)}** '
          '($n vente${n > 1 ? 's' : ''})$evoTxt.';
    }
    if (_matches(q, ['hier'])) {
      return 'Je n\'ai pas encore l\'historique détaillé d\'hier. '
          'Consultez l\'onglet **Historique** ou demandez le CA **du jour** ou **du mois**.';
    }
    final ca = _d(ctx.summary, 'ca_jour');
    final comptant = _d(ctx.summary, 'ca_comptant_jour');
    final credit = _d(ctx.summary, 'ca_credit_jour');
    final n = _i(ctx.summary, 'ventes_jour');
    if (n == 0) {
      return 'Aucune vente enregistrée **aujourd\'hui** pour l\'instant.';
    }
    return '**Aujourd\'hui**, votre chiffre d\'affaires est de **${_money(ca, ctx.devise)}** '
        '($n vente${n > 1 ? 's' : ''}) : '
        '${_money(comptant, ctx.devise)} comptant et ${_money(credit, ctx.devise)} à crédit.';
  }

  String _profit(AssistantContext ctx) {
    final benefJour = _d(ctx.summary, 'benefice_jour');
    final benefMois = _d(ctx.summary, 'benefice_mois');
    final marge = _d(ctx.summary, 'marge_mois_percent');
    return '**Bénéfice du jour** : ${_money(benefJour, ctx.devise)}.\n'
        '**Bénéfice du mois** : ${_money(benefMois, ctx.devise)} '
        '(marge de **${marge.toStringAsFixed(1)} %** sur le CA mensuel).';
  }

  String _sales(AssistantContext ctx) {
    final j = _i(ctx.summary, 'ventes_jour');
    final s = _i(ctx.summary, 'ventes_semaine');
    final m = _i(ctx.summary, 'ventes_mois');
    final comptant = _i(ctx.summary, 'ventes_comptant_jour');
    final credit = _i(ctx.summary, 'ventes_credit_jour');
    return '**Ventes aujourd\'hui** : $j ($comptant comptant, $credit crédit).\n'
        'Cette semaine : $s · Ce mois : $m.';
  }

  String _averageBasket(AssistantContext ctx) {
    final panier = _d(ctx.summary, 'panier_moyen_jour');
    if (_i(ctx.summary, 'ventes_jour') == 0) {
      return 'Pas encore de ventes aujourd\'hui — le panier moyen sera calculé après vos premières transactions.';
    }
    return 'Votre **panier moyen** aujourd\'hui est de **${_money(panier, ctx.devise)}** par transaction.';
  }

  String _credits(AssistantContext ctx) {
    final count = _i(ctx.summary, 'credits_en_cours');
    final reste = _d(ctx.summary, 'credits_reste_total');
    if (count == 0) {
      return 'Aucun **crédit en cours** — bravo, tous vos clients sont à jour !';
    }
    final buf = StringBuffer(
      'Vous avez **$count crédit${count > 1 ? 's' : ''} en cours** pour un total de '
      '**${_money(reste, ctx.devise)}** restant à encaisser.',
    );
    if (ctx.topCredits.isNotEmpty) {
      buf.writeln('\n\nPrincipaux dossiers :');
      for (final c in ctx.topCredits.take(3)) {
        final nom = c['client_nom']?.toString() ?? 'Client';
        final r = (c['reste'] as num?)?.toDouble() ?? 0;
        buf.writeln('• $nom — ${_money(r, ctx.devise)}');
      }
    }
    buf.write('\n\nRelancez depuis l\'onglet **Crédits** si nécessaire.');
    return buf.toString();
  }

  String _stockAlerts(AssistantContext ctx) {
    final rupture = _i(ctx.summary, 'stock_rupture');
    final faible = _i(ctx.summary, 'stock_faible');
    final ok = _i(ctx.summary, 'stock_ok');
    final total = _i(ctx.summary, 'total_produits');
    final alertes = List<Map<String, dynamic>>.from(ctx.summary['produits_alerte'] ?? []);

    if (total == 0) {
      return 'Votre catalogue est vide. Ajoutez des produits dans l\'onglet **Produits**.';
    }
    if (rupture == 0 && faible == 0) {
      return '**Stock sain** : $ok produit${ok > 1 ? 's' : ''} sur $total sans alerte. '
          'Continuez à surveiller les niveaux régulièrement.';
    }

    final buf = StringBuffer(
      '**État du stock** : $rupture en rupture, $faible en stock faible, $ok OK (sur $total produits).',
    );
    if (alertes.isNotEmpty) {
      buf.writeln('\n\nProduits à réapprovisionner en priorité :');
      for (final a in alertes.take(5)) {
        final nom = a['nom']?.toString() ?? 'Produit';
        final niveau = a['niveau']?.toString() == 'rupture' ? 'rupture' : 'stock faible';
        final stock = (a['stock'] as num?)?.toDouble() ?? 0;
        buf.writeln('• $nom — $niveau (${stock.toStringAsFixed(stock == stock.roundToDouble() ? 0 : 1)} restant)');
      }
    }
    return buf.toString();
  }

  String _productCount(AssistantContext ctx) {
    final total = _i(ctx.summary, 'total_produits');
    return 'Votre catalogue compte **$total produit${total > 1 ? 's' : ''}** '
        '(${_i(ctx.summary, 'stock_ok')} en stock sain).';
  }

  String _topProducts(AssistantContext ctx) {
    if (ctx.topProducts.isEmpty) {
      return 'Pas assez de ventes ce mois pour identifier un produit star. '
          'Enregistrez des ventes depuis la **Caisse**.';
    }
    final buf = StringBuffer('**Top produits** ce mois :\n');
    for (var i = 0; i < ctx.topProducts.length && i < 5; i++) {
      final p = ctx.topProducts[i];
      final nom = p['nom']?.toString() ?? 'Produit';
      final ca = (p['ca'] as num?)?.toDouble() ?? 0;
      final qty = (p['quantite'] as num?)?.toDouble() ?? 0;
      buf.writeln('${i + 1}. **$nom** — ${_money(ca, ctx.devise)} (${qty.toStringAsFixed(qty == qty.roundToDouble() ? 0 : 1)} vendus)');
    }
    final top = ctx.topProducts.first;
    final caMois = _d(ctx.summary, 'ca_mois');
    if (caMois > 0) {
      final part = ((top['ca'] as num?)?.toDouble() ?? 0) / caMois * 100;
      buf.write('\n« ${top['nom']} » représente **${part.toStringAsFixed(0)} %** de votre CA mensuel.');
    }
    return buf.toString();
  }

  String _dailyGoal(AssistantContext ctx) {
    final pct = _d(ctx.summary, 'objectif_jour_percent');
    final moyenne = _d(ctx.summary, 'ca_moyen_jour_mois');
    final ca = _d(ctx.summary, 'ca_jour');
    if (moyenne <= 0) {
      return 'Pas encore assez de données ce mois pour calculer un objectif journalier.';
    }
    final status = pct >= 100
        ? 'Objectif dépassé — excellente journée !'
        : pct >= 70
            ? 'Bonne progression, continuez ainsi.'
            : 'En dessous de votre moyenne — pensez à relancer les ventes.';
    return 'Vous êtes à **${pct.toStringAsFixed(0)} %** de votre moyenne journalière '
        '(${_money(moyenne, ctx.devise)}/jour). CA actuel : ${_money(ca, ctx.devise)}.\n$status';
  }

  String _weekSummary(AssistantContext ctx) {
    final ca = _d(ctx.summary, 'ca_semaine');
    final n = _i(ctx.summary, 'ventes_semaine');
    return '**Semaine glissante** : ${_money(ca, ctx.devise)} de CA et $n vente${n > 1 ? 's' : ''}. '
        'CA du jour : ${_money(_d(ctx.summary, 'ca_jour'), ctx.devise)}.';
  }

  String _monthlySummary(AssistantContext ctx) {
    final ca = _d(ctx.summary, 'ca_mois');
    final benef = _d(ctx.summary, 'benefice_mois');
    final marge = _d(ctx.summary, 'marge_mois_percent');
    final ventes = _i(ctx.summary, 'ventes_mois');
    final credits = _i(ctx.summary, 'credits_en_cours');
    final reste = _d(ctx.summary, 'credits_reste_total');
    final rupture = _i(ctx.summary, 'stock_rupture');

    final buf = StringBuffer('**Bilan de ${ctx.shopName}** (mois en cours)\n\n');
    buf.writeln('• CA : **${_money(ca, ctx.devise)}** ($ventes ventes)');
    if (ctx.evolutionCaMois.abs() >= 0.5) {
      final evo = ctx.evolutionCaMois;
      buf.writeln('• Évolution CA : ${evo >= 0 ? '+' : ''}${evo.toStringAsFixed(1)} % vs mois précédent');
    }
    buf.writeln('• Bénéfice : **${_money(benef, ctx.devise)}** (marge ${marge.toStringAsFixed(1)} %)');
    buf.writeln('• Crédits : $credits dossier${credits > 1 ? 's' : ''} — ${_money(reste, ctx.devise)} à recouvrer');
    buf.writeln('• Stock : $rupture rupture${_i(ctx.summary, 'stock_faible') > 0 ? ', ${_i(ctx.summary, 'stock_faible')} alertes' : ''}');

    if (ctx.topProducts.isNotEmpty) {
      buf.writeln('\nProduit star : **${ctx.topProducts.first['nom']}**');
    }

    if (_d(ctx.summary, 'ca_mois') > 0 && ctx.dayOfMonth > 0) {
      buf.writeln('\n**Projection fin de mois** : ~${_money(ctx.projectedCaEndOfMonth, ctx.devise)} '
          '(à ce rythme)');
    }

    final urgentStock = ctx.stockForecasts.where((f) => f.daysUntilRupture != null && f.daysUntilRupture! <= 7).take(1);
    if (urgentStock.isNotEmpty) {
      final f = urgentStock.first;
      buf.writeln('\n⚠ **${f.nom}** : rupture estimée dans ~${f.daysUntilRupture} jour${f.daysUntilRupture! > 1 ? 's' : ''}');
    }

    if (rupture > 0) {
      buf.write('\n\n⚠ Réapprovisionnez les produits en rupture pour ne pas perdre de ventes.');
    } else if (credits > 3) {
      buf.write('\n\n💡 Plusieurs crédits en cours — vérifiez les échéances dans l\'onglet Crédits.');
    } else if (ca > 0 && marge < 15) {
      buf.write('\n\n💡 Marge faible — revoyez vos prix d\'achat ou de vente.');
    } else {
      buf.write('\n\n✓ Activité stable. Continuez à suivre vos indicateurs quotidiennement.');
    }
    return buf.toString();
  }

  String _fallback(AssistantContext ctx) {
    if (_i(ctx.summary, 'ventes_mois') == 0 && _i(ctx.summary, 'total_produits') == 0) {
      return 'Votre boutique démarre à peine. Ajoutez des **produits**, enregistrez des **ventes**, '
          'puis demandez-moi un **bilan du mois**.';
    }
    return 'Je n\'ai pas bien compris. Essayez par exemple :\n'
        '• « Projection CA fin de mois ? »\n'
        '• « Quelle est la tendance sur 7 jours ? »\n'
        '• « Quels produits vont bientôt être en rupture ? »\n'
        '• « Fais-moi un bilan du mois »';
  }

  String _caProjection(AssistantContext ctx) {
    final caMois = _d(ctx.summary, 'ca_mois');
    if (caMois <= 0 || ctx.dayOfMonth <= 0) {
      return 'Pas assez de ventes ce mois pour établir une **projection**. '
          'Enregistrez quelques ventes puis reposez la question.';
    }
    final pace = caMois / ctx.dayOfMonth;
    final projected = ctx.projectedCaEndOfMonth;
    final remaining = ctx.daysRemainingInMonth;
    final delta = projected - caMois;

    return '**Projection CA fin de mois** (extrapolation linéaire)\n\n'
        '• CA actuel : **${_money(caMois, ctx.devise)}** (jour ${ctx.dayOfMonth}/${ctx.daysInMonth})\n'
        '• Rythme moyen : **${_money(pace, ctx.devise)}/jour**\n'
        '• **Estimation fin de mois : ~${_money(projected, ctx.devise)}**\n'
        '• Encore ~**${_money(delta, ctx.devise)}** à réaliser sur $remaining jour${remaining > 1 ? 's' : ''}\n\n'
        'Cette estimation suppose que vous conservez le même rythme qu\'en début de mois.';
  }

  String _trendAnalysis(AssistantContext ctx, String q) {
    final focusWeek = _matches(q, ['7', 'semaine', 'sept jour']) && !_matches(q, ['30', 'mois']);
    final focusMonth = _matches(q, ['30', 'mois', 'mensuel']) && !_matches(q, ['7', 'semaine']);

    final buf = StringBuffer('**Analyse des tendances**\n\n');

    void addTrend(String label, double evo, double ca) {
      final trend = AssistantPredictions.trendLabel(evo);
      final arrow = evo >= 0 ? '↑' : '↓';
      final sign = evo >= 0 ? '+' : '';
      buf.writeln('• **$label** : $trend $arrow ($sign${evo.toStringAsFixed(1)} % vs période précédente)');
      if (ca > 0) buf.writeln('  CA : ${_money(ca, ctx.devise)}');
    }

    if (!focusMonth) {
      addTrend('7 derniers jours', ctx.evolutionCaSemaine, _d(ctx.summary, 'ca_semaine'));
    }
    if (!focusWeek) {
      addTrend('30 derniers jours', ctx.evolutionCaMois, _d(ctx.summary, 'ca_mois'));
    }

    final evoRef = focusWeek ? ctx.evolutionCaSemaine : ctx.evolutionCaMois;
    if (evoRef >= 5) {
      buf.write('\n\n📈 Bonne dynamique — maintenez vos efforts commerciaux.');
    } else if (evoRef <= -5) {
      buf.write('\n\n📉 Activité en recul — vérifiez stock, prix et relancez vos clients fidèles.');
    } else {
      buf.write('\n\n➡ Activité stable — consultez vos top produits pour accélérer.');
    }
    return buf.toString();
  }

  String _stockProjection(AssistantContext ctx) {
    if (ctx.stockForecasts.isEmpty) {
      return 'Aucun produit dans le catalogue. Ajoutez des références dans **Produits**.';
    }

    final atRisk = ctx.stockForecasts
        .where((f) => f.isAlreadyOut || (f.daysUntilRupture != null && f.daysUntilRupture! <= 14))
        .toList();

    if (atRisk.isEmpty) {
      return '**Aucune rupture imminente** détectée sur les 14 prochains jours '
          '(au rythme des 7 derniers jours).\n\n'
          'Votre stock semble bien dimensionné. Continuez à surveiller les ventes rapides.';
    }

    final buf = StringBuffer('**Prévisions stock** (basées sur les ventes des 7 derniers jours)\n\n');
    for (final f in atRisk.take(6)) {
      if (f.isAlreadyOut) {
        buf.writeln('• **${f.nom}** — déjà en **rupture**');
      } else {
        final daily = f.soldLast7Days / 7;
        buf.writeln(
          '• **${f.nom}** — rupture estimée dans **~${f.daysUntilRupture} jour${f.daysUntilRupture! > 1 ? 's' : ''}** '
          '(${f.stock.toStringAsFixed(f.stock == f.stock.roundToDouble() ? 0 : 1)} en stock, '
          '~${daily.toStringAsFixed(1)}/jour vendus)',
        );
      }
    }
    buf.write('\n\nRéapprovisionnez en priorité les articles les plus urgents.');
    return buf.toString();
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e')
        .replaceAll('ê', 'e')
        .replaceAll('à', 'a')
        .replaceAll('ù', 'u')
        .replaceAll('ô', 'o')
        .replaceAll('î', 'i')
        .replaceAll('ç', 'c')
        .trim();
  }

  bool _matches(String q, List<String> keywords) =>
      keywords.any((k) => q.contains(_normalize(k)));

  double _d(Map<String, dynamic> m, String key) => (m[key] as num?)?.toDouble() ?? 0;
  int _i(Map<String, dynamic> m, String key) => (m[key] as num?)?.toInt() ?? 0;

  String _money(double v, String devise) {
    final formatted = NumberFormat('#,##0', 'fr_FR').format(v.round());
    return '$formatted $devise';
  }
}
