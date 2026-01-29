import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../data/repositories/order_repository.dart';
import 'orders_event.dart';
import 'orders_state.dart';

class OrdersBloc extends Bloc<OrdersEvent, OrdersState> {
  final OrderRepository orderRepository;
  
  OrdersBloc({required this.orderRepository}) : super(OrdersInitial()) {
    on<LoadOrders>(_onLoadOrders);
    on<FilterOrders>(_onFilterOrders);
    on<RefreshOrders>(_onRefreshOrders);
    on<CancelOrder>(_onCancelOrder);
  }
  
  Future<void> _onLoadOrders(
    LoadOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    
    try {
      final orders = await orderRepository.getOrders();
      
      if (orders.isEmpty) {
        emit(OrdersEmpty());
      } else {
        emit(OrdersLoaded(orders: orders));
      }
    } catch (e) {
      emit(OrdersError(message: e.toString()));
    }
  }
  
  Future<void> _onFilterOrders(
    FilterOrders event,
    Emitter<OrdersState> emit,
  ) async {
    emit(OrdersLoading());
    
    try {
      final orders = await orderRepository.getOrdersByStatus(event.status);
      
      if (orders.isEmpty) {
        emit(OrdersEmpty());
      } else {
        emit(OrdersLoaded(
          orders: orders,
          currentFilter: event.status,
        ));
      }
    } catch (e) {
      emit(OrdersError(message: e.toString()));
    }
  }
  
  Future<void> _onRefreshOrders(
    RefreshOrders event,
    Emitter<OrdersState> emit,
  ) async {
    // Manter o estado atual durante o refresh
    final currentState = state;
    
    try {
      final currentFilter = currentState is OrdersLoaded 
          ? currentState.currentFilter 
          : null;
      
      final orders = await orderRepository.getOrdersByStatus(currentFilter);
      
      if (orders.isEmpty) {
        emit(OrdersEmpty());
      } else {
        emit(OrdersLoaded(
          orders: orders,
          currentFilter: currentFilter,
        ));
      }
    } catch (e) {
      emit(OrdersError(message: e.toString()));
    }
  }
  
  Future<void> _onCancelOrder(
    CancelOrder event,
    Emitter<OrdersState> emit,
  ) async {
    final currentState = state;
    
    emit(OrderCancelling(orderId: event.orderId));
    
    try {
      final cancelledOrder = await orderRepository.cancelOrder(event.orderId);
      emit(OrderCancelled(order: cancelledOrder));
      
      // Recarregar lista de pedidos
      if (currentState is OrdersLoaded) {
        add(FilterOrders(status: currentState.currentFilter));
      } else {
        add(LoadOrders());
      }
    } catch (e) {
      emit(OrdersError(message: e.toString()));
      
      // Restaurar estado anterior
      if (currentState is OrdersLoaded) {
        emit(currentState);
      } else {
        add(LoadOrders());
      }
    }
  }
}


