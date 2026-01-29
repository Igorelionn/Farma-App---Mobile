import 'package:equatable/equatable.dart';
import '../../../data/models/order.dart';

abstract class OrdersState extends Equatable {
  const OrdersState();
  
  @override
  List<Object?> get props => [];
}

class OrdersInitial extends OrdersState {}

class OrdersLoading extends OrdersState {}

class OrdersLoaded extends OrdersState {
  final List<Order> orders;
  final OrderStatus? currentFilter;
  
  const OrdersLoaded({
    required this.orders,
    this.currentFilter,
  });
  
  bool get isEmpty => orders.isEmpty;
  
  @override
  List<Object?> get props => [orders, currentFilter];
}

class OrdersEmpty extends OrdersState {}

class OrdersError extends OrdersState {
  final String message;
  
  const OrdersError({required this.message});
  
  @override
  List<Object?> get props => [message];
}

class OrderCancelling extends OrdersState {
  final String orderId;
  
  const OrderCancelling({required this.orderId});
  
  @override
  List<Object?> get props => [orderId];
}

class OrderCancelled extends OrdersState {
  final Order order;
  
  const OrderCancelled({required this.order});
  
  @override
  List<Object?> get props => [order];
}


