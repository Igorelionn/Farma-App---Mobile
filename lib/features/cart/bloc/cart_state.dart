import 'package:equatable/equatable.dart';
import '../../../data/models/cart_item.dart';

abstract class CartState extends Equatable {
  const CartState();
  
  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final int itemCount;
  final Map<String, double> totals;
  
  const CartLoaded({
    required this.items,
    required this.itemCount,
    required this.totals,
  });
  
  bool get isEmpty => items.isEmpty;
  
  double get subtotal => totals['subtotal'] ?? 0;
  double get shipping => totals['shipping'] ?? 0;
  double get discount => totals['discount'] ?? 0;
  double get total => totals['total'] ?? 0;
  
  @override
  List<Object?> get props => [items, itemCount, totals];
}

class CartEmpty extends CartState {}

class CartError extends CartState {
  final String message;
  
  const CartError({required this.message});
  
  @override
  List<Object?> get props => [message];
}


