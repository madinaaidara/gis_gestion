import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart' as th;

/// ============================================
/// PROFIL PAGE - Guiss Gestion
/// ============================================
/// Page de profil utilisateur avec données Supabase
/// ============================================

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  // Données utilisateur
  String _userName = 'Utilisateur';
  String _userEmail = '';
  String? _userPhone;
  String? _shopName;
  String? _shopAddress;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        final email = currentUser.email ?? '';

        // Récupérer le profil
        String nom = email.split('@').first;
        String? phone;
        try {
          final profileResponse = await Supabase.instance.client
              .from('profiles')
              .select('full_name, phone')
              .eq('id', currentUser.id)
              .maybeSingle();

          if (profileResponse != null) {
            nom = profileResponse['full_name'] ?? nom;
            phone = profileResponse['phone'];
          }
        } catch (e) {
          debugPrint('Erreur profil: $e');
        }

        // Récupérer la boutique
        String? boutique;
        String? adresse;
        try {
          final shopResponse = await Supabase.instance.client
              .from('shops')
              .select('nom, address')
              .eq('owner_id', currentUser.id)
              .maybeSingle();

          if (shopResponse != null) {
            boutique = shopResponse['nom'];
            adresse = shopResponse['address'];
          }
        } catch (e) {
          debugPrint('Erreur boutique: $e');
        }

        setState(() {
          _userName = nom;
          _userEmail = email;
          _userPhone = phone;
          _shopName = boutique;
          _shopAddress = adresse;
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Erreur chargement: $e');
      setState(() => _isLoading = false);
    }
  }

  String _getInitiales() {
    if (_userName.isEmpty) return 'U';
    final parties = _userName.trim().split(' ');
    if (parties.length >= 2) {
      return '${parties[0][0]}${parties[1][0]}'.toUpperCase();
    }
    return _userName[0].toUpperCase();
  }

  Future<void> _deconnecter() async {
    final confirmer = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Déconnexion'),
        content: const Text('Voulez-vous vraiment vous déconnecter ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: th.AppColors.danger),
            child: const Text('Déconnexion', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmer == true) {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: th.AppColors.background,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : LayoutBuilder(
                builder: (context, constraints) {
                  final isSmall = constraints.maxWidth < 400;

                  return SingleChildScrollView(
                    padding: EdgeInsets.all(isSmall ? 16 : 24),
                    child: Column(
                      children: [
                        // Header
                        _buildHeader(isSmall),
                        const SizedBox(height: 24),
                        // Infos utilisateur
                        _buildUserCard(isSmall),
                        const SizedBox(height: 16),
                        // Infos boutique
                        if (_shopName != null) ...[
                          _buildShopCard(isSmall),
                          const SizedBox(height: 16),
                        ],
                        // Actions
                        _buildActionsCard(isSmall),
                        const SizedBox(height: 24),
                        // Déconnexion
                        _buildDeconnexionBtn(isSmall),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildHeader(bool isSmall) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2E), Color(0xFF2D2D44)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Avatar
          Container(
            width: isSmall ? 80 : 100,
            height: isSmall ? 80 : 100,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: th.AppColors.primaryViolet.withOpacity(0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: Text(
                _getInitiales(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isSmall ? 32 : 40,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 20 : 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: isSmall ? 13 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: th.AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_outline, color: th.AppColors.primaryViolet, size: 20),
              const SizedBox(width: 8),
              Text(
                'Informations personnelles',
                style: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: th.AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email_outlined, 'Email', _userEmail, isSmall),
          if (_userPhone != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.phone_outlined, 'Téléphone', _userPhone!, isSmall),
          ],
        ],
      ),
    );
  }

  Widget _buildShopCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: th.AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store_outlined, color: th.AppColors.primaryGreen, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ma boutique',
                style: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: th.AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.badge_outlined, 'Nom', _shopName ?? '-', isSmall),
          if (_shopAddress != null) ...[
            const SizedBox(height: 12),
            _buildInfoRow(Icons.location_on_outlined, 'Adresse', _shopAddress!, isSmall),
          ],
        ],
      ),
    );
  }

  Widget _buildActionsCard(bool isSmall) {
    return Container(
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: th.AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.settings_outlined, color: th.AppColors.textSecondary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Actions',
                style: TextStyle(
                  fontSize: isSmall ? 14 : 16,
                  fontWeight: FontWeight.bold,
                  color: th.AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionItem(Icons.edit_outlined, 'Modifier mon profil', isSmall, () {
            // TODO: Modifier profil
          }),
          _buildActionItem(Icons.notifications_outlined, 'Notifications', isSmall, () {
            // TODO: Notifications
          }),
          _buildActionItem(Icons.help_outline, 'Aide et support', isSmall, () {
            // TODO: Aide
          }),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, bool isSmall) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: th.AppColors.primaryViolet.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: th.AppColors.primaryViolet, size: 16),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isSmall ? 11 : 12,
                  color: th.AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: isSmall ? 13 : 14,
                  fontWeight: FontWeight.w600,
                  color: th.AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionItem(IconData icon, String label, bool isSmall, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: th.AppColors.primaryIndigo.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: th.AppColors.primaryIndigo, size: 16),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: isSmall ? 13 : 14,
                    color: th.AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: th.AppColors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeconnexionBtn(bool isSmall) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _deconnecter,
        style: ElevatedButton.styleFrom(
          backgroundColor: th.AppColors.danger,
          padding: EdgeInsets.symmetric(vertical: isSmall ? 14 : 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: const Icon(Icons.logout, color: Colors.white),
        label: Text(
          'Se déconnecter',
          style: TextStyle(
            fontSize: isSmall ? 14 : 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}