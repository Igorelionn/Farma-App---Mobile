import 'package:equatable/equatable.dart';
import '../../../data/models/order.dart';

abstract class OrdersEvent extends Equatable {
  const OrdersEvent();
  
  @override
  List<Object?> get props => [];
}

class LoadOrders extends OrdersEvent {}

class FilterOrders extends OrdersEvent {
  final OrderStatus? status;
  
  const FilterOrders({this.status});
  
  @override
  List<Object?> get props => [status];
}

class RefreshOrders extends OrdersEvent {}

class CancelOrder extends OrdersEvent {
  final String orderId;
  
  const CancelOrder({required this.orderId});
  
  @override
  List<Object?> get props => [orderId];
}


