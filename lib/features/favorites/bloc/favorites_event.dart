import 'package:equatable/equatable.dart';

abstract class FavoritesEvent extends Equatable {
  const FavoritesEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadFavorites extends FavoritesEvent {}

class ToggleFavorite extends FavoritesEvent {
  final String productId;
  
  const ToggleFavorite({required this.productId});
  
  @override
  List<Object?> get props => [productId];
}

class AddToFavorites extends FavoritesEvent {
  final String productId;
  
  const AddToFavorites({required this.productId});
  
  @override
  List<Object?> get props => [productId];
}

class RemoveFromFavorites extends FavoritesEvent {
  final String productId;
  
  const RemoveFromFavorites({required this.productId});
  
  @override
  List<Object?> get props => [productId];
}


