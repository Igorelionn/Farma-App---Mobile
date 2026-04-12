import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../core/widgets/morph_dock.dart';
import '../../../core/widgets/cart_notification_provider.dart';
import '../../../data/models/user.dart';
import '../../auth/bloc/auth_bloc.dart';
import '../../auth/bloc/auth_state.dart';
import '../../auth/bloc/auth_event.dart';
import '../bloc/catalog_bloc.dart';
import '../bloc/catalog_event.dart';
import '../bloc/catalog_state.dart';
import '../../cart/bloc/cart_bloc.dart';
import '../../cart/bloc/cart_state.dart';
import '../../cart/presentation/cart_screen.dart';
import '../../orders/presentation/orders_screen.dart';
import '../../favorites/presentation/favorites_screen.dart';
import '../../favorites/bloc/favorites_bloc.dart';
import '../widgets/category_card.dart';
import '../widgets/all_categories_card.dart';
import '../widgets/product_card.dart';
import '../widgets/animated_search_bar.dart';
import '../widgets/home_banners.dart';
import 'product_list_screen.dart';
import 'product_details_screen.dart';
import 'categories_screen.dart';
import '../../profile/presentation/settings_screen.dart';
import '../../profile/presentation/help_screen.dart';
import '../../profile/presentation/about_screen.dart';
import '../../profile/presentation/addresses_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _showNavNotification = false;
  String _notificationText = '';

  @override
  void initState() {
    super.initState();
    // Load products and categories
    context.read<CatalogBloc>().add(LoadProducts());
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _showCartNotification(String productName) {
    setState(() {
      _showNavNotification = true;
      _notificationText = productName;
    });

    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) {
        setState(() {
          _showNavNotification = false;
        });
      }
    });
  }

  String _getGreetingEmoji() {
    return '👋';
  }

  void _navigateToProductList({String? categoryId, String? categoryName, String? searchQuery}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CatalogBloc>()),
            BlocProvider.value(value: context.read<CartBloc>()),
            BlocProvider.value(value: context.read<FavoritesBloc>()),
          ],
          child: ProductListScreen(
            categoryId: categoryId,
            categoryName: categoryName,
            searchQuery: searchQuery,
          ),
        ),
      ),
    );
    if (mounted) {
      context.read<CatalogBloc>().add(LoadProducts());
    }
  }

  void _navigateToProductDetails(String productId) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<CatalogBloc>()),
            BlocProvider.value(value: context.read<CartBloc>()),
            BlocProvider.value(value: context.read<FavoritesBloc>()),
          ],
          child: ProductDetailsScreen(productId: productId),
        ),
      ),
    );
    if (mounted) {
      context.read<CatalogBloc>().add(LoadProducts());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          color: Colors.white,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      if (_selectedIndex == 0)
                        Expanded(
                          child: BlocBuilder<AuthBloc, AuthState>(
                            builder: (context, state) {
                              if (state is AuthAuthenticated) {
                                final firstName = state.user.nome.isNotEmpty
                                    ? state.user.nome.split(' ').first
                                    : 'Usuário';
                                return Text(
                                  'Olá, $firstName ${_getGreetingEmoji()}',
                                  style: AppTextStyles.h5.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 26,
                                    letterSpacing: -0.3,
                                  ),
                                );
                              } else {
                                return GestureDetector(
                                  onTap: () => Navigator.of(context).pushNamed('/login'),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Bem-vindo! Faça login',
                                        style: AppTextStyles.h5.copyWith(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 17,
                                          color: const Color(0xFF424242),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        size: 18,
                                        color: Color(0xFF424242),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        )
                      else
                        const Spacer(),
                      BlocBuilder<CartBloc, CartState>(
                        builder: (context, cartState) {
                          final itemCount = cartState is CartLoaded ? cartState.itemCount : 0;
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const CartScreen(),
                                ),
                              );
                            },
                            child: SizedBox(
                              width: 42,
                              height: 42,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SvgIcon(
                                    assetPath: 'assets/icons/cart_icon.svg',
                                    size: 26,
                                    color: AppColors.textPrimary.withValues(alpha: 0.75),
                                  ),
                                  if (itemCount > 0)
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: Container(
                                        width: 16,
                                        height: 16,
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            itemCount > 9 ? '9+' : itemCount.toString(),
                                            style: const TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF020B21),
                                              height: 1,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: CartNotificationProvider(
        onProductAdded: _showCartNotification,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 110), // Espaço para o dock + barra de navegação do Android
              child: IndexedStack(
                index: _selectedIndex,
                children: [
                  _buildHomeContent(),
                  const CartScreen(),
                  _buildCategoriesContent(),
                  const FavoritesScreen(),
                  _buildProfileContent(),
                ],
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: MorphDock(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              showNotification: _showNavNotification,
              notificationText: _notificationText,
              onViewCart: () {
                setState(() {
                  _showNavNotification = false;
                  _selectedIndex = 1; // Índice da aba da cesta
                });
              },
              items: [
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/home_icon.svg',
                    size: 24,
                    color: _selectedIndex == 0 ? const Color(0xFF020B21) : Colors.white.withValues(alpha: 0.7),
                  ),
                  label: 'Início',
                ),
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/cart_icon.svg',
                    size: 24,
                    color: _selectedIndex == 1 ? const Color(0xFF020B21) : Colors.white.withValues(alpha: 0.7),
                  ),
                  label: 'Cesta',
                ),
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/categories_icon.svg',
                    size: 24,
                    color: _selectedIndex == 2 ? const Color(0xFF020B21) : Colors.white.withValues(alpha: 0.7),
                  ),
                  label: 'Categorias',
                ),
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/favorite_icon.svg',
                    size: 24,
                    color: _selectedIndex == 3 ? const Color(0xFF020B21) : Colors.white.withValues(alpha: 0.7),
                  ),
                  label: 'Favoritos',
                ),
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/profile_icon.svg',
                    size: 24,
                    color: _selectedIndex == 4 ? const Color(0xFF020B21) : Colors.white.withValues(alpha: 0.7),
                  ),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  Widget _buildHomeContent() {
    return BlocBuilder<CatalogBloc, CatalogState>(
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
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CatalogBloc>().add(LoadProducts());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: AnimatedSearchBar(
                      onSearch: (query) => _navigateToProductList(searchQuery: query),
                      onVoiceSearch: (searchText) => _navigateToProductList(searchQuery: searchText),
                    ),
                  ),
                  
                  const SizedBox(height: 24),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: HomeBanners(
                      onCategoryTap: (categoryId, categoryName) {
                        _navigateToProductList(
                          categoryId: categoryId,
                          categoryName: categoryName,
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 28),

                  _buildSectionHeader('Recomendados', showViewAll: true, onViewAll: () {
                    _navigateToProductList();
                  }),
                  const SizedBox(height: 14),
                  _buildHorizontalProducts(state.products.take(8).toList()),

                  const SizedBox(height: 28),
                  
                  _buildSectionHeader('Categorias', showViewAll: false),
                  const SizedBox(height: 14),
                  _buildCategoriesHorizontal(state.categories),
                  const SizedBox(height: 32),
                  
                  if (state.promotionalProducts != null && 
                      state.promotionalProducts!.isNotEmpty) ...[
                    _buildSectionHeader('Ofertas da Semana', showViewAll: true, onViewAll: () {
                      _navigateToProductList(searchQuery: 'ofertas');
                    }),
                    const SizedBox(height: 14),
                    _buildPromotionalProducts(state.promotionalProducts!),
                    const SizedBox(height: 32),
                  ],
                  
                  _buildSectionHeader('Destaques', showViewAll: true, onViewAll: () {
                    _navigateToProductList(searchQuery: 'destaques');
                  }),
                  const SizedBox(height: 14),
                  _buildHorizontalProducts(state.products.skip(8).take(8).toList()),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Mais Vendidos', showViewAll: true, onViewAll: () {
                    _navigateToProductList(searchQuery: 'mais vendidos');
                  }),
                  const SizedBox(height: 14),
                  _buildHorizontalProducts(state.products.skip(16).take(8).toList()),
                  const SizedBox(height: 32),
                  
                  _buildSectionHeader('Promoções', showViewAll: true, onViewAll: () {
                    _navigateToProductList(searchQuery: 'promoções');
                  }),
                  const SizedBox(height: 14),
                  Builder(builder: (_) {
                    final promo = state.products.where((p) => p.emPromocao).take(8).toList();
                    return _buildHorizontalProducts(
                      promo.isEmpty ? state.products.skip(24).take(8).toList() : promo,
                    );
                  }),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }



  Widget _buildSectionHeader(String title, {bool showViewAll = false, VoidCallback? onViewAll}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            title,
            style: AppTextStyles.h5.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 19,
              letterSpacing: -0.4,
            ),
          ),
          if (showViewAll && onViewAll != null)
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'Ver tudo',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoriesHorizontal(List categories) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 20, right: 20),
        itemCount: categories.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return AllCategoriesCard(
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
                        child: const CategoriesScreen(),
                      ),
                    ),
                  );
                },
              );
          }

          final category = categories[index - 1];
          return CategoryCard(
              category: category,
              onTap: () => _navigateToProductList(
                  categoryId: category.id, categoryName: category.nome),
            );
        },
      ),
    );
  }

  Widget _buildPromotionalProducts(List products) {
    return SizedBox(
      height: 320,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcula largura para mostrar 2 produtos completos + um pouco do 3º
          final screenWidth = MediaQuery.of(context).size.width;
          final availableWidth = screenWidth - 40; // 20px padding de cada lado
          final itemWidth = (availableWidth - 24) / 2.2; // 2 espaçamentos de 12px, mostra 2.2 produtos
          
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: itemWidth,
                child: ProductCard(
                  product: product,
                  onTap: () {
                    _navigateToProductDetails(product.id);
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildHorizontalProducts(List products) {
    return SizedBox(
      height: 320,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Calcula largura para mostrar 2 produtos completos + um pouco do 3º
          final screenWidth = MediaQuery.of(context).size.width;
          final availableWidth = screenWidth - 40; // 20px padding de cada lado
          final itemWidth = (availableWidth - 24) / 2.2; // 2 espaçamentos de 12px, mostra 2.2 produtos
          
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: products.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final product = products[index];
              return SizedBox(
                width: itemWidth,
                child: ProductCard(
                  product: product,
                  onTap: () {
                    _navigateToProductDetails(product.id);
                  },
                ),
              );
            },
          );
        }
      ),
    );
  }

  Widget _buildCategoriesContent() {
    return BlocBuilder<CatalogBloc, CatalogState>(
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
          return RefreshIndicator(
            onRefresh: () async {
              context.read<CatalogBloc>().add(LoadProducts());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Categorias', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Navegue por categoria de produtos',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const spacing = 16.0;
                      const cols = 3;
                      final itemW = (constraints.maxWidth - spacing * (cols - 1)) / cols;
                      final itemH = itemW / 0.8;
                      final rows = (state.categories.length / cols).ceil();
                      final gridH = rows * itemH + (rows - 1) * spacing;
                      return SizedBox(
                        height: gridH,
                        child: GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: cols,
                            childAspectRatio: 0.8,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                          ),
                          itemCount: state.categories.length,
                          itemBuilder: (context, index) {
                            final category = state.categories[index];
                            return CategoryCard(
                              category: category,
                              onTap: () {
                                _navigateToProductList(categoryId: category.id, categoryName: category.nome);
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildProfileContent() {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        // Se não estiver autenticado, mostrar tela de convite para login
        if (state is! AuthAuthenticated) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 100,
                  color: AppColors.textTertiary,
                ),
                  const SizedBox(height: 24),
                  Text(
                    'Faça login para continuar',
                    style: AppTextStyles.h4,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Acesse sua conta para ver pedidos, favoritos e muito mais',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushNamed('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 48,
                        vertical: 16,
                      ),
                    ),
                    child: const Text('Fazer Login'),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Se estiver autenticado, mostrar perfil
        final User user = state.user;
        return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      child: Text(
                          user.nome.isNotEmpty ? user.nome[0].toUpperCase() : 'U',
                          style: AppTextStyles.h3.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(user.nome, style: AppTextStyles.h5),
                            const SizedBox(height: 4),
                            Text(user.empresa, style: AppTextStyles.bodyMedium),
                            const SizedBox(height: 4),
                            Text(user.email, style: AppTextStyles.caption),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Menu Options
                Text('Minha Conta', style: AppTextStyles.h6),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.receipt_long_outlined,
                  title: 'Meus Pedidos',
                  onTap: () {
                    // Navegar para tela de pedidos
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.favorite_outline,
                  title: 'Favoritos',
                  onTap: () {
                    setState(() => _selectedIndex = 3); // Índice correto para Favoritos
                  },
                ),
                _buildMenuItem(
                  icon: Icons.location_on_outlined,
                  title: 'Endereços',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AddressesScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
                
                Text('Configurações', style: AppTextStyles.h6),
                const SizedBox(height: 12),
                _buildMenuItem(
                  icon: Icons.settings_outlined,
                  title: 'Configurações',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Ajuda',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HelpScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.info_outline,
                  title: 'Sobre',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AboutScreen(),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.logout,
                  title: 'Sair',
                  textColor: AppColors.error,
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            ),
          );
      },
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: textColor ?? AppColors.textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: AppTextStyles.bodyMedium.copyWith(color: textColor),
            ),
          ),
          const Icon(
            Icons.chevron_right,
            color: AppColors.textTertiary,
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.white,
                      child: state is AuthAuthenticated && state.user.nome.isNotEmpty
                          ? Text(
                              state.user.nome[0].toUpperCase(),
                              style: AppTextStyles.h4.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                              size: 32,
                            ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      state is AuthAuthenticated
                          ? state.user.nome
                          : 'Convidado',
                      style: AppTextStyles.h6.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (state is AuthAuthenticated)
                      Text(
                      state.user.email,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                      ),
                  ],
                ),
              ),
              ListTile(
                leading: BlocBuilder<CartBloc, CartState>(
                  builder: (context, cartState) {
                    final itemCount = cartState is CartLoaded ? cartState.itemCount : 0;
                    return Badge(
                      label: Text(itemCount.toString()),
                      isLabelVisible: itemCount > 0,
                      child: const Icon(Icons.shopping_cart_outlined),
                    );
                  },
                ),
                title: const Text('Carrinho'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CartScreen(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_outlined),
                title: const Text('Notificações'),
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Notificações serão implementadas em breve'),
                    ),
                  );
                },
              ),
              const Divider(),
              if (state is AuthAuthenticated) ...[
                ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),
                  title: const Text('Meus Pedidos'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrdersScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Meu Perfil'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedIndex = 4;
                    });
                  },
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.logout, color: AppColors.error),
                  title: const Text(
                    'Sair',
                    style: TextStyle(color: AppColors.error),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                ),
              ] else ...[
                ListTile(
                  leading: const Icon(Icons.login, color: AppColors.primary),
                  title: const Text('Fazer Login'),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).pushNamed('/login');
                  },
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Sair'),
          content: const Text('Tem certeza que deseja sair?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                context.read<AuthBloc>().add(LogoutRequested());
              },
              child: const Text(
                'Sair',
                style: TextStyle(color: AppColors.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

