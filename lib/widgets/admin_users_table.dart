import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminUsersTable extends StatelessWidget {
  const AdminUsersTable({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Utilisateurs récents',
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 16),
          _UsersTable(),
        ],
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<UserData> _users = [
    UserData(
      name: 'Amira Benali',
      email: 'amira.benali@email.com',
      role: 'Étudiant',
      status: 'Actif',
      avatar: 'AB',
      joinDate: '15 Avr 2024',
      subscription: 'Premium',
    ),
    UserData(
      name: 'Prof. Fatima Z.',
      email: 'fatima.zahra@ecole.fr',
      role: 'Enseignant',
      status: 'Actif',
      avatar: 'FZ',
      joinDate: '10 Avr 2024',
      subscription: 'Premium',
    ),
    UserData(
      name: 'Youssef M.',
      email: 'youssef.mohamed@email.com',
      role: 'Étudiant',
      status: 'Actif',
      avatar: 'YM',
      joinDate: '08 Avr 2024',
      subscription: 'Gratuit',
    ),
    UserData(
      name: 'Sara K.',
      email: 'sara.karim@email.com',
      role: 'Étudiant',
      status: 'Inactif',
      avatar: 'SK',
      joinDate: '05 Avr 2024',
      subscription: 'Gratuit',
    ),
    UserData(
      name: 'Parent Karim',
      email: 'karim.parent@email.com',
      role: 'Parent',
      status: 'Actif',
      avatar: 'KP',
      joinDate: '02 Avr 2024',
      subscription: 'Premium',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header du tableau
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'Utilisateur',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  'Email',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Rôle',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Statut',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Abonnement',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSub,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Lignes du tableau
        ..._users.map((user) => _UserRow(user: user)).toList(),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final UserData user;

  const _UserRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      user.avatar,
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.text,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        user.joinDate,
                        style: GoogleFonts.nunito(
                          fontSize: 10,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              user.email,
              style: GoogleFonts.nunito(
                fontSize: 11,
                color: AppColors.textSub,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(user.role).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.role,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: _getRoleColor(user.role),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: user.status == 'Actif' ? AppColors.success : AppColors.error,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  user.status,
                  style: GoogleFonts.nunito(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: user.status == 'Actif' ? AppColors.success : AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: user.subscription == 'Premium' 
                    ? AppColors.primary.withOpacity(0.1) 
                    : AppColors.textSub.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                user.subscription,
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: user.subscription == 'Premium' 
                      ? AppColors.primary 
                      : AppColors.textSub,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'Étudiant':
        return AppColors.success;
      case 'Enseignant':
        return AppColors.primary;
      case 'Parent':
        return AppColors.warning;
      default:
        return AppColors.textSub;
    }
  }
}

class UserData {
  final String name;
  final String email;
  final String role;
  final String status;
  final String avatar;
  final String joinDate;
  final String subscription;

  const UserData({
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.avatar,
    required this.joinDate,
    required this.subscription,
  });
}
