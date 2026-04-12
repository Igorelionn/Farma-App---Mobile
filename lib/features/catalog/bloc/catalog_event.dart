import 'package:equatable/equatable.dart';

abstract class CatalogEvent extends Equatable {
  const CatalogEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadProducts extends CatalogEvent {}

class LoadCategories extends CatalogEvent {}

class SearchProducts extends CatalogEvent {
  final String query;
  
  const SearchProducts({required this.query});
  
  @override
  List<Object?> get props => [query];
}

class FilterProducts extends CatalogEvent {
  final String? category;
  final String? laboratorio;
  final double? minPrice;
  final double? maxPrice;
  final bool? disponivel;
  final String? sortBy;
  
  const FilterProducts({
    this.category,
    this.laboratorio,
    this.minPrice,
    this.maxPrice,
    this.disponivel,
    this.sortBy,
  });
  
  @override
  List<Object?> get props => [
    category,
    laboratorio,
    minPrice,
    maxPrice,
    disponivel,
    sortBy,
  ];
}

class LoadProductDetails extends CatalogEvent {
  final String productId;
  
  const LoadProductDetails({required this.productId});
  
  @override
  List<Object?> get props => [productId];
}

class LoadPromotionalProducts extends CatalogEvent {}

class ProductsUpdatedFromRealtime extends CatalogEvent {}

