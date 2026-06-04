import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../services/app_state.dart';
import '../models/user.dart';
import 'skwilti_logo.dart';
import '../screens/messages_screen.dart';

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
              const SizedBox(width: 8),
              _MessagesBell(),
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

class _MessagesBell extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final unread = context.watch<AppState>().unreadMessagesCount;
    return GestureDetector(
      // CORRECTION: Retiré const devant MessagesScreen()
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen())),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: unread > 0 ? AppColors.primaryLight : AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: unread > 0 ? AppColors.primary.withOpacity(0.3) : AppColors.border,
                width: unread > 0 ? 1.0 : 0.5,
              ),
            ),
            child: Icon(
              LucideIcons.messageCircle,
              size: 18,
              color: unread > 0 ? AppColors.primary : AppColors.text,
            ),
          ),
          if (unread > 0)
            Positioned(
              top: -6,
              right: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    unread > 99 ? '99+' : '$unread',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: unread > 99 ? 8 : 10,
                      fontWeight: FontWeight.w800,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _MessagesRedirect extends StatelessWidget {
  const _MessagesRedirect();
  @override
  Widget build(BuildContext context) {
    // CORRECTION: Retiré const devant MessagesScreen()
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => MessagesScreen()));
    });
    return const SizedBox.shrink();
  }
}

// ── Notification Bell with badge ──────────────────
class _NotificationBell extends StatefulWidget {
  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> with SingleTickerProviderStateMixin {
  late AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
  }
  @override
  void dispose() { _shake.dispose(); super.dispose(); }

  void _open() {
    context.read<AppState>().loadNotifications();
    _shake.forward().then((_) => _shake.reverse());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationsSheet(onClose: () => Navigator.pop(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final count = context.watch<AppState>().unreadNotificationsCount;
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
          if (count > 0)
            Positioned(
              top: -3, right: -3,
              child: Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: Center(child: Text('$count', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white))),
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
  const _ProfileChip({required this.user, this.profileIllustration});

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

  @override
  Widget build(BuildContext context) {
    final notifications = context.watch<AppState>().notifications;
    final loaded = context.watch<AppState>().notificationsLoaded;

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
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
          if (!loaded)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (notifications.isEmpty)
            Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(LucideIcons.bellOff, size: 48, color: AppColors.textSub.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text('Aucune notification', style: GoogleFonts.inter(color: AppColors.textSub)),
                ],
              ),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final n = notifications[index];
                  final data = n['data'] as Map<String, dynamic>?;
                  final type = n['type']?.toString();
                  final roomCode = data?['room_code']?.toString();

                  return _NotifTile(
                    id: n['id'].toString(),
                    title: n['title'] ?? '',
                    sub: n['message'] ?? '',
                    time: _formatTime(n['created_at']),
                    icon: _getIcon(type),
                    color: _getColor(type),
                    roomCode: roomCode,
                    isRead: n['is_read'] ?? false,
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  String _formatTime(String? dateStr) {
    if (dateStr == null) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'room_created': return LucideIcons.rocket;
      case 'qsm_completed': return LucideIcons.checkCircle;
      case 'achievement': return LucideIcons.award;
      case 'room_join': return LucideIcons.userPlus;
      default: return LucideIcons.bell;
    }
  }

  Color _getColor(String? type) {
    switch (type) {
      case 'room_created': return AppColors.warning;
      case 'qsm_completed': return AppColors.success;
      case 'achievement': return AppColors.primary;
      case 'room_join': return AppColors.primary;
      default: return AppColors.info;
    }
  }
}

class _NotifTile extends StatelessWidget {
  final String id;
  final String title, sub, time;
  final IconData icon;
  final Color color;
  final String? roomCode;
  final bool isRead;

  const _NotifTile({
    required this.id,
    required this.title,
    required this.sub,
    required this.time,
    required this.icon,
    required this.color,
    this.roomCode,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final emojiRegExp = RegExp(
      r'[\u{1F300}-\u{1F9FF}]|[\u{1F600}-\u{1F64F}]|[\u{1F680}-\u{1F6FF}]|[\u{2600}-\u{26FF}]|[\u{2700}-\u{27BF}]',
      unicode: true,
    );
    final cleanTitle = title.replaceAll(emojiRegExp, '').trim();
    final cleanSub = sub.replaceAll(emojiRegExp, '').trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isRead ? AppColors.background : color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isRead ? AppColors.border : color.withOpacity(0.3), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 17, color: color)),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(cleanTitle, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.text)),
              Text(cleanSub, style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
            ])),
            Text(time, style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSub)),
          ]),
          if (roomCode != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: roomCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Code $roomCode copié !'),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(LucideIcons.copy, size: 12),
                  label: Text('Copier le code : $roomCode', style: const TextStyle(fontSize: 11)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    minimumSize: const Size(0, 32),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
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
    final int itemCount = items.length;
    final double iconSize = itemCount > 5 ? 12.0 : (itemCount == 5 ? 16.0 : 20.0);
    final double textSize = itemCount > 5 ? 7.0 : (itemCount == 5 ? 8.0 : 10.0);
    final double bgWidth = itemCount > 5 ? 32.0 : (itemCount == 5 ? 38.0 : 44.0);
    final double bgHeight = itemCount > 5 ? 12.0 : (itemCount == 5 ? 16.0 : 24.0);

    return Container(
      height: 56,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border, width: 0.5)),
        boxShadow: [BoxShadow(color: Color(0x0A000000), blurRadius: 20, offset: Offset(0, -4))],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0),
        child: Row(
          children: items.asMap().entries.map((e) {
            final i = e.key; final item = e.value; final sel = i == currentIndex;
            return Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: bgWidth,
                        height: bgHeight,
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primaryLight : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(sel ? (item.activeIcon ?? item.icon) : item.icon,
                          size: iconSize, 
                          color: sel ? AppColors.primary : AppColors.textSub),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.label, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: textSize,
                          fontWeight: sel ? FontWeight.w700 : FontWeight.w600,
                          color: sel ? AppColors.primary : AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}