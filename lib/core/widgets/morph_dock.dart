import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MorphDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MorphDockItem> items;

  const MorphDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),  // Branco 100% opaco
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.border.withValues(alpha: 0.5),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          items.length,
          (index) => _buildDockItem(index),
        ),
      ),
    );
  }

  Widget _buildDockItem(int index) {
    final item = items[index];
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        width: 48,
        height: 48,
        child: Center(
          child: item.icon,
        ),
      ),
    );
  }
}

class MorphDockItem {
  final Widget icon;
  final String label;

  const MorphDockItem({
    required this.icon,
    required this.label,
  });
}

