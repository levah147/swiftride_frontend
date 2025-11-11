// ==================== widgets/common/menu_section_widget.dart ====================
import 'package:flutter/material.dart';

class MenuSectionWidget extends StatelessWidget {
  final List<Widget> items;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? margin;
  final EdgeInsets? padding;

  const MenuSectionWidget({
    super.key,
    required this.items,
    this.backgroundColor,
    this.borderColor,
    this.margin,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor = backgroundColor ?? Colors.grey[900];
    final effectiveMargin = margin ?? const EdgeInsets.symmetric(horizontal: 20);
    final effectivePadding = padding ?? EdgeInsets.zero;

    return Container(
      margin: effectiveMargin,
      padding: effectivePadding,
      decoration: BoxDecoration(
        color: effectiveBgColor,
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null
            ? Border.all(
                color: borderColor!,
                width: 0.5,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: items,
        ),
      ),
    );
  }
}