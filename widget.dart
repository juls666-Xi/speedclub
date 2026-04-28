// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/neon_button.dart
// ═══════════════════════════════════════════════════════════════
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class NeonButton extends StatefulWidget {
  const NeonButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.accentColor = AppColors.neonCyan,
    this.outlined = false,
    this.icon,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color accentColor;
  final bool outlined;
  final IconData? icon;
  final bool small;

  @override
  State<NeonButton> createState() => _NeonButtonState();
}

class _NeonButtonState extends State<NeonButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ripple;

  @override
  void initState() {
    super.initState();
    _ripple = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.97,
      upperBound: 1.0,
      value: 1.0,
    );
  }

  @override
  void dispose() {
    _ripple.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _ripple.reverse();
  void _onTapUp(_) => _ripple.forward();

  @override
  Widget build(BuildContext context) {
    final h = widget.small ? 42.0 : 52.0;
    final textStyle = widget.small ? AppTextStyles.body : AppTextStyles.h3;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: () => _ripple.forward(),
      onTap: widget.loading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _ripple,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: h,
          decoration: BoxDecoration(
            color: widget.outlined ? Colors.transparent : widget.accentColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.accentColor, width: 1.5),
            boxShadow: widget.outlined
                ? null
                : [
                    BoxShadow(
                      color: widget.accentColor.withOpacity(0.35),
                      blurRadius: 16,
                      spreadRadius: -2,
                    )
                  ],
          ),
          child: Center(
            child: widget.loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(
                        widget.outlined ? widget.accentColor : AppColors.bg0,
                      ),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon,
                            size: 18,
                            color: widget.outlined
                                ? widget.accentColor
                                : AppColors.bg0),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: textStyle.copyWith(
                          color: widget.outlined ? widget.accentColor : AppColors.bg0,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/neon_text_field.dart
// ═══════════════════════════════════════════════════════════════

class NeonTextField extends StatelessWidget {
  const NeonTextField({
    super.key,
    required this.controller,
    required this.label,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.validator,
    this.keyboardType,
    this.maxLines = 1,
    this.hint,
    this.enabled = true,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? hint;
  final bool enabled;
  final void Function(String)? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      keyboardType: keyboardType,
      maxLines: maxLines,
      enabled: enabled,
      onChanged: onChanged,
      style: AppTextStyles.body,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 18, color: AppColors.textHint)
            : null,
        suffixIcon: suffixIcon,
        labelStyle: AppTextStyles.label,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/duelgap_logo.dart
// ═══════════════════════════════════════════════════════════════

class DuelGapLogo extends StatelessWidget {
  const DuelGapLogo({super.key, this.size = 72});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const RadialGradient(
          colors: [Color(0xFF00E5FF), Color(0xFF0D1B2A)],
          stops: [0.3, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.neonCyan.withOpacity(0.45),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Center(
        child: Icon(Icons.flag_rounded,
            size: size * 0.46, color: AppColors.bg0),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/category_chip.dart
// ═══════════════════════════════════════════════════════════════

class CategoryChip extends StatelessWidget {
  const CategoryChip({super.key, required this.category, this.selected = false, this.onTap});
  final String category;
  final bool selected;
  final VoidCallback? onTap;

  IconData get _icon => switch (category) {
    'car'        => Icons.directions_car_rounded,
    'bicycle'    => Icons.directions_bike_rounded,
    'motorcycle' => Icons.two_wheeler_rounded,
    'running'    => Icons.directions_run_rounded,
    _            => Icons.help_outline,
  };

  @override
  Widget build(BuildContext context) {
    final color = categoryColor(category);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.15) : AppColors.bg2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : AppColors.borderSubtle,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 16, color: selected ? color : AppColors.textHint),
            const SizedBox(width: 6),
            Text(
              category.toUpperCase(),
              style: AppTextStyles.label.copyWith(
                color: selected ? color : AppColors.textHint,
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/rank_badge.dart
// ═══════════════════════════════════════════════════════════════

class RankBadge extends StatelessWidget {
  const RankBadge({super.key, required this.tier, required this.points, this.compact = false});
  final String tier;
  final int points;
  final bool compact;

  IconData get _icon => switch (tier) {
    'legend'   => Icons.auto_awesome,
    'elite'    => Icons.star,
    'diamond'  => Icons.diamond_outlined,
    'platinum' => Icons.shield_outlined,
    'gold'     => Icons.emoji_events_outlined,
    'silver'   => Icons.military_tech_outlined,
    _          => Icons.workspace_premium_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final color = tierColor(tier);
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_icon, size: 12, color: color),
            const SizedBox(width: 4),
            Text(tier.toUpperCase(),
                style: AppTextStyles.label.copyWith(color: color, fontSize: 10)),
          ],
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.15), blurRadius: 12),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 18, color: color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(tier.toUpperCase(),
                  style: AppTextStyles.label.copyWith(color: color)),
              Text('$points pts',
                  style: AppTextStyles.bodySmall.copyWith(color: color.withOpacity(0.7))),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/glass_card.dart
// ═══════════════════════════════════════════════════════════════

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.glowColor,
    this.onTap,
    this.margin,
  });

  final Widget child;
  final EdgeInsets? padding;
  final Color? glowColor;
  final VoidCallback? onTap;
  final EdgeInsets? margin;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: margin,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.bg1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: glowColor?.withOpacity(0.3) ?? AppColors.borderSubtle,
          ),
          boxShadow: glowColor != null
              ? [BoxShadow(color: glowColor!.withOpacity(0.08), blurRadius: 20)]
              : null,
        ),
        child: child,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/user_avatar.dart
// ═══════════════════════════════════════════════════════════════

class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.username,
    this.avatarUrl,
    this.size = 44,
    this.glowColor,
  });

  final String username;
  final String? avatarUrl;
  final double size;
  final Color? glowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glowColor != null
            ? [BoxShadow(color: glowColor!.withOpacity(0.4), blurRadius: 12)]
            : null,
      ),
      child: CircleAvatar(
        radius: size / 2,
        backgroundColor: AppColors.bg3,
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
        child: avatarUrl == null
            ? Text(
                username.isNotEmpty ? username[0].toUpperCase() : '?',
                style: AppTextStyles.h2.copyWith(
                  color: AppColors.neonCyan,
                  fontSize: size * 0.38,
                ),
              )
            : null,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/stat_chip.dart
// ═══════════════════════════════════════════════════════════════

class StatChip extends StatelessWidget {
  const StatChip({
    super.key,
    required this.label,
    required this.value,
    this.color = AppColors.neonCyan,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: AppTextStyles.h1.copyWith(color: color, fontFamily: 'Orbitron')),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.label),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/loading_overlay.dart
// ═══════════════════════════════════════════════════════════════

class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({super.key, this.message});
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation(AppColors.neonCyan),
              strokeWidth: 2,
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              Text(message!, style: AppTextStyles.body),
            ],
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// lib/shared/widgets/gap_meter.dart  (live race gap display)
// ═══════════════════════════════════════════════════════════════

class GapMeter extends StatelessWidget {
  const GapMeter({
    super.key,
    required this.currentGapM,
    required this.targetGapM,
    required this.isLeading,
  });

  final double currentGapM;
  final double targetGapM;
  final bool isLeading;

  double get _progress => (currentGapM / targetGapM).clamp(0.0, 1.0);

  @override
  Widget build(BuildContext context) {
    final color = isLeading ? AppColors.neonGreen : AppColors.neonRed;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              isLeading ? 'YOU LEAD' : 'OPPONENT LEADS',
              style: AppTextStyles.label.copyWith(color: color),
            ),
            Text(
              '${currentGapM.toStringAsFixed(0)}m / ${targetGapM.toStringAsFixed(0)}m',
              style: AppTextStyles.label.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: _progress,
            backgroundColor: AppColors.bg3,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}