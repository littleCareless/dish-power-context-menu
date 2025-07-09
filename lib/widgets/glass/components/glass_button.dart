import 'package:flutter/material.dart';
import '../core/glass_colors.dart';
import '../core/glass_container.dart';

/// 玻璃态按钮组件
class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final bool filled;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.filled = true,
    this.padding,
    this.width,
    this.height,
  });

  const GlassButton.filled({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
  }) : filled = true;

  const GlassButton.outlined({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.width,
    this.height,
  }) : filled = false;

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _opacityAnimation = Tween<double>(begin: 0.3, end: 0.5).animate(
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
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _isPressed ? _scaleAnimation.value : 1.0,
          child: MouseRegion(
            onEnter: (_) {
              if (mounted) {
                setState(() => _isHovered = true);
              }
            },
            onExit: (_) {
              if (mounted) {
                setState(() => _isHovered = false);
              }
            },
            child: GestureDetector(
              onTapDown: (_) {
                if (mounted) {
                  setState(() => _isPressed = true);
                  _animationController.forward();
                }
              },
              onTapUp: (_) {
                if (mounted) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                  widget.onPressed?.call();
                }
              },
              onTapCancel: () {
                if (mounted) {
                  setState(() => _isPressed = false);
                  _animationController.reverse();
                }
              },
              child: GlassContainer(
                width: widget.width,
                height: widget.height,
                padding:
                    widget.padding ??
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                opacity:
                    widget.filled
                        ? (_isHovered ? _opacityAnimation.value : 0.3)
                        : 0.1,
                gradient:
                    widget.filled
                        ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            GlassColors.primary.withOpacity(
                              _isHovered ? 0.6 : 0.4,
                            ),
                            GlassColors.secondary.withOpacity(
                              _isHovered ? 0.4 : 0.2,
                            ),
                          ],
                        )
                        : null,
                border:
                    widget.filled
                        ? null
                        : Border.all(
                          color:
                              _isHovered
                                  ? GlassColors.primary.withOpacity(0.6)
                                  : GlassColors.glassBorder,
                          width: 1.5,
                        ),
                child: Center(
                  child: DefaultTextStyle(
                    style: TextStyle(
                      color:
                          widget.filled
                              ? Colors.white
                              : (_isHovered
                                  ? GlassColors.primary
                                  : Colors.white70),
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}