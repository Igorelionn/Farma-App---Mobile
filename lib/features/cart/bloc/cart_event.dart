import 'package:equatable/equatable.dart';
import '../../../data/models/product.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {}

class AddToCart extends CartEvent {
  final Product product;
  final int quantity;
  
  const AddToCart({
    required this.product,
    this.quantity = 1,
  });
  
  @override
  List<Object?> get props => [product, quantity];
}

class RemoveFromCart extends CartEvent {
  final String itemId;
  
  const RemoveFromCart({required this.itemId});
  
  @override
  List<Object?> get props => [itemId];
}

class UpdateQuantity extends CartEvent {
  final String itemId;
  final int newQuantity;
  
  const UpdateQuantity({
    required this.itemId,
    required this.newQuantity,
  });
  
  @override
  List<Object?> get props => [itemId, newQuantity];
}

class ClearCart extends CartEvent {}


