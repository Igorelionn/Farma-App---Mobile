import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart' as custom;
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_state.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import 'product_list_screen.dart';

const _kCategoryIcons = <String, IconData>{
  'Medicamentos': Icons.medication_rounded,
  'Material Hospitalar': Icons.medical_services_rounded,
  'Injetaveis': Icons.vaccines_rounded,
  'Higiene e Dermocosmeticos': Icons.spa_rounded,
  'Limpeza e Desinfeccao': Icons.cleaning_services_rounded,
  'Equipamentos e Nutricao': Icons.monitor_heart_rounded,
};

const _kCategoryColors = <String, Color>{
  'Medicamentos': Color(0xFF4CAF50),
  'Material Hospitalar': Color(0xFF2196F3),
  'Injetaveis': Color(0xFF9C27B0),
  'Higiene e Dermocosmeticos': Color(0xFF009688),
  'Limpeza e Desinfeccao': Color(0xFF00BCD4),
  'Equipamentos e Nutricao': Color(0xFFFF9800),
};

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: BlocBuilder<CatalogBloc, CatalogState>(
                builder: (context, state) {
                  if (state is CatalogLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (state is CatalogError) {
                    return Center(
                      child: custom.CustomErrorWidget(
                        message: state.message,
                        onRetry: () {},
                      ),
                    );
                  }

                  if (state is CatalogLoaded) {
                    return _buildCategoriesGrid(context, state.categories);
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.arrow_back_rounded, size: 20),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Categorias',
                  style: GoogleFonts.dmSerifDisplay(
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                Text(
                  'Encontre o que você precisa',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF757575),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesGrid(BuildContext context, List categories) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.85,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        return _buildCategoryCard(context, category);
      },
    );
  }

  Widget _buildCategoryCard(BuildContext context, dynamic category) {
    final color = _kCategoryColors[category.nome] ?? const Color(0xFF78909C);
    final icon = _kCategoryIcons[category.nome] ?? Icons.inventory_2_rounded;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (ctx) => MultiBlocProvider(
              providers: [
                BlocProvider.value(value: context.read<CatalogBloc>()),
                BlocProvider.value(value: context.read<CartBloc>()),
                BlocProvider.value(value: context.read<FavoritesBloc>()),
              ],
              child: ProductListScreen(
                categoryId: category.id,
                categoryName: category.nome,
              ),
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 40,
                color: color,
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                category.nome,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1A1A),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${category.produtoCount ?? 0} produtos',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: const Color(0xFF9E9E9E),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
