// ==================== widgets/common/menu_item_widget.dart ====================
import 'package:flutter/material.dart';

class MenuItemWidget extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isDestructive;
  final VoidCallback? onTap;
  final Color? textColor;
  final Color? cardColor;
  final Color? subtitleColor;
  final Color? borderColor;

  const MenuItemWidget({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.isDestructive = false,
    this.onTap,
    this.textColor,
    this.cardColor,
    this.subtitleColor,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = isDestructive 
        ? Colors.red 
        : (textColor ?? Colors.white);
    
    final effectiveSubtitleColor = subtitleColor ?? Colors.grey[400];
    
    final effectiveBorderColor = borderColor ?? 
        (cardColor != null && cardColor == Colors.white 
            ? Colors.grey[300] 
            : Colors.grey[800]);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: effectiveBorderColor!,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: effectiveTextColor,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: effectiveTextColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: TextStyle(
                        color: effectiveSubtitleColor,
                        fontSize: 14,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: effectiveSubtitleColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}