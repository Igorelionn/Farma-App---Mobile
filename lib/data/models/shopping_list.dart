import 'package:equatable/equatable.dart';

class ShoppingList extends Equatable {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> productIds; // IDs dos produtos
  
  const ShoppingList({
    required this.id,
    required this.name,
    required this.createdAt,
    this.updatedAt,
    required this.productIds,
  });
  
  int get itemCount => productIds.length;
  
  ShoppingList copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? productIds,
  }) {
    return ShoppingList(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productIds: productIds ?? this.productIds,
    );
  }
  
  factory ShoppingList.fromJson(Map<String, dynamic> json) {
    return ShoppingList(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      productIds: List<String>.from(json['productIds'] as List),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'productIds': productIds,
    };
  }
  
  @override
  List<Object?> get props => [id, name, createdAt, updatedAt, productIds];
}


