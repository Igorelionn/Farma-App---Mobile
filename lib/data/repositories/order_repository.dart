import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/order.dart';
import '../models/cart_item.dart';
import '../models/address.dart';
import '../models/payment_method.dart';
import '../../core/services/supabase_service.dart';

class OrderRepository {
  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => SupabaseService.currentUserId;
  
  Future<List<Address>> getAddresses() async {
    if (_userId == null) return [];

    final response = await _client.from('addresses')
        .select()
        .eq('user_id', _userId!)
        .order('is_default', ascending: false);
    
    return (response as List)
        .map((json) => Address.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<Address> addAddress(Address address) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final data = address.toJson();
    data['user_id'] = _userId;

    final response = await _client.from('addresses')
        .insert(data)
        .select()
        .single();

    return Address.fromJson(response);
  }
  
  Future<List<PaymentMethod>> getPaymentMethods() async {
    final response = await _client.from('payment_methods')
        .select()
        .eq('active', true)
        .order('label');
    
    return (response as List)
        .map((json) => PaymentMethod.fromJson(json as Map<String, dynamic>))
        .where((method) => method.type != PaymentType.accountCredit) // Filtra "Saldo da Conta"
        .toList();
  }
  
  Future<Order> createOrder({
    required List<CartItem> items,
    required Address address,
    required PaymentMethod paymentMethod,
    required Map<String, double> totals,
  }) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final now = DateTime.now();
    final orderNumber = 'PED${now.millisecondsSinceEpoch}';

    // Preparar itens para a RPC
    final itemsJson = items.map((item) => {
      'product_id': item.productId,
      'quantity': item.quantity,
      'unit_price': item.product?.precoFinal ?? 0,
      'subtotal': item.subtotal,
    }).toList();

    // Usar RPC atômico para criar pedido + itens + histórico em uma transação
    final orderId = await _client.rpc('create_order_atomic', params: {
      'p_order_number': orderNumber,
      'p_user_id': _userId,
      'p_address_id': address.id,
      'p_payment_method_id': paymentMethod.id,
      'p_subtotal': totals['subtotal'],
      'p_shipping': totals['shipping'],
      'p_discount': totals['discount'],
      'p_total': totals['total'],
      'p_notes': null,
      'p_items': itemsJson,
    });

    // Buscar pedido completo criado
    final order = await getOrderById(orderId);
    if (order == null) throw Exception('Erro ao buscar pedido criado');
    
    return order;
  }
  
  Future<List<Order>> getOrders() async {
    if (_userId == null) return [];

    final response = await _client.from('orders')
        .select('*, addresses(*), payment_methods(*), order_items(*, products(*, categories(nome))), order_status_history(*)')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<Order>> getOrdersByStatus(OrderStatus? status) async {
    if (_userId == null) return [];

    var query = _client.from('orders')
        .select('*, addresses(*), payment_methods(*), order_items(*, products(*, categories(nome))), order_status_history(*)');
    
    query = query.eq('user_id', _userId!);

    if (status != null) {
      query = query.eq('status', status.name);
    }

    final response = await query.order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => Order.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<Order?> getOrderById(String orderId) async {
    if (_userId == null) return null;
    final response = await _client.from('orders')
        .select('*, addresses(*), payment_methods(*), order_items(*, products(*, categories(nome))), order_status_history(*)')
        .eq('id', orderId)
        .eq('user_id', _userId!)
        .maybeSingle();

    if (response == null) return null;
    return Order.fromJson(response);
  }

  Future<Order> cancelOrder(String orderId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    await _client.from('orders')
        .update({'status': 'cancelled'})
        .eq('id', orderId)
        .eq('user_id', _userId!);

    await _client.from('order_status_history').insert({
      'order_id': orderId,
      'status': 'cancelled',
      'description': 'Pedido cancelado pelo cliente',
    });

    final order = await getOrderById(orderId);
    if (order == null) throw Exception('Pedido não encontrado');
    return order;
  }
}
