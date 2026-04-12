import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class MorphDock extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<MorphDockItem> items;
  final bool showNotification;
  final String? notificationText;
  final VoidCallback? onViewCart;

  const MorphDock({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
    this.showNotification = false,
    this.notificationText,
    this.onViewCart,
  });

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    return Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: EdgeInsets.fromLTRB(12, 8, 12, 16 + bottomPadding),
        padding: EdgeInsets.symmetric(
          horizontal: showNotification ? 20 : 6,
          vertical: showNotification ? 16 : 10,
        ),
        decoration: BoxDecoration(
          color: AppColors.navBarBackground,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: showNotification
            ? _buildNotification()
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  items.length,
                  (index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: _buildDockItem(index),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildNotification() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.check_circle,
          color: Color(0xFF10B981),
          size: 20,
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Text(
            'Produto adicionado à cesta',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onViewCart,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Ver',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDockItem(int index) {
    final item = items[index];
    final isSelected = currentIndex == index;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutQuart,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: item.icon,
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
