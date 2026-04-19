import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/supabase_service.dart';
import '../../core/constants/app_constants.dart';

class CartRepository {
  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => SupabaseService.currentUserId;
  
  Future<List<CartItem>> getCartItems() async {
    if (_userId == null) return [];

    final response = await _client.from('cart_items')
        .select('*, products(*, categories(nome))')
        .eq('user_id', _userId!)
        .order('added_at');
    
    return (response as List)
        .map((json) => CartItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<CartItem>> addToCart(Product product, {int quantity = 1}) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final existing = await _client.from('cart_items')
        .select()
        .eq('user_id', _userId!)
        .eq('product_id', product.id)
        .maybeSingle();
    
    if (existing != null) {
      final newQuantity = (existing['quantity'] as int) + quantity;
      if (newQuantity > product.estoque) {
        throw Exception('Quantidade excede o estoque disponível');
      }
      await _client.from('cart_items')
          .update({'quantity': newQuantity})
          .eq('id', existing['id']);
    } else {
      if (quantity > product.estoque) {
        throw Exception('Quantidade excede o estoque disponível');
      }
      await _client.from('cart_items').insert({
        'user_id': _userId,
        'product_id': product.id,
        'quantity': quantity,
      });
    }
    
    return await getCartItems();
  }
  
  Future<List<CartItem>> removeFromCart(String itemId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');
    await _client.from('cart_items')
        .delete()
        .eq('id', itemId)
        .eq('user_id', _userId!);
    return await getCartItems();
  }

  Future<List<CartItem>> updateQuantity(String itemId, int newQuantity) async {
    if (_userId == null) throw Exception('Usuário não autenticado');
    if (newQuantity <= 0) {
      return removeFromCart(itemId);
    }

    await _client.from('cart_items')
        .update({'quantity': newQuantity})
        .eq('id', itemId)
        .eq('user_id', _userId!);

    return await getCartItems();
  }
  
  Future<void> clearCart() async {
    if (_userId == null) return;
    await _client.from('cart_items').delete().eq('user_id', _userId!);
  }
  
  Future<Map<String, double>> calculateTotals() async {
    final items = await getCartItems();
    
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.subtotal;
    }
    
    // Calcular frete baseado no subtotal
    double shipping = subtotal >= AppConstants.freeShippingThreshold 
        ? 0 
        : AppConstants.defaultShippingCost;
    
    double discount = 0; // Desconto pode ser implementado futuramente
    double total = subtotal + shipping - discount;
    
    return {
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
      'total': total,
    };
  }
  
  Future<int> getItemCount() async {
    final items = await getCartItems();
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
  
  Future<bool> validateCart() async {
    final items = await getCartItems();
    if (items.isEmpty) return false;
    return items.every((item) => item.isValid);
  }
}
