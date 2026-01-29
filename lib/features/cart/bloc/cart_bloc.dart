import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository cartRepository;
  
  CartBloc({required this.cartRepository}) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<UpdateQuantity>(_onUpdateQuantity);
    on<ClearCart>(_onClearCart);
  }
  
  Future<void> _onLoadCart(
    LoadCart event,
    Emitter<CartState> emit,
  ) async {
    emit(CartLoading());
    
    try {
      final items = await cartRepository.getCartItems();
      
      if (items.isEmpty) {
        emit(CartEmpty());
      } else {
        final itemCount = await cartRepository.getItemCount();
        final totals = await cartRepository.calculateTotals();
        
        emit(CartLoaded(
          items: items,
          itemCount: itemCount,
          totals: totals,
        ));
      }
    } catch (e) {
      emit(CartError(message: e.toString()));
    }
  }
  
  Future<void> _onAddToCart(
    AddToCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = await cartRepository.addToCart(
        event.product,
        quantity: event.quantity,
      );
      
      final itemCount = await cartRepository.getItemCount();
      final totals = await cartRepository.calculateTotals();
      
      emit(CartLoaded(
        items: items,
        itemCount: itemCount,
        totals: totals,
      ));
    } catch (e) {
      emit(CartError(message: e.toString()));
      // Recarregar o estado anterior
      add(LoadCart());
    }
  }
  
  Future<void> _onRemoveFromCart(
    RemoveFromCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = await cartRepository.removeFromCart(event.itemId);
      
      if (items.isEmpty) {
        emit(CartEmpty());
      } else {
        final itemCount = await cartRepository.getItemCount();
        final totals = await cartRepository.calculateTotals();
        
        emit(CartLoaded(
          items: items,
          itemCount: itemCount,
          totals: totals,
        ));
      }
    } catch (e) {
      emit(CartError(message: e.toString()));
      add(LoadCart());
    }
  }
  
  Future<void> _onUpdateQuantity(
    UpdateQuantity event,
    Emitter<CartState> emit,
  ) async {
    try {
      final items = await cartRepository.updateQuantity(
        event.itemId,
        event.newQuantity,
      );
      
      if (items.isEmpty) {
        emit(CartEmpty());
      } else {
        final itemCount = await cartRepository.getItemCount();
        final totals = await cartRepository.calculateTotals();
        
        emit(CartLoaded(
          items: items,
          itemCount: itemCount,
          totals: totals,
        ));
      }
    } catch (e) {
      emit(CartError(message: e.toString()));
      add(LoadCart());
    }
  }
  
  Future<void> _onClearCart(
    ClearCart event,
    Emitter<CartState> emit,
  ) async {
    try {
      await cartRepository.clearCart();
      emit(CartEmpty());
    } catch (e) {
      emit(CartError(message: e.toString()));
    }
  }
}


