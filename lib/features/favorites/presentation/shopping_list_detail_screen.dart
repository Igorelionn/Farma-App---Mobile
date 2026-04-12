import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/repositories/favorites_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/models/shopping_list.dart';
import '../../../data/models/product.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_event.dart';
import '../../catalog/presentation/product_details_screen.dart';
import '../../catalog/bloc/catalog_bloc.dart';
import '../bloc/favorites_bloc.dart';
import '../widgets/favorite_product_card.dart';

class ShoppingListDetailScreen extends StatefulWidget {
  final ShoppingList list;
  
  const ShoppingListDetailScreen({
    super.key,
    required this.list,
  });

  @override
  State<ShoppingListDetailScreen> createState() => _ShoppingListDetailScreenState();
}

class _ShoppingListDetailScreenState extends State<ShoppingListDetailScreen> {
  bool _isLoading = false;
  late ShoppingList _list;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _list = widget.list;
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    
    try {
      final productRepo = context.read<ProductRepository>();
      final allProducts = await productRepo.getAllProducts();
      
      setState(() {
        _products = allProducts
            .where((product) => _list.productIds.contains(product.id))
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar produtos: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_list.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showRenameDialog,
            tooltip: 'Renomear lista',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _products.isEmpty
              ? EmptyState(
                  icon: Icons.list_alt,
                  title: 'Lista Vazia',
                  message: 'Adicione produtos à lista através dos detalhes do produto',
                  actionText: 'Ver Catálogo',
                  onActionPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _products.length,
                        itemBuilder: (context, index) {
                          final product = _products[index];
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
                            onRemove: () => _removeProduct(product),
                            onAddToCart: () {
                              context.read<CartBloc>().add(
                                AddToCart(product: product),
                              );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.nome} adicionado à cesta'),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                    
                    // Add all to cart button
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
                        child: CustomButton(
                          text: 'Adicionar Todos à Cesta',
                          onPressed: _addAllToCart,
                          width: double.infinity,
                          icon: Icons.shopping_cart,
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Future<void> _removeProduct(Product product) async {
    try {
      final repo = context.read<FavoritesRepository>();
      final updatedList = await repo.removeProductFromList(_list.id, product.id);
      
      setState(() {
        _list = updatedList;
        _products.removeWhere((p) => p.id == product.id);
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${product.nome} removido da lista')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao remover produto: $e')),
        );
      }
    }
  }

  void _addAllToCart() {
    final cartBloc = context.read<CartBloc>();
    
    for (var product in _products) {
      cartBloc.add(AddToCart(product: product));
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_products.length} produtos adicionados à cesta'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRenameDialog() {
    final controller = TextEditingController(text: _list.name);
    
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Renomear Lista'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              labelText: 'Nome da lista',
            ),
            autofocus: true,
            textCapitalization: TextCapitalization.words,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                if (controller.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Digite um nome para a lista')),
                  );
                  return;
                }
                
                Navigator.pop(dialogContext);
                
                try {
                  final repo = context.read<FavoritesRepository>();
                  final updatedList = await repo.updateList(
                    _list.copyWith(name: controller.text.trim()),
                  );
                  
                  setState(() {
                    _list = updatedList;
                  });
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Lista renomeada')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erro ao renomear lista: $e')),
                    );
                  }
                }
              },
              child: const Text('Salvar'),
            ),
          ],
        );
      },
    );
  }
}


