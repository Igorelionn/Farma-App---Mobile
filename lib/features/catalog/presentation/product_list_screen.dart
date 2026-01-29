import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../favorites/bloc/favorites_bloc.dart';

class ProductListScreen extends StatefulWidget {
  final String? category;
  final String? searchQuery;
  
  const ProductListScreen({
    super.key, 
    this.category,
    this.searchQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;
  String? _selectedLaboratorio;
  String _sortBy = 'relevance';
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.category;
    
    // Se veio uma query de busca por voz, preencher o campo
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
      context.read<CatalogBloc>().add(
        SearchProducts(query: widget.searchQuery!),
      );
    } else if (widget.category != null) {
      context.read<CatalogBloc>().add(
        FilterProducts(category: widget.category),
      );
    } else {
      context.read<CatalogBloc>().add(LoadProducts());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    context.read<CatalogBloc>().add(
      FilterProducts(
        category: _selectedCategory,
        laboratorio: _selectedLaboratorio,
        sortBy: _sortBy == 'relevance' ? null : _sortBy,
      ),
    );
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = null;
      _selectedLaboratorio = null;
      _sortBy = 'relevance';
    });
    context.read<CatalogBloc>().add(LoadProducts());
  }

  void _performSearch(String query) {
    if (query.isNotEmpty) {
      context.read<CatalogBloc>().add(SearchProducts(query: query));
    } else {
      context.read<CatalogBloc>().add(LoadProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedCategory ?? 'Produtos'),
        actions: [
          IconButton(
            icon: Icon(
              _showFilters ? Icons.filter_list_off : Icons.filter_list,
            ),
            onPressed: () {
              setState(() => _showFilters = !_showFilters);
            },
          ),
          IconButton(
            icon: const Icon(Icons.shopping_cart_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Carrinho será implementado na Fase 2'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.surface,
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar produtos...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _performSearch('');
                        },
                      )
                    : null,
              ),
              onChanged: _performSearch,
            ),
          ),
          
          // Filters Panel
          if (_showFilters) _buildFiltersPanel(),
          
          // Products List
          Expanded(
            child: BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                if (state is CatalogLoading) {
                  return const LoadingIndicator();
                }
                
                if (state is CatalogError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: () {
                      context.read<CatalogBloc>().add(LoadProducts());
                    },
                  );
                }
                
                if (state is CatalogLoaded) {
                  if (state.products.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: 'Nenhum produto encontrado',
                      message: 'Tente ajustar os filtros ou buscar por outro termo',
                      actionText: 'Limpar Filtros',
                      onActionPressed: _clearFilters,
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      context.read<CatalogBloc>().add(LoadProducts());
                    },
                    child: GridView.builder(
                      padding: const EdgeInsets.all(16),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: state.products.length,
                      itemBuilder: (context, index) {
                        final product = state.products[index];
                        return ProductCard(
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
                        );
                      },
                    ),
                  );
                }
                
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltersPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceVariant,
        border: Border(
          bottom: BorderSide(color: AppColors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filtros', style: AppTextStyles.h6),
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Limpar'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Category Filter
          Text('Categoria', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          BlocBuilder<CatalogBloc, CatalogState>(
            builder: (context, state) {
              if (state is CatalogLoaded) {
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...state.categories.map((category) {
                      final isSelected = _selectedCategory == category.nome;
                      return FilterChip(
                        label: Text(category.nome),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = selected ? category.nome : null;
                          });
                        },
                      );
                    }),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
          const SizedBox(height: 16),
          
          // Sort Options
          Text('Ordenar por', style: AppTextStyles.labelMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Relevância'),
                selected: _sortBy == 'relevance',
                onSelected: (selected) {
                  setState(() => _sortBy = 'relevance');
                },
              ),
              ChoiceChip(
                label: const Text('Menor Preço'),
                selected: _sortBy == 'preco_asc',
                onSelected: (selected) {
                  setState(() => _sortBy = 'preco_asc');
                },
              ),
              ChoiceChip(
                label: const Text('Maior Preço'),
                selected: _sortBy == 'preco_desc',
                onSelected: (selected) {
                  setState(() => _sortBy = 'preco_desc');
                },
              ),
              ChoiceChip(
                label: const Text('A-Z'),
                selected: _sortBy == 'nome_asc',
                onSelected: (selected) {
                  setState(() => _sortBy = 'nome_asc');
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _applyFilters,
              child: const Text('Aplicar Filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

