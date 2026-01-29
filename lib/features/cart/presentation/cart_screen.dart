import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../bloc/cart_bloc.dart';
import '../bloc/cart_event.dart';
import '../bloc/cart_state.dart';
import '../widgets/cart_item_card.dart';
import '../widgets/cart_summary.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrinho'),
        actions: [
          BlocBuilder<CartBloc, CartState>(
            builder: (context, state) {
              if (state is CartLoaded && !state.isEmpty) {
                return TextButton.icon(
                  onPressed: () {
                    _showClearCartDialog(context);
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Limpar'),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
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
            return EmptyState(
              icon: Icons.shopping_cart_outlined,
              title: 'Carrinho Vazio',
              message: 'Adicione produtos ao carrinho para continuar',
              actionText: 'Ver Catálogo',
              onActionPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
          
          if (state is CartLoaded) {
            return Column(
              children: [
                // Items List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return CartItemCard(
                        item: item,
                        onRemove: () {
                          _showRemoveItemDialog(
                            context,
                            item.id,
                            item.product.nome,
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
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Remover Item'),
          content: Text('Deseja remover "$productName" do carrinho?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<CartBloc>().add(RemoveFromCart(itemId: itemId));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Item removido do carrinho'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Remover',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showClearCartDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Limpar Carrinho'),
          content: const Text('Deseja remover todos os itens do carrinho?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<CartBloc>().add(ClearCart());
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Carrinho limpo'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Limpar',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}


