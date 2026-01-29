import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartRepository {
  final SharedPreferences prefs;
  static const String _keyCart = 'cart_items';
  
  CartRepository({required this.prefs});
  
  // Carregar carrinho
  Future<List<CartItem>> getCartItems() async {
    try {
      final String? cartJson = prefs.getString(_keyCart);
      if (cartJson == null || cartJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> cartList = json.decode(cartJson);
      return cartList
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Salvar carrinho
  Future<void> _saveCart(List<CartItem> items) async {
    final cartJson = json.encode(items.map((item) => item.toJson()).toList());
    await prefs.setString(_keyCart, cartJson);
  }
  
  // Adicionar produto ao carrinho
  Future<List<CartItem>> addToCart(Product product, {int quantity = 1}) async {
    final items = await getCartItems();
    
    // Verificar se o produto já está no carrinho
    final existingIndex = items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex != -1) {
      // Atualizar quantidade
      final existingItem = items[existingIndex];
      final newQuantity = existingItem.quantity + quantity;
      
      // Validar estoque
      if (newQuantity > product.estoque) {
        throw Exception('Quantidade excede o estoque disponível');
      }
      
      items[existingIndex] = existingItem.copyWith(quantity: newQuantity);
    } else {
      // Adicionar novo item
      if (quantity > product.estoque) {
        throw Exception('Quantidade excede o estoque disponível');
      }
      
      final newItem = CartItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        product: product,
        quantity: quantity,
        addedAt: DateTime.now(),
      );
      items.add(newItem);
    }
    
    await _saveCart(items);
    return items;
  }
  
  // Remover item do carrinho
  Future<List<CartItem>> removeFromCart(String itemId) async {
    final items = await getCartItems();
    items.removeWhere((item) => item.id == itemId);
    await _saveCart(items);
    return items;
  }
  
  // Atualizar quantidade
  Future<List<CartItem>> updateQuantity(String itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return removeFromCart(itemId);
    }
    
    final items = await getCartItems();
    final index = items.indexWhere((item) => item.id == itemId);
    
    if (index != -1) {
      final item = items[index];
      
      // Validar estoque
      if (newQuantity > item.product.estoque) {
        throw Exception('Quantidade excede o estoque disponível');
      }
      
      items[index] = item.copyWith(quantity: newQuantity);
      await _saveCart(items);
    }
    
    return items;
  }
  
  // Limpar carrinho
  Future<void> clearCart() async {
    await prefs.remove(_keyCart);
  }
  
  // Calcular total
  Future<Map<String, double>> calculateTotals() async {
    final items = await getCartItems();
    
    double subtotal = 0;
    for (var item in items) {
      subtotal += item.subtotal;
    }
    
    // Calcular frete (mockado - grátis acima de R$ 1000)
    double shipping = subtotal >= 1000 ? 0 : 30.0;
    
    // Desconto (mockado - sem desconto por enquanto)
    double discount = 0;
    
    double total = subtotal + shipping - discount;
    
    return {
      'subtotal': subtotal,
      'shipping': shipping,
      'discount': discount,
      'total': total,
    };
  }
  
  // Contar itens no carrinho
  Future<int> getItemCount() async {
    final items = await getCartItems();
    return items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
  
  // Validar carrinho antes do checkout
  Future<bool> validateCart() async {
    final items = await getCartItems();
    
    if (items.isEmpty) return false;
    
    // Verificar se todos os itens são válidos
    for (var item in items) {
      if (!item.isValid) return false;
    }
    
    return true;
  }
}


