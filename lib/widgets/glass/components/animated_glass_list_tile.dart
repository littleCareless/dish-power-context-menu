import 'package:flutter/material.dart';
import '../core/glass_colors.dart';
import '../core/glass_container.dart';
import 'glass_card.dart';

/// 动画玻璃态列表项组件
class AnimatedGlassListTile extends StatefulWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? contentPadding;
  final int animationDelay;

  const AnimatedGlassListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.contentPadding,
    this.animationDelay = 0,
  });

  @override
  State<AnimatedGlassListTile> createState() => _AnimatedGlassListTileState();
}

class _AnimatedGlassListTileState extends State<AnimatedGlassListTile>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _hoverController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _hoverAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOut));

    _hoverAnimation = Tween<double>(begin: 0.2, end: 0.3).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    // 延迟启动动画
    Future.delayed(Duration(milliseconds: widget.animationDelay), () {
      if (mounted && _slideController.isAnimating == false) {
        _slideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedBuilder(
          animation: _hoverAnimation,
          builder: (context, child) {
            return MouseRegion(
              onEnter: (_) {
                if (mounted) {
                  setState(() => _isHovered = true);
                  _hoverController.forward();
                }
              },
              onExit: (_) {
                if (mounted) {
                  setState(() => _isHovered = false);
                  _hoverController.reverse();
                }
              },
              child: GlassCard(
                onTap: widget.onTap,
                padding: EdgeInsets.zero,
                child: GlassContainer(
                  padding: EdgeInsets.zero,
                  opacity: _hoverAnimation.value,
                  child: ListTile(
                    leading: widget.leading,
                    title: widget.title,
                    subtitle: widget.subtitle,
                    trailing: widget.trailing,
                    onTap: widget.onTap,
                    contentPadding:
                        widget.contentPadding ??
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    textColor: Colors.white,
                    iconColor: _isHovered ? GlassColors.accent : Colors.white70,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}