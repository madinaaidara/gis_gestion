import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../data/repositories/abonnement_repository.dart';
import '../../../data/repositories/shops_repository.dart';

/// Gestion abonnement / licence Gis Gestion.
class AbonnementPage extends StatefulWidget {
  final bool blocking;

  const AbonnementPage({super.key, this.blocking = false});

  @override
  State<AbonnementPage> createState() => _AbonnementPageState();
}

class _AbonnementPageState extends State<AbonnementPage> {
  static const Color _bg = Color(0xFF050505);
  static const Color _surface = Color(0xFF0E0E10);
  static const Color _surfaceHi = Color(0xFF161618);
  static const Color _border = Color(0xFF222226);
  static const Color _text = Color(0xFFF5F5F7);
  static const Color _mute = Color(0xFF8A8A92);
  static const Color _accent = Color(0xFF7C5CFF);
  static const Color _success = Color(0xFF22C55E);
  static const Color _danger = Color(0xFFFF4D6D);

  final _codeController = TextEditingController();
  bool _activating = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _activate() async {
    final shopId = context.read<ShopsRepository>().currentShop?.id;
    if (shopId == null) return;

    setState(() => _activating = true);
    HapticFeedback.lightImpact();

    final result = await context.read<AbonnementRepository>().activerLicence(
          shopId,
          _codeController.text,
        );

    if (!mounted) return;
    setState(() => _activating = false);

    if (result.success) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Licence activée avec succès !'), backgroundColor: _surfaceHi),
      );
      if (widget.blocking) Navigator.of(context).pop(true);
    } else {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Code invalide ou déjà utilisé'),
          backgroundColor: _danger,
        ),
      );
    }
  }

  Future<void> _contactSupport() async {
    final uri = Uri.parse('mailto:support@gisgestion.app?subject=Abonnement%20Gis%20Gestion');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final aboRepo = context.watch<AbonnementRepository>();
    final abo = aboRepo.currentAbonnement;
    final valid = abo?.isValid ?? false;

    return PopScope(
      canPop: !widget.blocking || valid,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          backgroundColor: _bg,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          leading: widget.blocking && !valid
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: _text),
                  onPressed: () => Navigator.of(context).pop(),
                ),
          title: Text(
            'Abonnement',
            style: GoogleFonts.plusJakartaSans(color: _text, fontWeight: FontWeight.w700),
          ),
        ),
        body: aboRepo.isLoading
            ? const Center(child: CircularProgressIndicator(color: _accent))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.blocking && !valid) _buildExpiredBanner(),
                    _buildStatusCard(abo, valid),
                    const SizedBox(height: 20),
                    _buildPlansSection(),
                    const SizedBox(height: 24),
                    _buildActivationCard(),
                    const SizedBox(height: 24),
                    _buildSupportCard(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildExpiredBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _danger.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _danger.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_clock_rounded, color: _danger),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Votre abonnement a expiré. Activez une licence pour continuer.',
              style: GoogleFonts.plusJakartaSans(color: _text, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(abo, bool valid) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: valid
              ? [_accent.withValues(alpha: 0.25), _surfaceHi]
              : [_danger.withValues(alpha: 0.15), _surfaceHi],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(valid ? Icons.verified_rounded : Icons.warning_amber_rounded,
                  color: valid ? _success : _danger),
              const SizedBox(width: 8),
              Text(
                valid ? 'Licence active' : 'Licence expirée',
                style: GoogleFonts.plusJakartaSans(
                  color: _text,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (abo != null) ...[
            Text('Plan : ${abo.planLabel}', style: const TextStyle(color: _mute, fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              valid ? '${abo.daysRemaining} jour(s) restant(s)' : 'Renouvelez pour débloquer l\'accès',
              style: TextStyle(color: valid ? _success : _danger, fontWeight: FontWeight.w600),
            ),
          ] else
            const Text('Aucun abonnement trouvé', style: TextStyle(color: _mute)),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Nos offres', style: GoogleFonts.plusJakartaSans(color: _text, fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        _planTile('Essai', '30 jours gratuits à l\'inscription', '0 FCFA', Icons.star_outline_rounded),
        _planTile('Pro', 'Caisse, stock, stats illimités', '9 900 FCFA/mois', Icons.workspace_premium_outlined, highlight: true),
        _planTile('Annuel', '2 mois offerts', '99 000 FCFA/an', Icons.calendar_month_outlined),
      ],
    );
  }

  Widget _planTile(String title, String desc, String price, IconData icon, {bool highlight = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? _accent.withValues(alpha: 0.12) : _surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: highlight ? _accent.withValues(alpha: 0.4) : _border),
      ),
      child: Row(
        children: [
          Icon(icon, color: highlight ? _accent : _mute),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 15)),
                Text(desc, style: const TextStyle(color: _mute, fontSize: 12)),
              ],
            ),
          ),
          Text(price, style: TextStyle(color: highlight ? _accent : _mute, fontSize: 11, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildActivationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: _border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Activer votre code', style: GoogleFonts.plusJakartaSans(color: _text, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Chaque code ne fonctionne qu\'une seule fois. '
            'Recevez le vôtre après paiement (Wave, Orange Money, virement).',
            style: TextStyle(color: _mute, fontSize: 11, height: 1.4),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _codeController,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(color: _text, letterSpacing: 1.2),
            decoration: InputDecoration(
              hintText: 'GIS-XXXX-XXXX',
              hintStyle: TextStyle(color: _mute.withValues(alpha: 0.5)),
              filled: true,
              fillColor: _surfaceHi,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _activating ? null : _activate,
            style: FilledButton.styleFrom(
              backgroundColor: _accent,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: _activating
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text('Activer la licence', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportCard() {
    return OutlinedButton.icon(
      onPressed: _contactSupport,
      style: OutlinedButton.styleFrom(
        foregroundColor: _text,
        side: const BorderSide(color: _border),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.mail_outline_rounded, size: 18),
      label: const Text('Contacter le support commercial'),
    );
  }
}
