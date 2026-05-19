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
    final isPremium = user.subscription == SubscriptionType.premium;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        title: Text(
          'Mon profil',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.text,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.text),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: false,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header Profile Info ──────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  // Avatar with Premium Ring
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      if (isPremium)
                        Container(
                          width: 104,
                          height: 104,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Colors.amber, Colors.orange, Colors.yellow],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                        ),
                      Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          color: roleColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [
                            BoxShadow(
                              color: roleColor.withOpacity(0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            )
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/teacher-illustration.webp',
                            width: 96,
                            height: 96,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Text(
                                  initials,
                                  style: GoogleFonts.inter(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      if (isPremium)
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: const BoxDecoration(
                              color: Colors.amber,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                )
                              ],
                            ),
                            child: const Icon(
                              LucideIcons.crown,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Full Name
                  Text(
                    user.fullName,
                    style: GoogleFonts.inter(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  
                  // Email
                  Text(
                    user.email,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSub,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Role Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: roleColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: roleColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _roleLabel(user.role),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: roleColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Premium Status Banner ────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isPremium
                      ? const LinearGradient(
                          colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [AppColors.primary, AppColors.primary2],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: (isPremium ? const Color(0xFF1E3C72) : AppColors.primary).withOpacity(0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        isPremium ? LucideIcons.crown : LucideIcons.zap,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isPremium ? 'Membre Premium' : 'Formule Gratuite',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isPremium 
                                ? 'Accès illimité débloqué' 
                                : 'Passez au niveau supérieur',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isPremium)
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppColors.primary,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        child: Text(
                          'Activer',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withOpacity(0.5), width: 0.5),
                        ),
                        child: Text(
                          'ACTIF',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ── Menu Options ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildMenuItem(
                    icon: LucideIcons.user,
                    label: 'Modifier le profil',
                    color: AppColors.primary,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfileScreen()));
                    },
                  ),
                  if (!isPremium)
                    _buildMenuItem(
                      icon: LucideIcons.award,
                      label: 'Passer à Premium',
                      color: AppColors.warning,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const PremiumScreen()));
                      },
                    ),
                  _buildMenuItem(
                    icon: LucideIcons.messageSquare,
                    label: 'Déposer une réclamation',
                    color: AppColors.error,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ComplaintScreen()));
                    },
                  ),
                  const SizedBox(height: 12),
                  // Log Out
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(LucideIcons.logOut, size: 17, color: Colors.red.shade600),
                      ),
                      title: Text(
                        'Se déconnecter',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.red.shade600,
                        ),
                      ),
                      trailing: Icon(LucideIcons.chevronRight, size: 16, color: Colors.red.shade300),
                      onTap: () async {
                        await context.read<AppState>().logout();
                        if (context.mounted) Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            const SkwiltiLogo(height: 24),
            const SizedBox(height: 8),
            Text(
              'Version 1.0.0',
              style: GoogleFonts.nunito(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textSub,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 17, color: color),
        ),
        title: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.text,
          ),
        ),
        trailing: const Icon(LucideIcons.chevronRight, size: 16, color: AppColors.textSub),
        onTap: onTap,
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
