import 'package:flutter/material.dart';
import '../theme/skwilti_theme.dart';

// Additional Skwilti-styled widgets
class SkwiltiStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;

  const SkwiltiStatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cardColor = color ?? SkwiltiTheme.primaryViolet;
    
    return SkwiltiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SkwiltiIcon(
                icon: icon,
                variant: SkwiltiIconVariant.background,
                color: cardColor,
                size: 20,
              ),
              const Spacer(),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: SkwiltiTheme.caption.copyWith(
                    color: SkwiltiTheme.textSecondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: SkwiltiTheme.headingMedium.copyWith(
              color: cardColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: SkwiltiTheme.bodySmall.copyWith(
              color: SkwiltiTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class SkwiltiProgressCard extends StatelessWidget {
  final String title;
  final double progress;
  final String? value;
  final Color? color;
  final bool showPercentage;

  const SkwiltiProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.value,
    this.color,
    this.showPercentage = true,
  });

  @override
  Widget build(BuildContext context) {
    final progressColor = color ?? SkwiltiTheme.primaryViolet;
    final progressValue = (progress * 100).toInt();
    
    return SkwiltiCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: SkwiltiTheme.titleMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showPercentage)
                Text(
                  value ?? '$progressValue%',
                  style: SkwiltiTheme.bodySmall.copyWith(
                    color: progressColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 8,
            decoration: BoxDecoration(
              color: SkwiltiTheme.borderLight,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  color: progressColor,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SkwiltiUserAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const SkwiltiUserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl != null) {
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: NetworkImage(imageUrl!),
        backgroundColor: backgroundColor ?? SkwiltiTheme.borderLight,
      );
    }

    final initials = name != null && name!.isNotEmpty
        ? name!.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : '?';

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: backgroundColor ?? SkwiltiTheme.primaryVioletBackground,
      child: Text(
        initials,
        style: SkwiltiTheme.titleMedium.copyWith(
          color: SkwiltiTheme.primaryViolet,
          fontWeight: FontWeight.w600,
          fontSize: size * 0.4,
        ),
      ),
    );
  }
}

class SkwiltiChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final VoidCallback? onTap;

  const SkwiltiChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chipBgColor = backgroundColor ?? SkwiltiTheme.primaryVioletBackground;
    final chipTextColor = textColor ?? SkwiltiTheme.primaryViolet;

    Widget chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipBgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            SkwiltiIcon(
              icon: icon!,
              size: 16,
              color: chipTextColor,
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: SkwiltiTheme.bodySmall.copyWith(
              color: chipTextColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      chip = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: chip,
      );
    }

    return chip;
  }
}

class SkwiltiHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<Widget>? actions;
  final Color? backgroundColor;

  const SkwiltiHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actions,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundColor ?? SkwiltiTheme.primaryViolet,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                SkwiltiIcon(
                  icon: icon!,
                  color: Colors.white,
                  size: 28,
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: SkwiltiTheme.headingMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: SkwiltiTheme.bodyMedium.copyWith(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (actions != null) ...?actions,
            ],
          ),
        ],
      ),
    );
  }
}

class SkwiltiEmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? action;

  const SkwiltiEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              SkwiltiIcon(
                icon: icon!,
                size: 64,
                color: SkwiltiTheme.textSecondary,
              ),
              const SizedBox(height: 24),
            ],
            Text(
              title,
              textAlign: TextAlign.center,
              style: SkwiltiTheme.titleLarge.copyWith(
                color: SkwiltiTheme.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 12),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: SkwiltiTheme.bodyMedium.copyWith(
                  color: SkwiltiTheme.textSecondary,
                ),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 24),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

class SkwiltiLoadingState extends StatelessWidget {
  final String? message;

  const SkwiltiLoadingState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: SkwiltiTheme.primaryViolet,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: SkwiltiTheme.bodyMedium.copyWith(
                color: SkwiltiTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class SkwiltiBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Color? textColor;

  const SkwiltiBadge({
    super.key,
    required this.text,
    this.color,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? SkwiltiTheme.primaryViolet;
    final badgeTextColor = textColor ?? Colors.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: SkwiltiTheme.caption.copyWith(
          color: badgeTextColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
