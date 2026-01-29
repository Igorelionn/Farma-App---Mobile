import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../../core/constants/app_constants.dart';

class OrderRepository {
  final SharedPreferences prefs;
  static const String _keyOrders = 'user_orders';
  List<Address>? _cachedAddresses;
  List<PaymentMethod>? _cachedPaymentMethods;
  
  OrderRepository({required this.prefs});
  
  // Carregar endereços mockados
  Future<List<Address>> getAddresses() async {
    if (_cachedAddresses != null) {
      return _cachedAddresses!;
    }
    
    try {
      final String response = await rootBundle.loadString('assets/data/addresses.json');
      final List<dynamic> addressesJson = json.decode(response);
      _cachedAddresses = addressesJson
          .map((json) => Address.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedAddresses!;
    } catch (e) {
      // Se não houver arquivo, retornar endereços padrão
      _cachedAddresses = [];
      return _cachedAddresses!;
    }
  }
  
  // Carregar formas de pagamento mockadas
  Future<List<PaymentMethod>> getPaymentMethods() async {
    if (_cachedPaymentMethods != null) {
      return _cachedPaymentMethods!;
    }
    
    try {
      final String response = await rootBundle.loadString('assets/data/payment_methods.json');
      final List<dynamic> paymentMethodsJson = json.decode(response);
      _cachedPaymentMethods = paymentMethodsJson
          .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();
      return _cachedPaymentMethods!;
    } catch (e) {
      _cachedPaymentMethods = [];
      return _cachedPaymentMethods!;
    }
  }
  
  // Criar pedido
  Future<Order> createOrder({
    required List<CartItem> items,
    required Address address,
    required PaymentMethod paymentMethod,
    required Map<String, double> totals,
  }) async {
    // Simular delay de API
    await Future.delayed(AppConstants.apiDelay);
    
    final now = DateTime.now();
    final orderNumber = 'PED${now.millisecondsSinceEpoch}';
    
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      number: orderNumber,
      date: now,
      status: OrderStatus.pending,
      items: items,
      subtotal: totals['subtotal']!,
      shipping: totals['shipping']!,
      discount: totals['discount']!,
      total: totals['total']!,
      address: address,
      paymentMethod: paymentMethod,
      estimatedDelivery: now.add(const Duration(days: 3)),
      statusHistory: [
        OrderStatusUpdate(
          status: OrderStatus.pending,
          date: now,
          description: 'Pedido realizado',
        ),
      ],
    );
    
    // Salvar pedido localmente
    final orders = await getOrders();
    orders.insert(0, order); // Adicionar no início
    await _saveOrders(orders);
    
    return order;
  }
  
  // Carregar pedidos do usuário
  Future<List<Order>> getOrders() async {
    try {
      final String? ordersJson = prefs.getString(_keyOrders);
      if (ordersJson == null || ordersJson.isEmpty) {
        // Carregar pedidos mockados iniciais
        return await _loadMockOrders();
      }
      
      final List<dynamic> ordersList = json.decode(ordersJson);
      return ordersList
          .map((order) => Order.fromJson(order as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return await _loadMockOrders();
    }
  }
  
  // Carregar pedidos mockados
  Future<List<Order>> _loadMockOrders() async {
    try {
      final String response = await rootBundle.loadString('assets/data/orders.json');
      final List<dynamic> ordersJson = json.decode(response);
      final orders = ordersJson
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
      await _saveOrders(orders);
      return orders;
    } catch (e) {
      return [];
    }
  }
  
  // Salvar pedidos
  Future<void> _saveOrders(List<Order> orders) async {
    final ordersJson = json.encode(orders.map((order) => order.toJson()).toList());
    await prefs.setString(_keyOrders, ordersJson);
  }
  
  // Filtrar pedidos por status
  Future<List<Order>> getOrdersByStatus(OrderStatus? status) async {
    final orders = await getOrders();
    
    if (status == null) {
      return orders;
    }
    
    return orders.where((order) => order.status == status).toList();
  }
  
  // Obter detalhes do pedido
  Future<Order?> getOrderById(String orderId) async {
    final orders = await getOrders();
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }
  
  // Cancelar pedido (mockado)
  Future<Order> cancelOrder(String orderId) async {
    await Future.delayed(AppConstants.apiDelay);
    
    final orders = await getOrders();
    final index = orders.indexWhere((order) => order.id == orderId);
    
    if (index != -1) {
      final order = orders[index];
      if (order.canCancel) {
        final updatedHistory = List<OrderStatusUpdate>.from(order.statusHistory ?? []);
        updatedHistory.add(OrderStatusUpdate(
          status: OrderStatus.cancelled,
          date: DateTime.now(),
          description: 'Pedido cancelado',
        ));
        
        final cancelledOrder = Order(
          id: order.id,
          number: order.number,
          date: order.date,
          status: OrderStatus.cancelled,
          items: order.items,
          subtotal: order.subtotal,
          shipping: order.shipping,
          discount: order.discount,
          total: order.total,
          address: order.address,
          paymentMethod: order.paymentMethod,
          trackingCode: order.trackingCode,
          estimatedDelivery: order.estimatedDelivery,
          statusHistory: updatedHistory,
        );
        
        orders[index] = cancelledOrder;
        await _saveOrders(orders);
        return cancelledOrder;
      }
    }
    
    throw Exception('Não foi possível cancelar o pedido');
  }
}


