import 'package:flutter/material.dart';
import '../../../data/models/category.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CategoryCard extends StatelessWidget {
  final Category category;
  final VoidCallback onTap;
  
  const CategoryCard({
    super.key,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90, // Largura aumentada para evitar quebra em textos longos
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          children: [
            // Círculo com ícone
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white, // Fundo branco puro
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.border.withValues(alpha: 0.5), // Borda sutil
                  width: 1,
                ),
              ),
              child: Icon(
                category.getIconData(),
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),
            // Nome da categoria com quebra de linha
            Text(
              category.nome,
              style: AppTextStyles.bodySmall.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.2, // Espaçamento entre linhas
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.visible, // Permite quebra natural
            ),
          ],
        ),
      ),
    );
  }
}

