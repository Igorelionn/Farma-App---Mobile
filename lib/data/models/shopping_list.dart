import 'package:equatable/equatable.dart';

class ShoppingList extends Equatable {
  final String id;
  final String userId;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> productIds;
  
  const ShoppingList({
    required this.id,
    required this.userId,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    required this.productIds,
  });
  
  int get itemCount => productIds.length;
  
  ShoppingList copyWith({
    String? id,
    String? userId,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? productIds,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productIds: productIds ?? this.productIds,
    );
  }
  
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    List<String> productIds = [];
    if (json['shopping_list_items'] != null && json['shopping_list_items'] is List) {
      productIds = (json['shopping_list_items'] as List)
          .map((item) => (item as Map<String, dynamic>)['product_id'] as String)
          .toList();
    } else if (json['productIds'] != null) {
      productIds = List<String>.from(json['productIds'] as List);
    }

    return ShoppingList(
      id: json['id'] as String,
      userId: json['user_id'] as String? ?? '',
      name: json['name'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['createdAt'] != null
              ? DateTime.parse(json['createdAt'] as String)
              : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : json['updatedAt'] != null
              ? DateTime.parse(json['updatedAt'] as String)
              : null,
      productIds: productIds,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'name': name,
    };
  }
  
  @override
  List<Object?> get props => [id, userId, name, createdAt, updatedAt, productIds];
}
