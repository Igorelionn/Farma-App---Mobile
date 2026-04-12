import 'package:flutter/material.dart';
import '../../../data/models/category.dart';

const _kCategoryColors = <String, Color>{
  'medication': Color(0xFF4CAF50),
  'science': Color(0xFF2196F3),
  'local_hospital': Color(0xFFE91E63),
  'medical_services': Color(0xFF9C27B0),
  'healing': Color(0xFFFF9800),
  'spa': Color(0xFF009688),
  'vaccines': Color(0xFF3F51B5),
  'cleaning_services': Color(0xFF00BCD4),
};

const _kCategoryImages = <String, String>{
  'fd23810a-a4e7-4de6-8019-7bdbff3a2736': 'assets/images/medicamentos.png',
  '514df013-93e9-4bce-900d-a1a20b1331d5': 'assets/images/materiais_hospitalares.png',
  'ac2fc24f-98c7-4699-8890-9f003cd5abef': 'assets/images/injetaveis.png',
  '2163baab-e7c4-46c5-87f0-6d805a4f14c9': 'assets/images/limpeza_desinfeccao.png',
  'b87ad532-ff92-4d9a-a25e-557a638a48d5': 'assets/images/higiene_dermocosmeticos.png',
  '2cb29ccc-7521-406a-8cd6-2be63f8a0ec8': 'assets/images/equipamentos_nutricao.png',
};

IconData getCategoryIconData(String icone) {
  switch (icone) {
    case 'medication':
      return Icons.medication_rounded;
    case 'science':
      return Icons.science_rounded;
    case 'local_hospital':
      return Icons.local_hospital_rounded;
    case 'medical_services':
      return Icons.medical_services_rounded;
    case 'healing':
      return Icons.healing_rounded;
    case 'spa':
      return Icons.spa_rounded;
    case 'vaccines':
      return Icons.vaccines_rounded;
    case 'cleaning_services':
      return Icons.cleaning_services_rounded;
    default:
      return Icons.category_rounded;
  }
}

Color _getCategoryColor(String icone) {
  return _kCategoryColors[icone] ?? const Color(0xFF78909C);
}

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
    final color = _getCategoryColor(category.icone);
    final imagePath = _kCategoryImages[category.id];
    final hasImage = imagePath != null;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 90,
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: hasImage ? Colors.transparent : color.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              clipBehavior: hasImage ? Clip.antiAlias : Clip.none,
              child: hasImage
                  ? Image.asset(
                      imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          getCategoryIconData(category.icone),
                          size: 28,
                          color: color.withValues(alpha: 0.85),
                        ),
                      ),
                    )
                  : Icon(
                      getCategoryIconData(category.icone),
                      size: 28,
                      color: color.withValues(alpha: 0.85),
                    ),
            ),
            const SizedBox(height: 10),
            Text(
              category.nome,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: hasImage ? const Color(0xFF1A1A1A) : const Color(0xFF3D3D3D),
                height: 1.2,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
