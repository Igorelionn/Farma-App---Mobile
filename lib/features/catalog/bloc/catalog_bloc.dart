import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../core/services/realtime_service.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final ProductRepository productRepository;
  StreamSubscription? _realtimeSubscription;

  // Cache local para evitar re-fetch desnecessário
  List<Category>? _cachedCategories;

  CatalogBloc({required this.productRepository}) : super(CatalogInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadCategories>(_onLoadCategories);
    on<SearchProducts>(_onSearchProducts);
    on<FilterProducts>(_onFilterProducts);
    on<LoadProductDetails>(_onLoadProductDetails);
    on<LoadPromotionalProducts>(_onLoadPromotionalProducts);
    on<ProductsUpdatedFromRealtime>(_onProductsUpdatedFromRealtime);

    _startRealtimeListener();
  }

  String _getFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    
    if (error is SocketException || errorStr.contains('socket')) {
      return 'Sem conexão com a internet. Verifique sua conexão e tente novamente.';
    }
    
    if (error is TimeoutException || errorStr.contains('timeout')) {
      return 'A conexão demorou muito. Verifique sua internet e tente novamente.';
    }
    
    if (error is http.ClientException || 
        errorStr.contains('clientexception') || 
        errorStr.contains('connection closed') ||
        errorStr.contains('failed host lookup')) {
      return 'Erro de conexão. Verifique sua internet e tente novamente.';
    }
    
    if (errorStr.contains('format') || errorStr.contains('json')) {
      return 'Erro ao processar dados. Tente novamente mais tarde.';
    }
    
    // Erro genérico
    return 'Não foi possível carregar os dados. Tente novamente.';
  }

  void _startRealtimeListener() {
    RealtimeService.subscribeToProducts();
    _realtimeSubscription = RealtimeService.productChanges.listen((_) {
      // Invalida cache ao receber update em tempo real
      _cachedCategories = null;
      add(ProductsUpdatedFromRealtime());
    });
  }

  Future<void> _onProductsUpdatedFromRealtime(
    ProductsUpdatedFromRealtime event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      final results = await Future.wait([
        productRepository.getAllProducts(),
        productRepository.getCategories(),
        productRepository.getPromotionalProducts(),
      ]);

      _cachedCategories = results[1] as List<Category>;

      emit(CatalogLoaded(
        products: results[0] as List<Product>,
        categories: results[1] as List<Category>,
        promotionalProducts: results[2] as List<Product>,
      ));
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao atualizar via realtime: $e');
    }
  }

  @override
  Future<void> close() {
    _realtimeSubscription?.cancel();
    RealtimeService.unsubscribeFromProducts();
    return super.close();
  }

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<CatalogState> emit,
  ) async {
    // Só emite loading se não há dados anteriores
    if (state is! CatalogLoaded) emit(CatalogLoading());

    try {
      // Carrega em paralelo
      final results = await Future.wait([
        productRepository.getAllProducts(),
        _cachedCategories != null
            ? Future.value(_cachedCategories)
            : productRepository.getCategories(),
        productRepository.getPromotionalProducts(),
      ]);

      _cachedCategories = results[1] as List<Category>;

      emit(CatalogLoaded(
        products: results[0] as List<Product>,
        categories: results[1] as List<Category>,
        promotionalProducts: results[2] as List<Product>,
      ));
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao carregar produtos: $e');
      emit(CatalogError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CatalogState> emit,
  ) async {
    if (state is! CatalogLoaded) emit(CatalogLoading());

    try {
      final results = await Future.wait([
        productRepository.getAllProducts(),
        _cachedCategories != null
            ? Future.value(_cachedCategories)
            : productRepository.getCategories(),
      ]);

      _cachedCategories = results[1] as List<Category>;

      emit(CatalogLoaded(
        products: results[0] as List<Product>,
        categories: results[1] as List<Category>,
      ));
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao carregar categorias: $e');
      emit(CatalogError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<CatalogState> emit,
  ) async {
    // Mantém lista anterior visível durante a busca
    if (state is! CatalogLoaded) emit(CatalogLoading());

    try {
      final products = await productRepository.searchProducts(event.query);
      final categories = _cachedCategories ?? await productRepository.getCategories();
      _cachedCategories ??= categories;

      emit(CatalogLoaded(
        products: products,
        categories: categories,
        searchQuery: event.query,
      ));
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao buscar produtos: $e');
      emit(CatalogError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onFilterProducts(
    FilterProducts event,
    Emitter<CatalogState> emit,
  ) async {
    if (state is! CatalogLoaded) emit(CatalogLoading());

    try {
      final products = await productRepository.filterProducts(
        category: event.category,
        laboratorio: event.laboratorio,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        disponivel: event.disponivel,
        sortBy: event.sortBy,
      );
      final categories = _cachedCategories ?? await productRepository.getCategories();
      _cachedCategories ??= categories;

      emit(CatalogLoaded(
        products: products,
        categories: categories,
      ));
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao filtrar produtos: $e');
      emit(CatalogError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onLoadProductDetails(
    LoadProductDetails event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());

    try {
      final product = await productRepository.getProductById(event.productId);

      if (product != null) {
        emit(ProductDetailsLoaded(product: product));
      } else {
        emit(const CatalogError(message: 'Produto não encontrado'));
      }
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao carregar produto: $e');
      emit(CatalogError(message: _getFriendlyErrorMessage(e)));
    }
  }

  Future<void> _onLoadPromotionalProducts(
    LoadPromotionalProducts event,
    Emitter<CatalogState> emit,
  ) async {
    if (state is! CatalogLoaded) emit(CatalogLoading());

    try {
      final results = await Future.wait([
        productRepository.getAllProducts(),
        _cachedCategories != null
            ? Future.value(_cachedCategories)
            : productRepository.getCategories(),
        productRepository.getPromotionalProducts(),
      ]);

      _cachedCategories = results[1] as List<Category>;

      emit(CatalogLoaded(
        products: results[0] as List<Product>,
        categories: results[1] as List<Category>,
        promotionalProducts: results[2] as List<Product>,
      ));
    } catch (e) {
      debugPrint('[CatalogBloc] Erro ao carregar promoções: $e');
      emit(CatalogError(message: _getFriendlyErrorMessage(e)));
    }
  }
}
