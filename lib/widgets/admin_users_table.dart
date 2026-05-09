import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class AdminUsersTable extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  
  const AdminUsersTable({super.key, required this.users});

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
          _UsersTable(users: users),
        ],
      ),
    );
  }
}

class _UsersTable extends StatelessWidget {
  final List<Map<String, dynamic>> users;

  const _UsersTable({required this.users});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: Text('Aucun utilisateur récent')),
      );
    }
    
    // Ne prendre que les 5 plus récents
    final recentUsers = users.take(5).toList();

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
        ...recentUsers.map((user) {
          final roleMap = {
            'student': 'Étudiant',
            'teacher': 'Enseignant',
            'parent': 'Parent',
            'admin': 'Admin',
          };
          final role = roleMap[user['role']] ?? 'Utilisateur';
          
          final firstName = user['first_name'] as String? ?? '';
          final lastName = user['last_name'] as String? ?? '';
          final fullName = ('$firstName $lastName').trim();
          final displayName = fullName.isNotEmpty ? fullName : (user['email'] as String? ?? 'Inconnu');
          final names = displayName.split(' ');
          final initials = names.length > 1 
              ? '${names[0][0]}${names[1][0]}'.toUpperCase()
              : displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'U';

          // Format date (très simple pour l'exemple)
          String joinDate = 'Récent';
          if (user['created_at'] != null) {
            final date = DateTime.tryParse(user['created_at']);
            if (date != null) {
              joinDate = '${date.day}/${date.month}/${date.year}';
            }
          }

          return _UserRow(
            user: UserData(
              name: displayName,
              email: user['email'] as String? ?? 'N/A',
              role: role,
              status: 'Actif',
              avatar: initials,
              joinDate: joinDate,
              subscription: user['subscription'] == 'premium' ? 'Premium' : 'Gratuit',
            ),
          );
        }).toList(),
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
