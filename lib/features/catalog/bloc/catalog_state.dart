import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';
import '../../../data/models/category.dart';

abstract class CatalogState extends Equatable {
  const CatalogState();
  
  @override
  List<Object?> get props => [];
}

class CatalogInitial extends CatalogState {}

class CatalogLoading extends CatalogState {}

class CatalogLoaded extends CatalogState {
  final List<Product> products;
  final List<Category> categories;
  final List<Product>? promotionalProducts;
  final String? searchQuery;
  
  const CatalogLoaded({
    required this.products,
    required this.categories,
    this.promotionalProducts,
    this.searchQuery,
  });
  
  @override
  List<Object?> get props => [products, categories, promotionalProducts, searchQuery];
}

class ProductDetailsLoaded extends CatalogState {
  final Product product;
  
  const ProductDetailsLoaded({required this.product});
  
  @override
  List<Object?> get props => [product];
}

class CatalogError extends CatalogState {
  final String message;
  
  const CatalogError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

