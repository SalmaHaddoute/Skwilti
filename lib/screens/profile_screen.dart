import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user.dart';
import '../widgets/skwilti_logo.dart';
import 'edit_profile_screen.dart';
import 'premium_screen.dart';
import 'complaint_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    if (user == null) return const SizedBox.shrink();
    final roleColor = _roleColor(user.role);
    final initials = '${user.firstName.isNotEmpty ? user.firstName[0] : ''}${user.lastName.isNotEmpty ? user.lastName[0] : ''}'.toUpperCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Mon profil', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.text,
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
            ),
            child: Column(children: [
              const SizedBox(height: 20),
              // Avatar
              Container(
                width: 88, height: 88,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  boxShadow: [BoxShadow(color: roleColor.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/teacher-illustration.webp',
                    width: 88,
                    height: 88,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(
                        child: Text(
                          initials,
                          style: GoogleFonts.nunito(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(user.fullName, style: GoogleFonts.nunito(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.text)),
              const SizedBox(height: 4),
              Text(user.email, style: GoogleFonts.nunito(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(color: roleColor.withOpacity(0.12), borderRadius: BorderRadius.circular(20)),
                child: Text(_roleLabel(user.role), style: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.w800, color: roleColor)),
              ),
            ]),
          ),
          // Status
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      LucideIcons.crown,
                      size: 20,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Plan actuel',
                          style: GoogleFonts.nunito(
                            fontSize: 12,
                            color: AppColors.textSub,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.subscription.name.toUpperCase(),
                          style: GoogleFonts.nunito(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.subscription == SubscriptionType.premium 
                          ? AppColors.warning.withOpacity(0.1)
                          : AppColors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.subscription == SubscriptionType.premium ? 'PREMIUM' : 'GRATUIT',
                      style: GoogleFonts.nunito(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: user.subscription == SubscriptionType.premium 
                            ? AppColors.warning
                            : AppColors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Menu items
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(children: [
              _MenuItem(LucideIcons.user, 'Modifier le profil', AppColors.primary, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
              }),
              _MenuItem(LucideIcons.bell, 'Notifications', AppColors.info, () {}),
              _MenuItem(LucideIcons.award, 'Passer à Premium', AppColors.warning, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
              }),
              _MenuItem(LucideIcons.settings, 'Paramètres n8n', AppColors.textSub, () => _showN8nDialog(context)),
              _MenuItem(LucideIcons.messageSquare, 'Déposer une réclamation', AppColors.error, () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen()));
              }),
              _MenuItem(LucideIcons.logOut, 'Se déconnecter', AppColors.error,
                () async { await context.read<AppState>().logout(); if (context.mounted) Navigator.pop(context); }),
            ]),
          ),
          const SizedBox(height: 32),
          const SkwiltiLogo(height: 24),
          const SizedBox(height: 8),
          Text('v1.0.0', style: GoogleFonts.nunito(fontSize: 11, color: AppColors.textSub)),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }

  void _showN8nDialog(BuildContext context) {
    final ctrl = TextEditingController(text: context.read<AppState>().n8nUrl);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('URL n8n', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(labelText: 'Webhook URL', prefixIcon: Icon(LucideIcons.link, size: 16)),
          style: GoogleFonts.nunito(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () { context.read<AppState>().setN8nUrl(ctrl.text.trim()); Navigator.pop(context); },
            child: const Text('Sauvegarder'),
          ),
        ],
      ),
    );
  }

  void _showSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Aide & Support', style: GoogleFonts.nunito(fontWeight: FontWeight.w800)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comment pouvons-nous vous aider ?', style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 16),
            _SupportOption(
              icon: LucideIcons.crown,
              title: 'Passer au Premium',
              description: 'Débloquez toutes les fonctionnalités premium',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
              },
            ),
            const SizedBox(height: 12),
            _SupportOption(
              icon: LucideIcons.messageSquare,
              title: 'Déposer une réclamation',
              description: 'Contactez notre équipe d\'administration',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen()));
              },
            ),
            const SizedBox(height: 12),
            _SupportOption(
              icon: LucideIcons.mail,
              title: 'Contacter le support',
              description: 'support@skwilti.com',
              onTap: () {
                // Ouvrir le client email
              },
            ),
            const SizedBox(height: 12),
            _SupportOption(
              icon: LucideIcons.bookOpen,
              title: 'Centre d\'aide',
              description: 'Consultez notre documentation',
              onTap: () {
                // Ouvrir la documentation
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer')),
        ],
      ),
    );
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.teacher: return AppColors.primary;
      case UserRole.student: return AppColors.green;
      case UserRole.parent:  return const Color(0xFF9B59B6);
      case UserRole.admin:   return const Color(0xFF2980B9);
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.teacher: return 'Enseignant';
      case UserRole.student: return 'Étudiant';
      case UserRole.parent:  return 'Parent';
      case UserRole.admin:   return 'Administrateur';
    }
  }
}

class _SupportOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;
  
  const _SupportOption({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 20,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: AppColors.textSub,
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String v, l; final Color c;
  const _StatBox(this.v, this.l, this.c);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
    child: Column(children: [
      Text(v, style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w900, color: c)),
      const SizedBox(height: 2),
      Text(l, style: GoogleFonts.nunito(fontSize: 10, color: AppColors.textSub, fontWeight: FontWeight.w600)),
    ]),
  ));
}

class _MenuItem extends StatelessWidget {
  final IconData icon; final String label; final Color color; final VoidCallback onTap;
  const _MenuItem(this.icon, this.label, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    child: ListTile(
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, size: 17, color: color)),
      title: Text(label, style: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.text)),
      trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSub),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border, width: 0.5)),
      tileColor: Colors.white,
      onTap: onTap,
    ),
  );
}
