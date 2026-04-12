import 'package:equatable/equatable.dart';
import 'product.dart';

class CartItem extends Equatable {
  final String id;
  final String userId;
  final String productId;
  final Product? product;
  final int quantity;
  final DateTime addedAt;
  
  const CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    this.product,
    required this.quantity,
    required this.addedAt,
  });
  
  double get subtotal => (product?.precoFinal ?? 0) * quantity;
  
  bool get isValid => product != null && product!.disponivel && product!.estoque >= quantity;
  
  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    Product? product,
    int? quantity,
    DateTime? addedAt,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
    );
  }
  
  factory CartItem.fromJson(Map<String, dynamic> json) {
    Product? product;
    if (json['products'] != null && json['products'] is Map) {
      product = Product.fromJson(json['products'] as Map<String, dynamic>);
    } else if (json['product'] != null && json['product'] is Map) {
      product = Product.fromJson(json['product'] as Map<String, dynamic>);
    }

    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      productId: json['product_id'] as String,
      product: product,
      quantity: json['quantity'] as int,
      addedAt: json['added_at'] != null
          ? DateTime.parse(json['added_at'] as String)
          : DateTime.now(),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
    };
  }
  
  @override
  List<Object?> get props => [id, userId, productId, product, quantity, addedAt];
}
