import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/catalog/bloc/catalog_bloc.dart';
import 'features/catalog/presentation/home_screen.dart';
import 'features/cart/bloc/cart_bloc.dart';
import 'features/cart/bloc/cart_event.dart';
import 'features/orders/bloc/orders_bloc.dart';
import 'features/orders/bloc/orders_event.dart';
import 'features/favorites/bloc/favorites_bloc.dart';
import 'features/favorites/bloc/favorites_event.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/product_repository.dart';
import 'data/repositories/cart_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/favorites_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;
  
  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => AuthRepository(prefs: prefs),
        ),
        RepositoryProvider(
          create: (context) => ProductRepository(),
        ),
        RepositoryProvider(
          create: (context) => CartRepository(prefs: prefs),
        ),
        RepositoryProvider(
          create: (context) => OrderRepository(prefs: prefs),
        ),
        RepositoryProvider(
          create: (context) => FavoritesRepository(prefs: prefs),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CatalogBloc(
              productRepository: context.read<ProductRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CartBloc(
              cartRepository: context.read<CartRepository>(),
            )..add(LoadCart()),
          ),
          BlocProvider(
            create: (context) => OrdersBloc(
              orderRepository: context.read<OrderRepository>(),
            )..add(LoadOrders()),
          ),
          BlocProvider(
            create: (context) => FavoritesBloc(
              favoritesRepository: context.read<FavoritesRepository>(),
            )..add(LoadFavorites()),
          ),
        ],
        child: MaterialApp(
          title: 'Suevit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: const SplashScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
            '/home': (context) => const HomeScreen(),
          },
        ),
      ),
    );
  }
}

