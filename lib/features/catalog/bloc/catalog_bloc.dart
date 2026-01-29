import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/product_repository.dart';
import 'catalog_event.dart';
import 'catalog_state.dart';

class CatalogBloc extends Bloc<CatalogEvent, CatalogState> {
  final ProductRepository productRepository;
  
  CatalogBloc({required this.productRepository}) : super(CatalogInitial()) {
    on<LoadProducts>(_onLoadProducts);
    on<LoadCategories>(_onLoadCategories);
    on<SearchProducts>(_onSearchProducts);
    on<FilterProducts>(_onFilterProducts);
    on<LoadProductDetails>(_onLoadProductDetails);
    on<LoadPromotionalProducts>(_onLoadPromotionalProducts);
  }
  
  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    
    try {
      final products = await productRepository.getAllProducts();
      final categories = await productRepository.getCategories();
      final promotionalProducts = await productRepository.getPromotionalProducts();
      
      emit(CatalogLoaded(
        products: products,
        categories: categories,
        promotionalProducts: promotionalProducts,
      ));
    } catch (e) {
      emit(CatalogError(message: 'Erro ao carregar produtos: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadCategories(
    LoadCategories event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      final categories = await productRepository.getCategories();
      final products = await productRepository.getAllProducts();
      
      emit(CatalogLoaded(
        products: products,
        categories: categories,
      ));
    } catch (e) {
      emit(CatalogError(message: 'Erro ao carregar categorias: ${e.toString()}'));
    }
  }
  
  Future<void> _onSearchProducts(
    SearchProducts event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    
    try {
      final products = await productRepository.searchProducts(event.query);
      final categories = await productRepository.getCategories();
      
      emit(CatalogLoaded(
        products: products,
        categories: categories,
        searchQuery: event.query,
      ));
    } catch (e) {
      emit(CatalogError(message: 'Erro ao buscar produtos: ${e.toString()}'));
    }
  }
  
  Future<void> _onFilterProducts(
    FilterProducts event,
    Emitter<CatalogState> emit,
  ) async {
    emit(CatalogLoading());
    
    try {
      final products = await productRepository.filterProducts(
        category: event.category,
        laboratorio: event.laboratorio,
        minPrice: event.minPrice,
        maxPrice: event.maxPrice,
        disponivel: event.disponivel,
        sortBy: event.sortBy,
      );
      final categories = await productRepository.getCategories();
      
      emit(CatalogLoaded(
        products: products,
        categories: categories,
      ));
    } catch (e) {
      emit(CatalogError(message: 'Erro ao filtrar produtos: ${e.toString()}'));
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
      emit(CatalogError(message: 'Erro ao carregar produto: ${e.toString()}'));
    }
  }
  
  Future<void> _onLoadPromotionalProducts(
    LoadPromotionalProducts event,
    Emitter<CatalogState> emit,
  ) async {
    try {
      final promotionalProducts = await productRepository.getPromotionalProducts();
      final products = await productRepository.getAllProducts();
      final categories = await productRepository.getCategories();
      
      emit(CatalogLoaded(
        products: products,
        categories: categories,
        promotionalProducts: promotionalProducts,
      ));
    } catch (e) {
      emit(CatalogError(message: 'Erro ao carregar promoções: ${e.toString()}'));
    }
  }
}

