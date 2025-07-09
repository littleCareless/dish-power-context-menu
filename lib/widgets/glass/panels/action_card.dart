import 'package:flutter/material.dart';
import '../core/glass_colors.dart';
import '../components/glass_card.dart';
import '../components/glass_button.dart';

/// 操作卡片组件
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isCompact;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.onPressed,
    this.isPrimary = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cardPadding = isCompact ? 12.0 : 20.0;
    final iconPadding = isCompact ? 8.0 : 12.0;
    final iconSize = isCompact ? 20.0 : 28.0;
    final titleSize = isCompact ? 16.0 : 18.0;
    final descriptionSize = isCompact ? 12.0 : 14.0;
    final spacing = isCompact ? 8.0 : 16.0;
    final smallSpacing = isCompact ? 4.0 : 8.0;

    return GlassCard(
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color:
                      isPrimary
                          ? GlassColors.accent.withOpacity(0.3)
                          : GlassColors.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
                ),
                child: Icon(
                  icon,
                  color: isPrimary ? GlassColors.accent : Colors.white,
                  size: iconSize,
                ),
              ),
              SizedBox(height: spacing),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: titleSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: smallSpacing),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: descriptionSize,
                  height: 1.4,
                ),
                maxLines: isCompact ? 2 : null,
                overflow: isCompact ? TextOverflow.ellipsis : null,
              ),
              SizedBox(height: spacing),
              SizedBox(
                width: double.infinity,
                child:
                    isPrimary
                        ? GlassButton.filled(
                          onPressed: onPressed,
                          padding:
                              isCompact
                                  ? const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  )
                                  : null,
                          child: const Text('开始操作'),
                        )
                        : GlassButton.outlined(
                          onPressed: onPressed,
                          padding:
                              isCompact
                                  ? const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  )
                                  : null,
                          child: const Text('执行'),
                        ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}