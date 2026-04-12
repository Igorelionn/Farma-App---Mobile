import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/shopping_list.dart';
import '../../core/services/supabase_service.dart';

class FavoritesRepository {
  SupabaseClient get _client => SupabaseService.client;
  String? get _userId => SupabaseService.currentUserId;
  
  // ===== FAVORITOS =====
  
  Future<List<String>> getFavorites() async {
    if (_userId == null) return [];

    final response = await _client.from('favorites')
        .select('product_id')
        .eq('user_id', _userId!);
    
    return (response as List)
        .map((json) => json['product_id'] as String)
        .toList();
  }
  
  Future<List<String>> addToFavorites(String productId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    await _client.from('favorites').upsert({
      'user_id': _userId,
      'product_id': productId,
    }, onConflict: 'user_id,product_id');
    
    return await getFavorites();
  }
  
  Future<List<String>> removeFromFavorites(String productId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    await _client.from('favorites')
        .delete()
        .eq('user_id', _userId!)
        .eq('product_id', productId);
    
    return await getFavorites();
  }
  
  Future<List<String>> toggleFavorite(String productId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final existing = await _client.from('favorites')
        .select()
        .eq('user_id', _userId!)
        .eq('product_id', productId)
        .maybeSingle();
    
    if (existing != null) {
      return await removeFromFavorites(productId);
    } else {
      return await addToFavorites(productId);
    }
  }
  
  Future<bool> isFavorite(String productId) async {
    if (_userId == null) return false;

    final response = await _client.from('favorites')
        .select()
        .eq('user_id', _userId!)
        .eq('product_id', productId)
        .maybeSingle();
    
    return response != null;
  }
  
  // ===== LISTAS DE COMPRAS =====
  
  Future<List<ShoppingList>> getShoppingLists() async {
    if (_userId == null) return [];

    final response = await _client.from('shopping_lists')
        .select('*, shopping_list_items(product_id)')
        .eq('user_id', _userId!)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((json) => ShoppingList.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<ShoppingList> createList(String name) async {
    if (_userId == null) throw Exception('Usuário não autenticado');

    final response = await _client.from('shopping_lists')
        .insert({
          'user_id': _userId,
          'name': name,
        })
        .select('*, shopping_list_items(product_id)')
        .single();
    
    return ShoppingList.fromJson(response);
  }
  
  Future<ShoppingList> updateList(ShoppingList updatedList) async {
    if (_userId == null) throw Exception('Usuário não autenticado');
    final response = await _client.from('shopping_lists')
        .update({'name': updatedList.name})
        .eq('id', updatedList.id)
        .eq('user_id', _userId!)
        .select('*, shopping_list_items(product_id)')
        .single();

    return ShoppingList.fromJson(response);
  }

  Future<void> deleteList(String listId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');
    await _client.from('shopping_lists')
        .delete()
        .eq('id', listId)
        .eq('user_id', _userId!);
  }

  Future<ShoppingList> addProductToList(String listId, String productId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');
    // Verifica propriedade da lista antes de inserir
    final listOwner = await _client.from('shopping_lists')
        .select('id')
        .eq('id', listId)
        .eq('user_id', _userId!)
        .maybeSingle();
    if (listOwner == null) throw Exception('Lista não encontrada');

    await _client.from('shopping_list_items').upsert({
      'list_id': listId,
      'product_id': productId,
    }, onConflict: 'list_id,product_id');
    
    final response = await _client.from('shopping_lists')
        .select('*, shopping_list_items(product_id)')
        .eq('id', listId)
        .single();
    
    return ShoppingList.fromJson(response);
  }
  
  Future<ShoppingList> removeProductFromList(String listId, String productId) async {
    if (_userId == null) throw Exception('Usuário não autenticado');
    // Garante que a lista pertence ao usuário antes de remover
    final listOwner = await _client.from('shopping_lists')
        .select('id')
        .eq('id', listId)
        .eq('user_id', _userId!)
        .maybeSingle();
    if (listOwner == null) throw Exception('Lista não encontrada');

    await _client.from('shopping_list_items')
        .delete()
        .eq('list_id', listId)
        .eq('product_id', productId);
    
    final response = await _client.from('shopping_lists')
        .select('*, shopping_list_items(product_id)')
        .eq('id', listId)
        .single();
    
    return ShoppingList.fromJson(response);
  }
  
  Future<ShoppingList?> getListById(String listId) async {
    final response = await _client.from('shopping_lists')
        .select('*, shopping_list_items(product_id)')
        .eq('id', listId)
        .maybeSingle();

    if (response == null) return null;
    return ShoppingList.fromJson(response);
  }
}
