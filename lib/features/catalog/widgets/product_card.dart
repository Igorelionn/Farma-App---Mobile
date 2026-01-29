import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/models/product.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/bloc/favorites_event.dart';
import '../../favorites/bloc/favorites_state.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  // Gera uma avaliação diversificada baseada no ID do produto
  Map<String, dynamic> _generateRating() {
    final hash = product.id.hashCode.abs();
    
    // Usa múltiplos valores do hash para criar mais variação
    final seed1 = hash % 97;  // Número primo para melhor distribuição
    final seed2 = (hash ~/ 13) % 73;  // Outro número primo
    final seed3 = (hash * 7) % 61;  // Mais variação
    
    // Gera estrelas entre 4.6 e 5.0 apenas com valores "redondos"
    final ratings = [
      4.6, 4.7, 4.8, 4.9, 5.0
    ];
    final rating = ratings[(seed1 + seed2) % ratings.length];
    
    // Gera quantidade de avaliações muito variadas (47 a 8500)
    final counts = [
      47, 89, 134, 256, 378, 491, 567, 643, 729, 814, 
      956, 1089, 1234, 1456, 1678, 1897, 2134, 2367, 2589, 2834,
      3056, 3289, 3512, 3789, 4023, 4256, 4489, 4712, 4934, 5167,
      5423, 5678, 5923, 6178, 6423, 6689, 6934, 7189, 7456, 7734,
      7989, 8256, 8512
    ];
    final count = counts[(seed2 + seed3) % counts.length];
    
    return {'rating': rating, 'count': count};
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
          // Sem sombra
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image Container
                Container(
                  height: 140,
                  decoration: const BoxDecoration(
                    color: Colors.white, // Fundo branco para as imagens
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Product Image
                      if (product.imagem != null && product.imagem!.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(12),
                          ),
                          child: Image.network(
                            product.imagem!,
                            width: double.infinity,
                            height: 140,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(
                                  Icons.medication,
                                  size: 60,
                                  color: AppColors.textTertiary,
                                ),
                              );
                            },
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.medication,
                            size: 60,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      // Favorite button
                      Positioned(
                        top: 8,
                        right: 8,
                        child: BlocBuilder<FavoritesBloc, FavoritesState>(
                          builder: (context, state) {
                            final isFavorite = state is FavoritesLoaded &&
                                state.isFavorite(product.id);
                            return GestureDetector(
                              onTap: () {
                                context.read<FavoritesBloc>().add(
                                  ToggleFavorite(productId: product.id),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF5F5F5), // Branco mais escuro (grey[100])
                                  shape: BoxShape.circle,
                                  // Sombra removida
                                ),
                                child: Icon(
                                  isFavorite ? Icons.favorite : Icons.favorite_border,
                                  color: isFavorite ? AppColors.error : AppColors.textSecondary,
                                  size: 20,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // Product Info
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(10), // Reduzido para evitar overflow
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Rating Badge - Alinhado com o título
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Color(0xFFFFC107)),
                            const SizedBox(width: 4),
                            Text(
                              _generateRating()['rating'].toString(),
                              style: AppTextStyles.caption.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '(${Formatters.compactNumber(_generateRating()['count'])})',
                              style: AppTextStyles.caption.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          product.nome,
                          style: AppTextStyles.labelMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3), // Reduzido
                        Text(
                          product.laboratorio,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3), // Reduzido
                        Text(
                          product.apresentacao,
                          style: AppTextStyles.caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        // Price
                        if (product.emPromocao && product.precoPromocional != null) ...[
                          Text(
                            Formatters.currency(product.preco),
                            style: AppTextStyles.bodySmall.copyWith(
                              decoration: TextDecoration.lineThrough,
                              color: AppColors.textTertiary,
                            ),
                          ),
                          Text(
                            Formatters.currency(product.precoPromocional!),
                            style: AppTextStyles.priceSmall.copyWith(
                              color: Colors.black,
                            ),
                          ),
                        ] else
                          Text(
                            Formatters.currency(product.preco),
                            style: AppTextStyles.priceSmall.copyWith(
                              color: Colors.black,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            // Add to Cart Button
            if (product.disponivel && product.estoque > 0)
              Positioned(
                top: 98, // Ajustado para alinhar o centro visualmente com a badge
                right: 8,
                child: GestureDetector(
                  onTap: () {
                    context.read<CartBloc>().add(
                      AddToCart(product: product),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${product.nome} adicionado ao carrinho'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white, // Fundo branco
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 1), // Borda sutil
                      // Sombra removida
                    ),
                    child: const Icon(
                      Icons.add,
                      color: AppColors.primary, // Ícone verde
                      size: 24, // Aumentado levemente
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

