import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/product_repository.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../../favorites/bloc/favorites_event.dart';
import '../../favorites/bloc/favorites_state.dart';

class ProductDetailsScreen extends StatefulWidget {
  final String productId;
  
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  State<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int _quantity = 1;
  Product? _product;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  Future<void> _loadProduct() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final productRepository = context.read<ProductRepository>();
      final product = await productRepository.getProductById(widget.productId);
      
      if (product != null) {
        setState(() {
          _product = product;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Produto não encontrado';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar produto: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Produto'),
        actions: [
          if (_product != null)
            BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                final isFavorite = state is FavoritesLoaded &&
                    state.isFavorite(_product!.id);
                return IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: isFavorite ? AppColors.error : null,
                  ),
                  onPressed: () {
                    context.read<FavoritesBloc>().add(
                      ToggleFavorite(productId: _product!.id),
                    );
                  },
                );
              },
            ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Compartilhar será implementado em breve'),
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? CustomErrorWidget(
                  message: _errorMessage!,
                  onRetry: _loadProduct,
                )
              : _product != null
                  ? _buildProductDetails(_product!)
                  : const SizedBox.shrink(),
    );
  }

  Widget _buildProductDetails(Product product) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Container(
                  height: 300,
                  width: double.infinity,
                  color: AppColors.surfaceVariant,
                  child: Stack(
                    children: [
                      if (product.imagemUrl != null && product.imagemUrl!.isNotEmpty)
                        Center(
                          child: CachedNetworkImage(
                            imageUrl: product.imagemUrl!,
                            height: 300,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            placeholder: (_, __) => const Center(
                              child: SizedBox(
                                width: 28,
                                height: 28,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            errorWidget: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.medication_rounded,
                                size: 100,
                                color: AppColors.textTertiary,
                              ),
                            ),
                          ),
                        )
                      else
                        const Center(
                          child: Icon(
                            Icons.medication_rounded,
                            size: 100,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      // Badges
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (product.emPromocao)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'PROMOÇÃO',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            if (product.tarja != null) ...[
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getTarjaColor(product.tarja!),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  'TARJA ${product.tarja!.toUpperCase()}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Product Info
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title and Laboratory
                      Text(product.nome, style: AppTextStyles.h4),
                      const SizedBox(height: 8),
                      Text(
                        product.laboratorio,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.apresentacao,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Price
                      if (product.emPromocao && product.precoPromocional != null) ...[
                        Text(
                          Formatters.currency(product.preco),
                          style: AppTextStyles.bodyLarge.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          Formatters.currency(product.precoPromocional!),
                          style: AppTextStyles.priceMain,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Economize ${Formatters.currency(product.preco - product.precoPromocional!)}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ] else
                        Text(
                          Formatters.currency(product.preco),
                          style: AppTextStyles.priceMain,
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Stock Status
                      Row(
                        children: [
                          Icon(
                            product.disponivel && product.estoque > 0
                                ? Icons.check_circle
                                : Icons.cancel,
                            color: product.disponivel && product.estoque > 0
                                ? AppColors.success
                                : AppColors.error,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            product.disponivel && product.estoque > 0
                                ? 'Em estoque (${product.estoque} unidades)'
                                : 'Indisponível',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: product.disponivel && product.estoque > 0
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      const Divider(),
                      const SizedBox(height: 24),
                      
                      // Additional Info
                      if (product.principioAtivo != null) ...[
                        _buildInfoRow('Princípio Ativo', product.principioAtivo!),
                        const SizedBox(height: 12),
                      ],
                      
                      _buildInfoRow('Categoria', product.categoria),
                      const SizedBox(height: 12),
                      
                      _buildInfoRow('Unidade', product.unidade),
                      const SizedBox(height: 12),
                      
                      if (product.codigoBarras != null) ...[
                        _buildInfoRow('Código de Barras', product.codigoBarras!),
                        const SizedBox(height: 12),
                      ],
                      
                      if (product.classificacaoFiscal != null) ...[
                        _buildInfoRow('Classificação Fiscal', product.classificacaoFiscal!),
                        const SizedBox(height: 12),
                      ],
                      
                      if (product.isControlado) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: AppColors.warning.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_amber,
                                color: AppColors.warning,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Medicamento controlado. Requer receita especial.',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                      
                      // Description
                      if (product.descricao != null) ...[
                        const Divider(),
                        const SizedBox(height: 24),
                        Text('Descrição', style: AppTextStyles.h6),
                        const SizedBox(height: 12),
                        Text(
                          product.descricao!,
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Bottom Bar with Add to Cart
        if (product.disponivel && product.estoque > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  // Quantity Selector
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: _quantity > 1
                              ? () {
                                  setState(() => _quantity--);
                                }
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            _quantity.toString(),
                            style: AppTextStyles.h6,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: _quantity < product.estoque
                              ? () {
                                  setState(() => _quantity++);
                                }
                              : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Add to Cart Button
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        context.read<CartBloc>().add(
                          AddToCart(product: product, quantity: _quantity),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '$_quantity x ${product.nome} adicionado${_quantity > 1 ? 's' : ''} ao carrinho',
                            ),
                            backgroundColor: AppColors.success,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A1A),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.shopping_bag_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Adicionar',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  Color _getTarjaColor(String tarja) {
    switch (tarja.toLowerCase()) {
      case 'vermelha':
        return AppColors.tarjaVermelha;
      case 'preta':
        return AppColors.tarjaPreta;
      case 'amarela':
        return AppColors.tarjaAmarela;
      default:
        return AppColors.textSecondary;
    }
  }
}

