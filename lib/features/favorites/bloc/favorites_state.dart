import 'package:equatable/equatable.dart';

abstract class FavoritesState extends Equatable {
  const FavoritesState();
  
  @override
  List<Object?> get props => [];
}

class FavoritesInitial extends FavoritesState {}

class FavoritesLoading extends FavoritesState {}

class FavoritesLoaded extends FavoritesState {
  final List<String> favoriteIds;
  
  const FavoritesLoaded({required this.favoriteIds});
  
  bool isFavorite(String productId) => favoriteIds.contains(productId);
  bool get isEmpty => favoriteIds.isEmpty;
  
  @override
  List<Object?> get props => [favoriteIds];
}

class FavoritesEmpty extends FavoritesState {}

class FavoritesError extends FavoritesState {
  final String message;
  
  const FavoritesError({required this.message});
  
  @override
  List<Object?> get props => [message];
}


