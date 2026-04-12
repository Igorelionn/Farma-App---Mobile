import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthState;
import 'package:gotrue/gotrue.dart' show AuthChangeEvent;
import 'core/services/supabase_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/bloc/auth_bloc.dart';
import 'features/auth/bloc/auth_event.dart';
import 'features/auth/bloc/auth_state.dart';
import 'features/auth/presentation/splash_screen.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/auth/presentation/register_screen.dart';
import 'features/auth/presentation/pending_approval_screen.dart';
import 'features/auth/presentation/register_success_screen.dart';
import 'features/auth/presentation/reset_password_screen.dart';
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
  await SupabaseService.initialize();
  runApp(const MyApp());
}

class _AppWithAuthListener extends StatefulWidget {
  @override
  State<_AppWithAuthListener> createState() => _AppWithAuthListenerState();
}

class _AppWithAuthListenerState extends State<_AppWithAuthListener> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    
    // Listener para deep links de recuperação de senha
    SupabaseService.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      
      if (event == AuthChangeEvent.passwordRecovery) {
        // Aguarda um frame para garantir que o navigator está pronto
        Future.delayed(const Duration(milliseconds: 500), () {
          _navigatorKey.currentState?.pushNamed('/reset-password');
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (previous, current) =>
          previous is! AuthAuthenticated && current is AuthAuthenticated,
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.read<CartBloc>().add(LoadCart());
          context.read<OrdersBloc>().add(LoadOrders());
          context.read<FavoritesBloc>().add(LoadFavorites());
        }
      },
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'Suevit',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/register-success': (context) => const RegisterSuccessScreen(),
          '/pending-approval': (context) => const PendingApprovalScreen(),
          '/home': (context) => const HomeScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
        },
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (context) => AuthRepository(),
        ),
        RepositoryProvider(
          create: (context) => ProductRepository(),
        ),
        RepositoryProvider(
          create: (context) => CartRepository(),
        ),
        RepositoryProvider(
          create: (context) => OrderRepository(),
        ),
        RepositoryProvider(
          create: (context) => FavoritesRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepository>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => CatalogBloc(
              productRepository: context.read<ProductRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => CartBloc(
              cartRepository: context.read<CartRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => OrdersBloc(
              orderRepository: context.read<OrderRepository>(),
            ),
          ),
          BlocProvider(
            create: (context) => FavoritesBloc(
              favoritesRepository: context.read<FavoritesRepository>(),
            ),
          ),
        ],
        child: _AppWithAuthListener(),
      ),
    );
  }
}
