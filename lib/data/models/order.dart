import 'package:equatable/equatable.dart';
import 'cart_item.dart';
import 'address.dart';
import 'payment_method.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
}

class Order extends Equatable {
  final String id;
  final String number;
  final String userId;
  final DateTime date;
  final OrderStatus status;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final Address? address;
  final PaymentMethod? paymentMethod;
  final String? addressId;
  final String? paymentMethodId;
  final String? trackingCode;
  final DateTime? estimatedDelivery;
  final List<OrderStatusUpdate>? statusHistory;
  
  const Order({
    required this.id,
    required this.number,
    required this.userId,
    required this.date,
    required this.status,
    this.items = const [],
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    this.address,
    this.paymentMethod,
    this.addressId,
    this.paymentMethodId,
    this.trackingCode,
    this.estimatedDelivery,
    this.statusHistory,
  });
  
  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendente';
      case OrderStatus.confirmed:
        return 'Confirmado';
      case OrderStatus.processing:
        return 'Em Separação';
      case OrderStatus.shipped:
        return 'Enviado';
      case OrderStatus.delivered:
        return 'Entregue';
      case OrderStatus.cancelled:
        return 'Cancelado';
    }
  }
  
  bool get canCancel => 
      status == OrderStatus.pending || status == OrderStatus.confirmed || status == OrderStatus.processing;

  static OrderStatus _parseStatus(String statusStr) {
    return OrderStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => OrderStatus.pending,
    );
  }
  
  factory Order.fromJson(Map<String, dynamic> json) {
    Address? address;
    if (json['addresses'] != null && json['addresses'] is Map) {
      address = Address.fromJson(json['addresses'] as Map<String, dynamic>);
    } else if (json['address'] != null && json['address'] is Map) {
      address = Address.fromJson(json['address'] as Map<String, dynamic>);
    }

    PaymentMethod? paymentMethod;
    if (json['payment_methods'] != null && json['payment_methods'] is Map) {
      paymentMethod = PaymentMethod.fromJson(json['payment_methods'] as Map<String, dynamic>);
    } else if (json['paymentMethod'] != null && json['paymentMethod'] is Map) {
      paymentMethod = PaymentMethod.fromJson(json['paymentMethod'] as Map<String, dynamic>);
    }

    List<CartItem> items = [];
    if (json['order_items'] != null && json['order_items'] is List) {
      items = (json['order_items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } else if (json['items'] != null && json['items'] is List) {
      items = (json['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    List<OrderStatusUpdate>? history;
    if (json['order_status_history'] != null && json['order_status_history'] is List) {
      history = (json['order_status_history'] as List)
          .map((h) => OrderStatusUpdate.fromJson(h as Map<String, dynamic>))
          .toList();
    } else if (json['statusHistory'] != null && json['statusHistory'] is List) {
      history = (json['statusHistory'] as List)
          .map((h) => OrderStatusUpdate.fromJson(h as Map<String, dynamic>))
          .toList();
    }

    return Order(
      id: json['id'] as String,
      number: json['number'] as String,
      userId: json['user_id'] as String? ?? '',
      date: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(),
      status: _parseStatus(json['status'] as String),
      items: items,
      subtotal: (json['subtotal'] as num? ?? 0).toDouble(),
      shipping: (json['shipping'] as num? ?? 0).toDouble(),
      discount: (json['discount'] as num? ?? 0).toDouble(),
      total: (json['total'] as num? ?? 0).toDouble(),
      address: address,
      paymentMethod: paymentMethod,
      addressId: json['address_id'] as String?,
      paymentMethodId: json['payment_method_id'] as String?,
      trackingCode: json['tracking_code'] as String? ?? json['trackingCode'] as String?,
      estimatedDelivery: json['estimated_delivery'] != null
          ? DateTime.parse(json['estimated_delivery'] as String)
          : json['estimatedDelivery'] != null
              ? DateTime.parse(json['estimatedDelivery'] as String)
              : null,
      statusHistory: history,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'number': number,
      'user_id': userId,
      'status': status.name,
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'address_id': addressId ?? address?.id,
      'payment_method_id': paymentMethodId ?? paymentMethod?.id,
      'tracking_code': trackingCode,
      'estimated_delivery': estimatedDelivery?.toIso8601String(),
    };
  }
  
  @override
  List<Object?> get props => [
    id, number, userId, date, status, items, subtotal, shipping, 
    discount, total, address, paymentMethod, trackingCode,
    estimatedDelivery, statusHistory,
  ];
}

class OrderStatusUpdate extends Equatable {
  final String? id;
  final String? orderId;
  final OrderStatus status;
  final DateTime date;
  final String? description;
  
  const OrderStatusUpdate({
    this.id,
    this.orderId,
    required this.status,
    required this.date,
    this.description,
  });
  
  factory OrderStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdate(
      id: json['id'] as String?,
      orderId: json['order_id'] as String?,
      status: Order._parseStatus(json['status'] as String),
      date: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : json['date'] != null
              ? DateTime.parse(json['date'] as String)
              : DateTime.now(),
      description: json['description'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'order_id': orderId,
      'status': status.name,
      'description': description,
    };
  }
  
  @override
  List<Object?> get props => [id, orderId, status, date, description];
}
