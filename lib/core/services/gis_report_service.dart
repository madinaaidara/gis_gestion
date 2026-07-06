import 'package:intl/intl.dart';

/// Données agrégées pour générer un rapport boutique.
class GisReportData {
  const GisReportData({
    required this.shopName,
    required this.devise,
    required this.periodeLabel,
    required this.totalCA,
    required this.evolutionCA,
    required this.totalVentes,
    required this.evolutionVentes,
    required this.beneficeTotal,
    required this.evolutionBenefice,
    required this.margePercent,
    required this.totalClients,
    required this.panierMoyen,
    required this.caComptant,
    required this.caCredit,
    required this.tauxCredits,
    required this.chartData,
    required this.topProducts,
    required this.ventesDetail,
  });

  final String shopName;
  final String devise;
  final String periodeLabel;
  final double totalCA;
  final double evolutionCA;
  final int totalVentes;
  final double evolutionVentes;
  final double beneficeTotal;
  final double evolutionBenefice;
  final double margePercent;
  final int totalClients;
  final double panierMoyen;
  final double caComptant;
  final double caCredit;
  final double tauxCredits;
  final List<Map<String, dynamic>> chartData;
  final List<Map<String, dynamic>> topProducts;
  final List<Map<String, dynamic>> ventesDetail;
}

/// Génère rapports texte et CSV à partir des stats réelles.
abstract final class GisReportService {
  static final _money = NumberFormat('#,##0', 'fr_FR');
  static final _dateTime = DateFormat('dd/MM/yyyy HH:mm', 'fr_FR');
  static final _dateShort = DateFormat('dd/MM/yyyy', 'fr_FR');

  static String _fmtMoney(double v, String devise) => '${_money.format(v.round())} $devise';

  static String _fmtTrend(double evo) => '${evo >= 0 ? '+' : ''}${evo.toStringAsFixed(1)} %';

  static String buildTextReport(GisReportData data) {
    final buf = StringBuffer();
    final sep = '═' * 44;
    final line = '─' * 44;

    buf.writeln(sep);
    buf.writeln('  RAPPORT Gis Gestion');
    buf.writeln('  ${data.shopName}');
    buf.writeln('  Période : ${data.periodeLabel}');
    buf.writeln('  Généré le ${_dateTime.format(DateTime.now())}');
    buf.writeln(sep);
    buf.writeln();

    buf.writeln('RÉSUMÉ FINANCIER');
    buf.writeln(line);
    buf.writeln('Chiffre d\'affaires  : ${_fmtMoney(data.totalCA, data.devise)} (${_fmtTrend(data.evolutionCA)})');
    buf.writeln('Nombre de ventes      : ${data.totalVentes} (${_fmtTrend(data.evolutionVentes)})');
    buf.writeln('Bénéfice net          : ${_fmtMoney(data.beneficeTotal, data.devise)} (${_fmtTrend(data.evolutionBenefice)})');
    buf.writeln('Marge nette           : ${data.margePercent.toStringAsFixed(1)} %');
    buf.writeln('Clients uniques       : ${data.totalClients}');
    buf.writeln('Panier moyen          : ${_fmtMoney(data.panierMoyen, data.devise)}');
    buf.writeln('CA comptant           : ${_fmtMoney(data.caComptant, data.devise)}');
    buf.writeln('CA crédit             : ${_fmtMoney(data.caCredit, data.devise)} (${data.tauxCredits.toStringAsFixed(0)} % des ventes)');
    buf.writeln();

    if (data.chartData.isNotEmpty) {
      buf.writeln('CA PAR JOUR');
      buf.writeln(line);
      for (final row in data.chartData) {
        final date = row['date']?.toString() ?? '';
        final total = (row['total'] as num?)?.toDouble() ?? 0.0;
        final label = date.length >= 10 ? _dateShort.format(DateTime.parse(date)) : date;
        buf.writeln('$label — ${_fmtMoney(total, data.devise)}');
      }
      buf.writeln();
    }

    if (data.topProducts.isNotEmpty) {
      buf.writeln('TOP PRODUITS');
      buf.writeln(line);
      for (var i = 0; i < data.topProducts.length; i++) {
        final p = data.topProducts[i];
        final nom = p['nom']?.toString() ?? 'Produit';
        final qty = (p['quantite'] as num?)?.toDouble() ?? 0.0;
        final ca = (p['ca'] as num?)?.toDouble() ?? 0.0;
        final part = data.totalCA > 0 ? (ca / data.totalCA * 100) : 0.0;
        buf.writeln('${i + 1}. $nom — ${qty.toStringAsFixed(0)} u. — ${_fmtMoney(ca, data.devise)} (${part.toStringAsFixed(0)} %)');
      }
      buf.writeln();
    }

    if (data.ventesDetail.isNotEmpty) {
      buf.writeln('DÉTAIL DES VENTES (${data.ventesDetail.length})');
      buf.writeln(line);
      for (final v in data.ventesDetail) {
        final dateRaw = v['date_vente']?.toString() ?? '';
        final date = dateRaw.isNotEmpty
            ? _dateShort.format(DateTime.tryParse(dateRaw) ?? DateTime.now())
            : '—';
        final client = v['client_nom']?.toString() ?? 'Client';
        final produit = v['nom_produit']?.toString() ?? '—';
        final total = (v['total'] as num?)?.toDouble() ?? 0.0;
        final benefice = (v['benefice_reel'] as num?)?.toDouble() ?? 0.0;
        final type = v['est_credit'] == true ? 'Crédit' : 'Comptant';
        buf.writeln('$date | $type | $client | $produit');
        buf.writeln('         Total ${_fmtMoney(total, data.devise)} · Bénéfice ${_fmtMoney(benefice, data.devise)}');
      }
    } else {
      buf.writeln('Aucune vente enregistrée sur cette période.');
    }

    buf.writeln();
    buf.writeln(sep);
    buf.writeln('  Gis Gestion — Rapport automatique');
    buf.writeln(sep);
    return buf.toString();
  }

