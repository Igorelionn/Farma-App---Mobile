import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/favorites_repository.dart';
import 'favorites_event.dart';
import 'favorites_state.dart';

class FavoritesBloc extends Bloc<FavoritesEvent, FavoritesState> {
  final FavoritesRepository favoritesRepository;
  
  FavoritesBloc({required this.favoritesRepository}) : super(FavoritesInitial()) {
    on<LoadFavorites>(_onLoadFavorites);
    on<ToggleFavorite>(_onToggleFavorite);
    on<AddToFavorites>(_onAddToFavorites);
    on<RemoveFromFavorites>(_onRemoveFromFavorites);
  }
  
  Future<void> _onLoadFavorites(
    LoadFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    emit(FavoritesLoading());
    
    try {
      final favoriteIds = await favoritesRepository.getFavorites();
      
      if (favoriteIds.isEmpty) {
        emit(FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(favoriteIds: favoriteIds));
      }
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
    }
  }
  
  Future<void> _onToggleFavorite(
    ToggleFavorite event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final favoriteIds = await favoritesRepository.toggleFavorite(event.productId);
      
      if (favoriteIds.isEmpty) {
        emit(FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(favoriteIds: favoriteIds));
      }
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
      add(LoadFavorites());
    }
  }
  
  Future<void> _onAddToFavorites(
    AddToFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final favoriteIds = await favoritesRepository.addToFavorites(event.productId);
      emit(FavoritesLoaded(favoriteIds: favoriteIds));
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
      add(LoadFavorites());
    }
  }
  
  Future<void> _onRemoveFromFavorites(
    RemoveFromFavorites event,
    Emitter<FavoritesState> emit,
  ) async {
    try {
      final favoriteIds = await favoritesRepository.removeFromFavorites(event.productId);
      
      if (favoriteIds.isEmpty) {
        emit(FavoritesEmpty());
      } else {
        emit(FavoritesLoaded(favoriteIds: favoriteIds));
      }
    } catch (e) {
      emit(FavoritesError(message: e.toString()));
      add(LoadFavorites());
    }
  }
}


