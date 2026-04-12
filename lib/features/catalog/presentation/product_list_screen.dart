import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/svg_icon.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../widgets/product_card.dart';
import 'product_details_screen.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../favorites/bloc/favorites_bloc.dart';

class ProductListScreen extends StatefulWidget {
  final String? categoryId;
  final String? categoryName;
  final String? searchQuery;
  
  const ProductListScreen({
    super.key, 
    this.categoryId,
    this.categoryName,
    this.searchQuery,
  });

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounceTimer;
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  String? _selectedLaboratorio;
  String _sortBy = 'relevance';
  bool _showFilters = false;
  List<String> _searchHistory = [];
  final FocusNode _searchFocusNode = FocusNode();
  bool _showSearchHistory = false;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = widget.categoryId;
    _selectedCategoryName = widget.categoryName;
    _loadSearchHistory();
    
    // Focar automaticamente na barra de pesquisa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _searchFocusNode.requestFocus();
    });
    
    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchHistory = _searchFocusNode.hasFocus && _searchController.text.isEmpty;
      });
    });
    
    if (widget.searchQuery != null) {
      _searchController.text = widget.searchQuery!;
      context.read<CatalogBloc>().add(
        SearchProducts(query: widget.searchQuery!),
      );
    } else if (widget.categoryId != null) {
      context.read<CatalogBloc>().add(
        FilterProducts(category: widget.categoryId),
      );
    }
    // Não carrega produtos inicialmente - só mostra histórico
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Future<void> _loadSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _searchHistory = prefs.getStringList('search_history') ?? [];
    });
  }

  Future<void> _saveSearchHistory(String query) async {
    if (query.trim().isEmpty) return;
    
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    _searchHistory.insert(0, query);
    
    if (_searchHistory.length > 10) {
      _searchHistory = _searchHistory.sublist(0, 10);
    }
    
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _removeSearchHistoryItem(String query) async {
    final prefs = await SharedPreferences.getInstance();
    _searchHistory.remove(query);
    await prefs.setStringList('search_history', _searchHistory);
    setState(() {});
  }

  Future<void> _clearSearchHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('search_history');
    setState(() {
      _searchHistory = [];
    });
  }

  void _applyFilters() {
    context.read<CatalogBloc>().add(
      FilterProducts(
        category: _selectedCategoryId,
        laboratorio: _selectedLaboratorio,
        sortBy: _sortBy == 'relevance' ? null : _sortBy,
      ),
    );
    setState(() => _showFilters = false);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
      _selectedLaboratorio = null;
      _sortBy = 'relevance';
    });
    context.read<CatalogBloc>().add(LoadProducts());
  }

  void _performSearch(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted) return;
      if (query.isNotEmpty) {
        context.read<CatalogBloc>().add(SearchProducts(query: query));
        setState(() {
          _showSearchHistory = false;
        });
      } else {
        // Quando limpar, apenas mostra o histórico, não carrega produtos
        setState(() {
          _showSearchHistory = _searchFocusNode.hasFocus;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const SvgIcon(
            assetPath: 'assets/icons/arrow_back_icon.svg',
            size: 20,
            color: Colors.black,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
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
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocusNode,
                      textInputAction: TextInputAction.search,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        letterSpacing: 0.3,
                      ),
                      cursorColor: const Color(0xFF9CA3AF),
                      cursorHeight: 18,
                      decoration: InputDecoration(
                        hintText: 'Buscar produtos...',
                        hintStyle: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textTertiary,
                          letterSpacing: 0.3,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (value) {
                        _performSearch(value);
                        setState(() {});
                      },
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          _saveSearchHistory(value);
                          _searchFocusNode.unfocus();
                        }
                      },
                    ),
                  ),
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        _performSearch('');
                        setState(() {});
                      },
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.textTertiary,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Search History
          if (_showSearchHistory && _searchHistory.isNotEmpty)
            Container(
              color: Colors.white,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Histórico de busca',
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        TextButton(
                          onPressed: _clearSearchHistory,
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Limpar tudo',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.4,
                    ),
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      itemCount: _searchHistory.length,
                      itemBuilder: (context, index) {
                        final historyItem = _searchHistory[index];
                        return InkWell(
                          onTap: () {
                            _searchController.text = historyItem;
                            _performSearch(historyItem);
                            _searchFocusNode.unfocus();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.history,
                                  size: 18,
                                  color: AppColors.textTertiary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    historyItem,
                                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 14),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: AppColors.textTertiary,
                                  ),
                                  onPressed: () => _removeSearchHistoryItem(historyItem),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          
          // Products List
          Expanded(
            child: BlocBuilder<CatalogBloc, CatalogState>(
              builder: (context, state) {
                // Só mostra produtos se houver texto na busca
                if (_searchController.text.isEmpty) {
                  return const SizedBox.shrink();
                }
                
                if (state is CatalogLoading) {
                  return const LoadingIndicator();
                }
                
                if (state is CatalogError) {
                  return CustomErrorWidget(
                    message: state.message,
                    onRetry: () {
                      if (_searchController.text.isNotEmpty) {
                        context.read<CatalogBloc>().add(
                          SearchProducts(query: _searchController.text),
                        );
                      }
                    },
                  );
                }
                
                if (state is CatalogLoaded) {
                  if (state.products.isEmpty) {
                    return EmptyState(
                      icon: Icons.search_off,
                      title: 'Nenhum produto encontrado',
                      message: 'Tente buscar por outro termo',
                      actionText: null,
                      onActionPressed: null,
                    );
                  }
                  
                  return RefreshIndicator(
                    onRefresh: () async {
                      if (_searchController.text.isNotEmpty) {
                        context.read<CatalogBloc>().add(
                          SearchProducts(query: _searchController.text),
                        );
                      }
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
                      final isSelected = _selectedCategoryId == category.id;
                      return FilterChip(
                        label: Text(category.nome),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategoryId = selected ? category.id : null;
                            _selectedCategoryName = selected ? category.nome : null;
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

