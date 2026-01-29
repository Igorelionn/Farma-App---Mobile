import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/error_widget.dart';
import '../../../core/widgets/svg_icon.dart';
import '../../../core/widgets/morph_dock.dart';
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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia';
    } else if (hour < 18) {
      return 'Boa tarde';
    } else {
      return 'Boa noite';
    }
  }

  // Helper para navegar garantindo acesso aos Blocs
  void _navigateToProductList({String? category, String? searchQuery}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => BlocProvider.value(
          value: context.read<CatalogBloc>(),
          child: ProductListScreen(
            category: category,
            searchQuery: searchQuery,
          ),
        ),
      ),
    );
  }

  void _navigateToProductDetails(String productId) {
    Navigator.push(
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent, // Fundo transparente para o AppBar padrão
        elevation: 0,
        toolbarHeight: 100, // Aumenta a altura do toolbar
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(
              bottom: Radius.circular(32), // Arredondamento inferior
            ),
            // Sombra removida
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        String greeting;
                        String userName = 'Convidado';
                        
                        if (state is AuthAuthenticated) {
                          greeting = _getGreeting();
                          userName = state.user.nome.split(' ').first;
                        } else {
                          greeting = 'Bem-vindo(a)';
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center, // Centraliza verticalmente
                          children: [
                            Text(
                              greeting,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if (state is AuthAuthenticated)
                              Text(
                                userName,
                                style: AppTextStyles.h5.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              )
                            else
                              GestureDetector(
                                onTap: () => Navigator.of(context).pushNamed('/login'),
                                child: Row(
                                  children: [
                                    Text(
                                      'Faça login',
                                      style: AppTextStyles.h5.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF424242),
                                      ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Icon(
                                    Icons.arrow_forward,
                                    size: 20,
                                    color: Color(0xFF424242),
                                  ),
                                  ],
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return GestureDetector(
                        onTap: () {
                          if (state is! AuthAuthenticated) {
                            Navigator.of(context).pushNamed('/login');
                          } else {
                            setState(() {
                              _selectedIndex = 4;
                            });
                          }
                        },
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: const Color(0xFFF5F5F5),
                          child: state is AuthAuthenticated
                              ? Text(
                                  state.user.nome.split(' ').first[0].toUpperCase(),
                                  style: AppTextStyles.h5.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : const Icon(
                                  Icons.person_outline,
                                  color: AppColors.textSecondary,
                                  size: 28,
                                ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 96), // Espaço para o dock
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                _buildHomeContent(),
                _buildOffersContent(),
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
              items: [
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/home_icon.svg',
                    size: 26,
                    color: _selectedIndex == 0 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: 'Início',
                ),
                MorphDockItem(
                  icon: Icon(
                    Icons.local_offer_outlined,
                    size: 26,
                    color: _selectedIndex == 1 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: 'Ofertas',
                ),
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/categories_icon.svg',
                    size: 26,
                    color: _selectedIndex == 2 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: 'Categorias',
                ),
                MorphDockItem(
                  icon: Icon(
                    Icons.favorite_outline,
                    size: 26,
                    color: _selectedIndex == 3 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: 'Favoritos',
                ),
                MorphDockItem(
                  icon: SvgIcon(
                    assetPath: 'assets/icons/profile_icon.svg',
                    size: 26,
                    color: _selectedIndex == 4 ? AppColors.primary : AppColors.textSecondary,
                  ),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ],
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Animated Search Bar
                  AnimatedSearchBar(
                    onTap: () => _navigateToProductList(),
                    onVoiceSearch: (searchText) => _navigateToProductList(searchQuery: searchText),
                  ),
                  
                  // Greeting (Moved to AppBar, removing here to avoid duplication if needed, but user asked for banners below search bar)
                  // The user instruction: "abaixo da barra de pesquisa deve ter banners, abaixo dos banner deve ter Recomendados"
                  
                  const SizedBox(height: 24),

                  // Banners Section
                  const HomeBanners(),
                  
                  const SizedBox(height: 24),

                  // Recomendados Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recomendados', style: AppTextStyles.h5),
                      TextButton(
              onPressed: () => _navigateToProductList(),
                        child: Text(
                          'Ver todos',
                          style: AppTextStyles.buttonSmall.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Using existing horizontal products list for Recomendados
                  _buildHorizontalProducts(state.products.take(8).toList()),

                  const SizedBox(height: 24),
                  
                  // Categories Section
                  Text('Categorias', style: AppTextStyles.h5),
                  const SizedBox(height: 16),
                  _buildCategoriesHorizontal(state.categories),
                  const SizedBox(height: 24),
                  
                  // Promotional Products
                  if (state.promotionalProducts != null && 
                      state.promotionalProducts!.isNotEmpty) ...[
                    Text('Ofertas da Semana', style: AppTextStyles.h5),
                    const SizedBox(height: 12),
                    _buildPromotionalProducts(state.promotionalProducts!),
                    const SizedBox(height: 24),
                  ],
                  
                  // Featured Products
                  Text('Destaques', style: AppTextStyles.h5),
                  const SizedBox(height: 12),
                  _buildHorizontalProducts(state.products.skip(8).take(8).toList()),
                  const SizedBox(height: 24),
                  
                  // Best Sellers
                  Text('Mais Vendidos', style: AppTextStyles.h5),
                  const SizedBox(height: 12),
                  _buildHorizontalProducts(state.products.skip(16).take(8).toList()),
                  const SizedBox(height: 24),
                  
                  // New Products
                  Text('Lançamentos', style: AppTextStyles.h5),
                  const SizedBox(height: 12),
                  _buildHorizontalProducts(state.products.skip(24).take(8).toList()),
                ],
              ),
            ),
          );
        }
        
        return const SizedBox.shrink();
      },
    );
  }



  Widget _buildCategoriesHorizontal(List categories) {
    return SizedBox(
      height: 120, // Altura aumentada para acomodar 2 linhas de texto
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length + 1, // +1 para "Todas"
        itemBuilder: (context, index) {
          // Primeiro item: "Todas as categorias"
          if (index == 0) {
            return Container(
              margin: const EdgeInsets.only(right: 16),
              child: AllCategoriesCard(
                      onTap: () => _navigateToProductList(),
              ),
            );
          }
          
          // Demais categorias
          final category = categories[index - 1];
          return Container(
            margin: EdgeInsets.only(
              right: index < categories.length ? 16 : 0,
            ),
            child: CategoryCard(
              category: category,
              onTap: () => _navigateToProductList(category: category.nome),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionalProducts(List products) {
    return SizedBox(
      height: 310, // Altura aumentada
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 160, // Largura padronizada
            margin: EdgeInsets.only(right: index < products.length - 1 ? 20 : 0),
            child: ProductCard(
              product: product,
              onTap: () {
                _navigateToProductDetails(product.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalProducts(List products) {
    return SizedBox(
      height: 310, // Altura aumentada para cards de produtos
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Container(
            width: 160, // Largura de cada card
            margin: EdgeInsets.only(right: index < products.length - 1 ? 20 : 0), // Espaçamento aumentado
            child: ProductCard(
              product: product,
              onTap: () {
                _navigateToProductDetails(product.id);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildOffersContent() {
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
          // Filtrar apenas produtos em promoção
          final offersProducts = state.products.where((p) => p.emPromocao).toList();

          return RefreshIndicator(
            onRefresh: () async {
              context.read<CatalogBloc>().add(LoadProducts());
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ofertas Especiais', style: AppTextStyles.h4),
                  const SizedBox(height: 8),
                  Text(
                    'Aproveite os melhores preços!',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (offersProducts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.local_offer_outlined,
                            size: 80,
                            color: AppColors.textTertiary,
                          ),
                            const SizedBox(height: 16),
                            Text(
                              'Nenhuma oferta disponível no momento',
                              style: AppTextStyles.bodyLarge.copyWith(
                                color: AppColors.textSecondary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio: 0.52,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: offersProducts.length,
                      itemBuilder: (context, index) {
                        final product = offersProducts[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                              _navigateToProductDetails(product.id);
                          },
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
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.8,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: state.categories.length,
                    itemBuilder: (context, index) {
                      final category = state.categories[index];
                      return CategoryCard(
                        category: category,
                        onTap: () {
                          _navigateToProductList(category: category.nome);
                        },
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
                          user.nome[0].toUpperCase(),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Endereços serão implementados na Fase 2'),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Configurações serão implementadas na Fase 2'),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: 'Ajuda',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ajuda será implementada na Fase 2'),
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
                      child: state is AuthAuthenticated
                          ? Text(
                              state.user.nome.split(' ').first[0].toUpperCase(),
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
                    setState(() {
                      _selectedIndex = 1;
                    });
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

