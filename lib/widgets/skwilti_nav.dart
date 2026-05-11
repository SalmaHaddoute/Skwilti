import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user.dart';
import 'skwilti_logo.dart';

// ══════════════════════════════════════════════════
//  SKWILTI TOP APP BAR  (logo + title + notif + avatar)
// ══════════════════════════════════════════════════
class SkwiltiTopNav extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showLogo;
  final bool showNotifications;
  final String? profileIllustration;
  final VoidCallback? onProfileTap;
  final List<Widget>? extraActions;
  final Widget? leading;

  const SkwiltiTopNav({
    super.key,
    required this.title,
    this.showLogo = false,
    this.showNotifications = true,
    this.profileIllustration,
    this.onProfileTap,
    this.extraActions,
    this.leading,
  });

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AppState>().currentUser;
    return Container(
      height: preferredSize.height,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              if (showLogo)
                const SkwiltiLogo(height: 28)
              else
                Text(title, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
              const Spacer(),
              if (extraActions != null) ...extraActions!,
              if (showNotifications) ...[
                const SizedBox(width: 4),
                _NotificationBell(),
              ],
              const SizedBox(width: 6),
              if (user != null)
                GestureDetector(
                  onTap: onProfileTap,
                  child: _ProfileChip(user: user, profileIllustration: profileIllustration),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Notification Bell with badge ──────────────────
class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> with SingleTickerProviderStateMixin {
  int _count = 3;
  late AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }
  @override
  void dispose() { _shake.dispose(); super.dispose(); }

  void _open() {
    _shake.forward().then((_) => _shake.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(onClose: () { setState(() => _count = 0); Navigator.pop(context); }),
    ).then((_) => setState(() => _count = 0));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedBuilder(
            animation: _shake,
            builder: (_, child) => Transform.rotate(
              angle: _shake.value * 0.3 * ((_shake.value < 0.5) ? 1 : -1),
              child: child,
            ),
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border, width: 0.5),
              ),
              child: const Icon(LucideIcons.bell, size: 16, color: AppColors.text),
            ),
          ),
          if (_count > 0)
            Positioned(
              top: -3, right: -3,
              child: Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text('$_count', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Profile chip (avatar + name) ─────────────────
class _ProfileChip extends StatelessWidget {
  final User user;
  final String? profileIllustration;
  const _ProfileChip({super.key, required this.user, this.profileIllustration});

  Color get _roleColor {
    switch (user.role) {
      case UserRole.teacher: return AppColors.primary;
      case UserRole.student: return AppColors.green;
      case UserRole.parent:  return const Color(0xFF9B59B6);
      case UserRole.admin:   return const Color(0xFF2980B9);
    }
  }

  String get _initials {
    final f = user.firstName.isNotEmpty ? user.firstName[0] : '';
    final l = user.lastName.isNotEmpty  ? user.lastName[0]  : '';
    return '$f$l'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 80),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(user.firstName,
                style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w700, color: AppColors.text),
                maxLines: 1, overflow: TextOverflow.ellipsis),
              Text(_roleLabel,
                style: GoogleFonts.inter(fontSize: 5, color: AppColors.textSub),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 22, height: 22,
          decoration: BoxDecoration(
            color: _roleColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [BoxShadow(color: _roleColor.withOpacity(0.30), blurRadius: 6, offset: const Offset(0, 2))],
          ),
          child: profileIllustration != null
              ? ClipOval(
                  child: Image.asset(
                    profileIllustration!,
                    width: 22,
                    height: 22,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Center(child: Text(_initials, style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white)));
                    },
                  ),
                )
              : Center(child: Text(_initials, style: GoogleFonts.inter(fontSize: 7, fontWeight: FontWeight.w700, color: Colors.white))),
        ),
      ],
    );
  }

  String get _roleLabel {
    switch (user.role) {
      case UserRole.teacher: return 'Enseignant';
      case UserRole.student: return 'Étudiant';
      case UserRole.parent:  return 'Parent';
      case UserRole.admin:   return 'Admin';
    }
  }
}

// ── Notifications Sheet ───────────────────────────
class _NotificationsSheet extends StatelessWidget {
  final VoidCallback onClose;
  const _NotificationsSheet({required this.onClose});

  static const _items = [
    (LucideIcons.checkCircle, 'QSM terminé !',        'Biologie Cellulaire — Score 87%', '2 min',  AppColors.success),
    (LucideIcons.users,     'Nouvel étudiant',       'Karim L. a rejoint votre classe',  '15 min', AppColors.info),
    (LucideIcons.clock,        'Timer expiré',          'Room SKW-4821 terminée',           '1h',     AppColors.warning),
    (LucideIcons.award,         'Points gagnés !',       '+50 pts pour le QSM du jour',      '2h',     AppColors.primary),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(LucideIcons.bell, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text('Notifications', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.text)),
              const Spacer(),
              TextButton(onPressed: onClose, child: const Text('Fermer')),
            ],
          ),
          const SizedBox(height: 8),
          ..._items.map((n) => _NotifTile(icon: n.$1, title: n.$2, sub: n.$3, time: n.$4, color: n.$5)),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final IconData icon; final String title, sub, time; final Color color;
  const _NotifTile({required this.icon, required this.title, required this.sub, required this.time, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border, width: 0.5)),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: color)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
          Text(sub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
        ])),
        Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSub)),
      ]),
    );
  }
}

// ══════════════════════════════════════════════════
//  SKWILTI BOTTOM NAV BAR
// ══════════════════════════════════════════════════
class SkwNavItem {
  final IconData icon;
  final IconData? activeIcon;
  final String label;
  const SkwNavItem({required this.icon, required this.label, this.activeIcon});
}

class SkwiltiBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final List<SkwNavItem> items;

  const SkwiltiBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final isFiveItems = items.length == 5;
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Row(
        children: items.asMap().entries.map((e) {
          final i = e.key; final item = e.value; final sel = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding: EdgeInsets.zero,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: isFiveItems ? 38 : 44, 
                      height: isFiveItems ? 18 : 28,
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primaryLight : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Icon(sel ? (item.activeIcon ?? item.icon) : item.icon,
                        size: isFiveItems ? 16 : 20, 
                        color: sel ? AppColors.primary : AppColors.textSub),
                    ),
                    const SizedBox(height: 1),
                    Text(item.label, style: GoogleFonts.inter(
                      fontSize: isFiveItems ? 8 : 10,
                      fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                      color: sel ? AppColors.primary : AppColors.textSub,
                    )),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
