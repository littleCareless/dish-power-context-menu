import 'package:flutter/material.dart';
import '../core/glass_colors.dart';
import '../core/glass_container.dart';

/// 玻璃态卡片组件
class GlassCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final double elevation;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.elevation = 4.0,
  });

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.02).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) {
              if (mounted) {
                setState(() => _isHovered = true);
                _animationController.forward();
              }
            },
            onExit: (_) {
              if (mounted) {
                setState(() => _isHovered = false);
                _animationController.reverse();
              }
            },
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin:
                    widget.margin ?? const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: GlassColors.primary.withOpacity(
                        _isHovered ? 0.3 : 0.1,
                      ),
                      blurRadius: widget.elevation * 2,
                      offset: Offset(0, widget.elevation),
                    ),
                  ],
                ),
                child: GlassContainer(
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  opacity: _isHovered ? 0.3 : 0.2,
                  child: widget.child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}