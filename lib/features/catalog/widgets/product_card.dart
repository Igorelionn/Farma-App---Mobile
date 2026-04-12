import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../data/models/product.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/cart_notification_provider.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../cart/bloc/cart_state.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/bloc/favorites_event.dart';
import '../../favorites/bloc/favorites_state.dart';

const _kCategoryPlaceholders = <String, _PlaceholderData>{
  'Medicamentos': _PlaceholderData(Icons.medication_rounded, Color(0xFF4CAF50), Color(0xFFF5F6F7)),
  'Material Hospitalar': _PlaceholderData(Icons.medical_services_rounded, Color(0xFF2196F3), Color(0xFFF5F6F7)),
  'Injetaveis': _PlaceholderData(Icons.vaccines_rounded, Color(0xFF9C27B0), Color(0xFFF5F6F7)),
  'Higiene e Dermocosmeticos': _PlaceholderData(Icons.spa_rounded, Color(0xFF009688), Color(0xFFF5F6F7)),
  'Limpeza e Desinfeccao': _PlaceholderData(Icons.cleaning_services_rounded, Color(0xFF00BCD4), Color(0xFFF5F6F7)),
  'Equipamentos e Nutricao': _PlaceholderData(Icons.monitor_heart_rounded, Color(0xFFFF9800), Color(0xFFF5F6F7)),
};

const _kDefaultPlaceholder = _PlaceholderData(Icons.inventory_2_rounded, Color(0xFF78909C), Color(0xFFF5F6F7));

class _PlaceholderData {
  final IconData icon;
  final Color color;
  final Color bg;
  const _PlaceholderData(this.icon, this.color, this.bg);
}

_PlaceholderData _getPlaceholder(String? categoryName) {
  if (categoryName == null) return _kDefaultPlaceholder;
  return _kCategoryPlaceholders[categoryName] ?? _kDefaultPlaceholder;
}

class ProductCard extends StatefulWidget {
  final Product product;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
  });

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  int _quantity = 0;

  @override
  Widget build(BuildContext context) {
    final placeholder = _getPlaceholder(widget.product.categoryNome);

    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0F0F0)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    color: const Color(0xFFF8F8F8),
                    child: _buildImage(placeholder),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.nome,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1A1A),
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.product.laboratorio,
                          style: const TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFAAAAAA),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        _buildPrice(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: _buildFavoriteButton(context),
            ),
            if (widget.product.disponivel && widget.product.estoque > 0)
              Positioned(
                top: 80,
                right: 8,
                child: _buildCartButton(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(_PlaceholderData placeholder) {
    if (widget.product.imagem != null && widget.product.imagem!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: widget.product.imagem!,
        width: double.infinity,
        height: 130,
        fit: BoxFit.contain,
        memCacheWidth: 260,
        memCacheHeight: 260,
        placeholder: (_, __) => _placeholderWidget(placeholder),
        errorWidget: (_, __, ___) => _placeholderWidget(placeholder),
        fadeInDuration: const Duration(milliseconds: 150),
      );
    }
    return _placeholderWidget(placeholder);
  }

  Widget _placeholderWidget(_PlaceholderData p) {
    return Center(
      child: Icon(p.icon, size: 36, color: p.color.withValues(alpha: 0.3)),
    );
  }

  Widget _buildPrice() {
    if (widget.product.emPromocao && widget.product.precoPromocional != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.currency(widget.product.preco),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w400,
              color: Color(0xFFBBBBBB),
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            Formatters.currency(widget.product.precoPromocional!),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
        ],
      );
    }
    return Text(
      Formatters.currency(widget.product.preco),
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: Color(0xFF1A1A1A),
      ),
    );
  }

  Widget _buildFavoriteButton(BuildContext context) {
    return BlocBuilder<FavoritesBloc, FavoritesState>(
      buildWhen: (prev, curr) {
        final wasFav = prev is FavoritesLoaded && prev.isFavorite(widget.product.id);
        final isFav = curr is FavoritesLoaded && curr.isFavorite(widget.product.id);
        return wasFav != isFav || curr is! FavoritesLoaded;
      },
      builder: (context, state) {
        final isFavorite =
            state is FavoritesLoaded && state.isFavorite(widget.product.id);
        return GestureDetector(
          onTap: () {
            context
                .read<FavoritesBloc>()
                .add(ToggleFavorite(productId: widget.product.id));
          },
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
              color: isFavorite ? const Color(0xFFEF4444) : const Color(0xFFCCCCCC),
              size: 16,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCartButton(BuildContext context) {
    if (_quantity == 0) {
      // Botão circular simples
      return GestureDetector(
        onTap: () {
          setState(() => _quantity = 1);
          context.read<CartBloc>().add(AddToCart(product: widget.product));
          
          // Usar o CartNotificationProvider para mostrar a notificação na nav bar
          CartNotificationProvider.of(context)?.onProductAdded(widget.product.nome);
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1.5,
            ),
          ),
          child: const Icon(
            Icons.add_rounded,
            color: Color(0xFF1A1A1A),
            size: 22,
          ),
        ),
      );
    }

    // Botão expandido com contador
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE0E0E0),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de diminuir
          GestureDetector(
            onTap: () {
              if (_quantity > 1) {
                setState(() => _quantity--);
                // Remover 1 unidade do carrinho
                context.read<CartBloc>().add(AddToCart(
                  product: widget.product,
                  quantity: -1,
                ));
              } else if (_quantity == 1) {
                // Remover completamente do carrinho
                final cartState = context.read<CartBloc>().state;
                if (cartState is CartLoaded) {
                  try {
                    final cartItem = cartState.items.firstWhere(
                      (item) => item.productId == widget.product.id,
                    );
                    setState(() => _quantity = 0);
                    context.read<CartBloc>().add(RemoveFromCart(itemId: cartItem.id));
                  } catch (e) {
                    // Item não encontrado no carrinho, apenas resetar o contador local
                    setState(() => _quantity = 0);
                  }
                } else {
                  setState(() => _quantity = 0);
                }
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.remove_rounded,
                color: Color(0xFF1A1A1A),
                size: 20,
              ),
            ),
          ),
          
          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              _quantity.toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ),
          
          // Botão de aumentar
          GestureDetector(
            onTap: () {
              if (_quantity < widget.product.estoque) {
                setState(() => _quantity++);
                context.read<CartBloc>().add(AddToCart(product: widget.product));
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Color(0xFF1A1A1A),
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
