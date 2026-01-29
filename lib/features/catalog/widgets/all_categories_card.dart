import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AllCategoriesCard extends StatelessWidget {
  final VoidCallback onTap;
  
  const AllCategoriesCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            // Círculo com ícone de grade
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white, // Fundo branco
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.grid_view_rounded,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            // Nome "Todas as categorias"
            Text(
              'Todas as\ncategorias',
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

