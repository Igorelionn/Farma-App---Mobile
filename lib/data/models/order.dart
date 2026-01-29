import 'package:equatable/equatable.dart';
import 'cart_item.dart';
import 'address.dart';
import 'payment_method.dart';

enum OrderStatus {
  pending,
  processing,
  shipped,
  delivered,
  cancelled,
}

class Order extends Equatable {
  final String id;
  final String number;
  final DateTime date;
  final OrderStatus status;
  final List<CartItem> items;
  final double subtotal;
  final double shipping;
  final double discount;
  final double total;
  final Address address;
  final PaymentMethod paymentMethod;
  final String? trackingCode;
  final DateTime? estimatedDelivery;
  final List<OrderStatusUpdate>? statusHistory;
  
  const Order({
    required this.id,
    required this.number,
    required this.date,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.shipping,
    required this.discount,
    required this.total,
    required this.address,
    required this.paymentMethod,
    this.trackingCode,
    this.estimatedDelivery,
    this.statusHistory,
  });
  
  String get statusLabel {
    switch (status) {
      case OrderStatus.pending:
        return 'Pendente';
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
      status == OrderStatus.pending || status == OrderStatus.processing;
  
  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      number: json['number'] as String,
      date: DateTime.parse(json['date'] as String),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
      ),
      items: (json['items'] as List)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      subtotal: (json['subtotal'] as num).toDouble(),
      shipping: (json['shipping'] as num).toDouble(),
      discount: (json['discount'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      address: Address.fromJson(json['address'] as Map<String, dynamic>),
      paymentMethod: PaymentMethod.fromJson(
        json['paymentMethod'] as Map<String, dynamic>,
      ),
      trackingCode: json['trackingCode'] as String?,
      estimatedDelivery: json['estimatedDelivery'] != null
          ? DateTime.parse(json['estimatedDelivery'] as String)
          : null,
      statusHistory: json['statusHistory'] != null
          ? (json['statusHistory'] as List)
              .map((h) => OrderStatusUpdate.fromJson(h as Map<String, dynamic>))
              .toList()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'number': number,
      'date': date.toIso8601String(),
      'status': status.toString().split('.').last,
      'items': items.map((item) => item.toJson()).toList(),
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
      'total': total,
      'address': address.toJson(),
      'paymentMethod': paymentMethod.toJson(),
      'trackingCode': trackingCode,
      'estimatedDelivery': estimatedDelivery?.toIso8601String(),
      'statusHistory': statusHistory?.map((h) => h.toJson()).toList(),
    };
  }
  
  @override
  List<Object?> get props => [
    id, number, date, status, items, subtotal, shipping, 
    discount, total, address, paymentMethod, trackingCode,
    estimatedDelivery, statusHistory,
  ];
}

class OrderStatusUpdate extends Equatable {
  final OrderStatus status;
  final DateTime date;
  final String? description;
  
  const OrderStatusUpdate({
    required this.status,
    required this.date,
    this.description,
  });
  
  factory OrderStatusUpdate.fromJson(Map<String, dynamic> json) {
    return OrderStatusUpdate(
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${json['status']}',
      ),
      date: DateTime.parse(json['date'] as String),
      description: json['description'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'status': status.toString().split('.').last,
      'date': date.toIso8601String(),
      'description': description,
    };
  }
  
  @override
  List<Object?> get props => [status, date, description];
}


