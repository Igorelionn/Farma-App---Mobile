import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/svg_icon.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary.dart';
import 'checkout_screen.dart';
import '../../catalog/bloc/catalog_bloc.dart';
import '../../catalog/bloc/catalog_state.dart';
import '../../catalog/widgets/product_card.dart';
import '../../catalog/presentation/product_details_screen.dart';
import '../../catalog/presentation/product_list_screen.dart';
import '../../favorites/bloc/favorites_bloc.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Cesta',
          style: GoogleFonts.urbanist(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: SvgIcon(
            assetPath: 'assets/icons/arrow_back_icon.svg',
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<CartBloc, CartState>(
        builder: (context, state) {
          if (state is CartLoading) {
            return const LoadingIndicator();
          }
          
          if (state is CartError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<CartBloc>().add(LoadCart());
              },
            );
          }
          
          if (state is CartEmpty) {
            return BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, catalogState) {
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SvgIcon(
                              assetPath: 'assets/icons/cart_icon.svg',
                              size: 80,
                              color: AppColors.textTertiary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Cesta Vazia',
                              style: AppTextStyles.h5,
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Adicione produtos à cesta para continuar',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: const Color(0xFF020B21),
                                  elevation: 0,
                                  shadowColor: Colors.transparent,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: Text(
                                  'Ver Catálogo',
                                  style: GoogleFonts.urbanist(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF020B21),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Produtos Recomendados
                      if (catalogState is CatalogLoaded && catalogState.products.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Divider(),
                              const SizedBox(height: 24),
                              Text(
                                'Recomendados para você',
                                style: AppTextStyles.h5.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 19,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 320,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            itemCount: catalogState.products.take(8).length,
                            separatorBuilder: (context, index) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final product = catalogState.products[index];
                              return SizedBox(
                                width: 160,
                                child: ProductCard(
                                  product: product,
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
                                          child: ProductDetailsScreen(productId: product.id),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                );
              },
            );
          }
          
          if (state is CartLoaded) {
            return Column(
              children: [
                // Search Bar
                GestureDetector(
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
                          child: ProductListScreen(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(28),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.search,
                            color: Colors.black54,
                            size: 26,
                            weight: 1.5,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Buscar produtos...',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textTertiary,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Clear Button
                if (!state.isEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          _showClearCartDialog(context);
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF1A1A1A),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        child: Text(
                          'Remover todos',
                          style: GoogleFonts.urbanist(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                      ),
                    ),
                  ),
                
                // Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return CartItemCard(
                        item: item,
                        onRemove: () {
                          _showRemoveItemDialog(
                            context,
                            item.id,
                            item.product?.nome ?? 'Produto',
                          );
                        },
                        onUpdateQuantity: (newQuantity) {
                          context.read<CartBloc>().add(
                            UpdateQuantity(
                              itemId: item.id,
                              newQuantity: newQuantity,
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                
                // Summary
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      top: BorderSide(
                        color: AppColors.border.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                  child: SafeArea(
                    child: CartSummary(
                      subtotal: state.subtotal,
                      shipping: state.shipping,
                      discount: state.discount,
                      total: state.total,
                      onCheckout: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CheckoutScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }
  
  void _showRemoveItemDialog(BuildContext context, String itemId, String productName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext sheetContext) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Close button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.close,
                          size: 24,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                // Title
                Text(
                  'Tem certeza de que deseja remover este produto?',
                  style: AppTextStyles.h5.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                
                // Delete button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      context.read<CartBloc>().add(RemoveFromCart(itemId: itemId));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Item removido da cesta',
                            style: GoogleFonts.urbanist(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFB91C1C),
                      foregroundColor: Colors.white,
                      overlayColor: const Color(0xFFB91C1C),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Excluir',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                
                // Continue shopping button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pop(sheetContext);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      overlayColor: Colors.grey.shade100,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      'Continuar comprando',
                      style: GoogleFonts.urbanist(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Limpar Cesta',
            style: GoogleFonts.urbanist(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          content: Text(
            'Deseja remover todos os itens da cesta?',
            style: GoogleFonts.urbanist(
              fontSize: 14,
              fontWeight: FontWeight.normal,
              color: AppColors.textSecondary,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(
                'Cancelar',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<CartBloc>().add(ClearCart());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Cesta limpa',
                      style: GoogleFonts.urbanist(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: Text(
                'Limpar',
                style: GoogleFonts.urbanist(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.error,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}


