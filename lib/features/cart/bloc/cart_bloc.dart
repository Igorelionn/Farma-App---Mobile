import 'dart:async';
import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
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
    
    if (errorStr.contains('estoque insuficiente') || errorStr.contains('sem estoque')) {
      return 'Produto sem estoque suficiente';
    }
    
    if (errorStr.contains('produto não disponível') || errorStr.contains('indisponível')) {
      return 'Produto não está mais disponível';
    }
    
    if (errorStr.contains('carrinho vazio')) {
      return 'Carrinho vazio';
    }
    
    // Retorna mensagem original se for algo específico
    String message = error.toString().replaceAll('Exception: ', '');
    if (!message.toLowerCase().contains('exception') && 
        !message.contains('Error:') &&
        message.length < 100) {
      return message;
    }
    
    return 'Erro ao processar operação. Tente novamente.';
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
      emit(CartError(message: _getFriendlyErrorMessage(e)));
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
      emit(CartError(message: _getFriendlyErrorMessage(e)));
    }
  }
}


