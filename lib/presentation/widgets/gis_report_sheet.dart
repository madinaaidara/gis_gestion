import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/services/gis_report_service.dart';
import '../../core/theme/gis_palette.dart';
import '../../core/utils/download_helper.dart';

/// Feuille d'export rapport — aperçu, copie et téléchargement CSV.
class GisReportSheet extends StatefulWidget {
  const GisReportSheet({
    super.key,
    required this.data,
    required this.periodeId,
  });

  final GisReportData data;
  final String periodeId;

  @override
  State<GisReportSheet> createState() => _GisReportSheetState();
}

class _GisReportSheetState extends State<GisReportSheet> {
  late final String _textReport;
  late final String _csvReport;
  late final String _baseName;
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _textReport = GisReportService.buildTextReport(widget.data);
    _csvReport = GisReportService.buildCsvReport(widget.data);
    _baseName = GisReportService.fileName(widget.data.shopName, widget.periodeId);
  }

  Future<void> _copy(String content, String label) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copié dans le presse-papiers'), behavior: SnackBarBehavior.floating),
    );
  }

  void _downloadCsv() {
    try {
      downloadTextFile('$_baseName.csv', _csvReport, mimeType: 'text/csv;charset=utf-8');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement CSV lancé'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      _copy(_csvReport, 'CSV');
    }
  }

  void _downloadTxt() {
    try {
      downloadTextFile('$_baseName.txt', _textReport);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Téléchargement TXT lancé'), behavior: SnackBarBehavior.floating),
      );
    } catch (_) {
      _copy(_textReport, 'Rapport');
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final content = _tab == 0 ? _textReport : _csvReport;
    final maxH = MediaQuery.sizeOf(context).height * 0.75;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Rapport · ${widget.data.periodeLabel}',
                            style: GoogleFonts.plusJakartaSans(
                              color: p.text,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.data.shopName,
                            style: TextStyle(color: p.textMute, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close_rounded, color: p.textMute),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SegmentedButton<int>(
                  segments: const [
                    ButtonSegment(value: 0, label: Text('Résumé'), icon: Icon(Icons.summarize_outlined, size: 16)),
                    ButtonSegment(value: 1, label: Text('CSV'), icon: Icon(Icons.table_chart_outlined, size: 16)),
                  ],
                  selected: {_tab},
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              const SizedBox(height: 12),
              Flexible(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.surfaceHi,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.border),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      content,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 12,
                        height: 1.45,
                        fontFamily: _tab == 1 ? 'monospace' : null,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () => _copy(_textReport, 'Rapport'),
                      icon: const Icon(Icons.copy_rounded, size: 18),
                      label: const Text('Copier'),
                      style: FilledButton.styleFrom(
                        backgroundColor: p.accent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                    if (canDownloadFile) ...[
                      OutlinedButton.icon(
                        onPressed: _downloadTxt,
                        icon: Icon(Icons.download_rounded, size: 18, color: p.text),
                        label: Text('TXT', style: TextStyle(color: p.text)),
                      ),
                      OutlinedButton.icon(
                        onPressed: _downloadCsv,
                        icon: Icon(Icons.download_rounded, size: 18, color: p.text),
                        label: Text('CSV', style: TextStyle(color: p.text)),
                      ),
                    ] else
                      OutlinedButton.icon(
                        onPressed: () => _copy(_csvReport, 'CSV'),
                        icon: Icon(Icons.copy_all_rounded, size: 18, color: p.text),
                        label: Text('Copier CSV', style: TextStyle(color: p.text)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Panneau d'accès rapide aux rapports sur la page Statistiques.
class GisReportsPanel extends StatelessWidget {
  const GisReportsPanel({
    super.key,
    required this.periodeLabel,
    required this.totalCA,
    required this.totalVentes,
    required this.devise,
    required this.onExport,
    required this.isLoading,
  });

  final String periodeLabel;
  final double totalCA;
  final int totalVentes;
  final String devise;
  final VoidCallback? onExport;
  final bool isLoading;

  String _fmt(double v) {
    if (v >= 1000000) return '${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(0)}K';
    return v.toStringAsFixed(0);
  }

  @override
  Widget build(BuildContext context) {
    final p = GisPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 520;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rapports',
          style: GoogleFonts.plusJakartaSans(
            color: p.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$periodeLabel · ${_fmt(totalCA)} $devise · $totalVentes ventes',
          style: TextStyle(color: p.textMute, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          'Exportez un rapport complet : résumé financier, CA par jour, top produits et détail des ventes.',
          style: TextStyle(color: p.textDim, fontSize: 12, height: 1.4),
        ),
      ],
    );

    final exportBtn = FilledButton.icon(
      onPressed: isLoading ? null : onExport,
      icon: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white.withValues(alpha: 0.8)),
            )
          : const Icon(Icons.file_download_outlined, size: 18),
      label: Text(isLoading ? '…' : 'Exporter'),
      style: FilledButton.styleFrom(
        backgroundColor: p.accent,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        visualDensity: VisualDensity.compact,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.accent.withValues(alpha: 0.12),
            p.surface,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.accent.withValues(alpha: 0.25)),
      ),
      child: narrow
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: p.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.assessment_rounded, color: p.accent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: info),
                  ],
                ),
                const SizedBox(height: 12),
                exportBtn,
              ],
            )
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.assessment_rounded, color: p.accent, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(child: info),
                const SizedBox(width: 8),
                exportBtn,
              ],
            ),
    );
  }
}
