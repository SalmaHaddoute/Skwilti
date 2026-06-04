import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class SkwBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const SkwBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(icon: LucideIcons.home, label: 'Accueil'),
      _NavItem(icon: LucideIcons.upload, label: 'Upload'),
      _NavItem(icon: LucideIcons.bookOpen, label: 'Cours'),
      _NavItem(icon: LucideIcons.user, label: 'Profil'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = e.key == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(e.key),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isActive)
                    Container(
                      width: 4,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 3),
                      decoration: const BoxDecoration(
                        color: AppColors.orange,
                        shape: BoxShape.circle,
                      ),
                    )
                  else
                    const SizedBox(height: 7),
                  Icon(
                    e.value.icon,
                    size: 20,
                    color: isActive ? AppColors.orange : AppColors.textSub,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.label,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.orange : AppColors.textSub,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  _NavItem({required this.icon, required this.label});
}
