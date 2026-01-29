import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/product.dart';
import '../../catalog/presentation/product_details_screen.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../catalog/bloc/catalog_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../bloc/favorites_bloc.dart';
import '../bloc/favorites_event.dart';
import '../bloc/favorites_state.dart';
import '../widgets/favorite_product_card.dart';
import 'shopping_lists_screen.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favoritos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.list_alt),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ShoppingListsScreen(),
                ),
              );
            },
            tooltip: 'Listas de Compras',
          ),
        ],
      ),
      body: BlocBuilder<FavoritesBloc, FavoritesState>(
        builder: (context, state) {
          if (state is FavoritesLoading) {
            return const LoadingIndicator();
          }
          
          if (state is FavoritesError) {
            return CustomErrorWidget(
              message: state.message,
              onRetry: () {
                context.read<FavoritesBloc>().add(LoadFavorites());
              },
            );
          }
          
          if (state is FavoritesEmpty) {
            return EmptyState(
              icon: Icons.favorite_border,
              title: 'Nenhum Favorito',
              message: 'Adicione produtos aos favoritos para vê-los aqui',
              actionText: 'Ver Catálogo',
              onActionPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
          
          if (state is FavoritesLoaded) {
            return FutureBuilder<List<Product>>(
              future: _loadFavoriteProducts(context, state.favoriteIds),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const LoadingIndicator();
                }
                
                if (snapshot.hasError) {
                  return CustomErrorWidget(
                    message: snapshot.error.toString(),
                    onRetry: () {
                      context.read<FavoritesBloc>().add(LoadFavorites());
                    },
                  );
                }
                
                final products = snapshot.data ?? [];
                
                if (products.isEmpty) {
                  return EmptyState(
                    icon: Icons.favorite_border,
                    title: 'Nenhum Favorito',
                    message: 'Adicione produtos aos favoritos para vê-los aqui',
                    actionText: 'Ver Catálogo',
                    onActionPressed: () {
                      Navigator.of(context).pop();
                    },
                  );
                }
                
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return FavoriteProductCard(
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
                      onRemove: () {
                        context.read<FavoritesBloc>().add(
                          RemoveFromFavorites(productId: product.id),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.nome} removido dos favoritos'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      onAddToCart: () {
                        context.read<CartBloc>().add(
                          AddToCart(product: product),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.nome} adicionado ao carrinho'),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          }
          
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Future<List<Product>> _loadFavoriteProducts(
    BuildContext context,
    List<String> favoriteIds,
  ) async {
    final productRepo = context.read<ProductRepository>();
    final allProducts = await productRepo.getAllProducts();
    
    return allProducts
        .where((product) => favoriteIds.contains(product.id))
        .toList();
  }
}