  static String buildCsvReport(GisReportData data) {
    final buf = StringBuffer();
    void row(List<String> cells) => buf.writeln(cells.map(_csvCell).join(';'));

    row(['Rapport Gis Gestion']);
    row(['Boutique', data.shopName]);
    row(['Période', data.periodeLabel]);
    row(['Généré le', _dateTime.format(DateTime.now())]);
    row([]);

    row(['Indicateur', 'Valeur', 'Évolution']);
    row(['Chiffre d\'affaires', _fmtMoney(data.totalCA, data.devise), _fmtTrend(data.evolutionCA)]);
    row(['Ventes', '${data.totalVentes}', _fmtTrend(data.evolutionVentes)]);
    row(['Bénéfice net', _fmtMoney(data.beneficeTotal, data.devise), _fmtTrend(data.evolutionBenefice)]);
    row(['Marge %', '${data.margePercent.toStringAsFixed(1)} %', '']);
    row(['Clients uniques', '${data.totalClients}', '']);
    row(['Panier moyen', _fmtMoney(data.panierMoyen, data.devise), '']);
    row(['CA comptant', _fmtMoney(data.caComptant, data.devise), '']);
    row(['CA crédit', _fmtMoney(data.caCredit, data.devise), '${data.tauxCredits.toStringAsFixed(0)} %']);
    row([]);

    if (data.chartData.isNotEmpty) {
      row(['Date', 'CA']);
      for (final r in data.chartData) {
        row([r['date']?.toString() ?? '', _fmtMoney((r['total'] as num?)?.toDouble() ?? 0, data.devise)]);
      }
      row([]);
    }

    if (data.topProducts.isNotEmpty) {
      row(['Produit', 'Quantité', 'CA']);
      for (final p in data.topProducts) {
        row([
          p['nom']?.toString() ?? '',
          '${(p['quantite'] as num?)?.toDouble() ?? 0}',
          _fmtMoney((p['ca'] as num?)?.toDouble() ?? 0, data.devise),
        ]);
      }
      row([]);
    }

    if (data.ventesDetail.isNotEmpty) {
      row(['Date', 'Type', 'Client', 'Produits', 'Total', 'Bénéfice']);
      for (final v in data.ventesDetail) {
        row([
          v['date_vente']?.toString().substring(0, 10) ?? '',
          v['est_credit'] == true ? 'Crédit' : 'Comptant',
          v['client_nom']?.toString() ?? '',
          v['nom_produit']?.toString() ?? '',
          '${(v['total'] as num?)?.toDouble() ?? 0}',
          '${(v['benefice_reel'] as num?)?.toDouble() ?? 0}',
        ]);
      }
    }

    return buf.toString();
  }

  static String _csvCell(String value) {
    if (value.contains(';') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  static String fileName(String shopName, String periode) {
    final safe = shopName.replaceAll(RegExp(r'[^\w\s-]'), '').trim().replaceAll(' ', '_');
    final date = DateFormat('yyyyMMdd').format(DateTime.now());
    return 'rapport_${safe.isEmpty ? 'gis' : safe}_${periode}_$date';
  }
}
