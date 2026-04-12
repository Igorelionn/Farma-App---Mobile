import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String? message;
  final String? actionText;
  final VoidCallback? onActionPressed;
  
  const EmptyState({
    super.key,
    this.icon,
    this.iconWidget,
    required this.title,
    this.message,
    this.actionText,
    this.onActionPressed,
  }) : assert(icon != null || iconWidget != null, 'Either icon or iconWidget must be provided');

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (iconWidget != null)
              iconWidget!
            else
              Icon(
                icon!,
                size: 80,
                color: AppColors.textTertiary,
              ),
            const SizedBox(height: 24),
            Text(
              title,
              style: AppTextStyles.h5,
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionText != null && onActionPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onActionPressed,
                child: Text(actionText!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

