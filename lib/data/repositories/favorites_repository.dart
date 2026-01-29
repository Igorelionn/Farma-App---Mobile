import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/shopping_list.dart';

class FavoritesRepository {
  final SharedPreferences prefs;
  static const String _keyFavorites = 'favorite_products';
  static const String _keyLists = 'shopping_lists';
  
  FavoritesRepository({required this.prefs});
  
  // ===== FAVORITOS =====
  
  // Carregar favoritos
  Future<List<String>> getFavorites() async {
    try {
      final String? favoritesJson = prefs.getString(_keyFavorites);
      if (favoritesJson == null || favoritesJson.isEmpty) {
        return [];
      }
      return List<String>.from(json.decode(favoritesJson));
    } catch (e) {
      return [];
    }
  }
  
  // Adicionar aos favoritos
  Future<List<String>> addToFavorites(String productId) async {
    final favorites = await getFavorites();
    if (!favorites.contains(productId)) {
      favorites.add(productId);
      await _saveFavorites(favorites);
    }
    return favorites;
  }
  
  // Remover dos favoritos
  Future<List<String>> removeFromFavorites(String productId) async {
    final favorites = await getFavorites();
    favorites.remove(productId);
    await _saveFavorites(favorites);
    return favorites;
  }
  
  // Toggle favorito
  Future<List<String>> toggleFavorite(String productId) async {
    final favorites = await getFavorites();
    if (favorites.contains(productId)) {
      favorites.remove(productId);
    } else {
      favorites.add(productId);
    }
    await _saveFavorites(favorites);
    return favorites;
  }
  
  // Verificar se é favorito
  Future<bool> isFavorite(String productId) async {
    final favorites = await getFavorites();
    return favorites.contains(productId);
  }
  
  // Salvar favoritos
  Future<void> _saveFavorites(List<String> favorites) async {
    final favoritesJson = json.encode(favorites);
    await prefs.setString(_keyFavorites, favoritesJson);
  }
  
  // ===== LISTAS DE COMPRAS =====
  
  // Carregar listas
  Future<List<ShoppingList>> getShoppingLists() async {
    try {
      final String? listsJson = prefs.getString(_keyLists);
      if (listsJson == null || listsJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> listsList = json.decode(listsJson);
      return listsList
          .map((list) => ShoppingList.fromJson(list as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  // Salvar listas
  Future<void> _saveLists(List<ShoppingList> lists) async {
    final listsJson = json.encode(lists.map((list) => list.toJson()).toList());
    await prefs.setString(_keyLists, listsJson);
  }
  
  // Criar lista
  Future<ShoppingList> createList(String name) async {
    final lists = await getShoppingLists();
    
    final newList = ShoppingList(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      createdAt: DateTime.now(),
      productIds: const [],
    );
    
    lists.add(newList);
    await _saveLists(lists);
    return newList;
  }
  
  // Atualizar lista
  Future<ShoppingList> updateList(ShoppingList updatedList) async {
    final lists = await getShoppingLists();
    final index = lists.indexWhere((list) => list.id == updatedList.id);
    
    if (index != -1) {
      lists[index] = updatedList.copyWith(updatedAt: DateTime.now());
      await _saveLists(lists);
      return lists[index];
    }
    
    throw Exception('Lista não encontrada');
  }
  
  // Deletar lista
  Future<void> deleteList(String listId) async {
    final lists = await getShoppingLists();
    lists.removeWhere((list) => list.id == listId);
    await _saveLists(lists);
  }
  
  // Adicionar produto à lista
  Future<ShoppingList> addProductToList(String listId, String productId) async {
    final lists = await getShoppingLists();
    final index = lists.indexWhere((list) => list.id == listId);
    
    if (index != -1) {
      final list = lists[index];
      if (!list.productIds.contains(productId)) {
        final updatedList = list.copyWith(
          productIds: [...list.productIds, productId],
          updatedAt: DateTime.now(),
        );
        lists[index] = updatedList;
        await _saveLists(lists);
        return updatedList;
      }
      return list;
    }
    
    throw Exception('Lista não encontrada');
  }
  
  // Remover produto da lista
  Future<ShoppingList> removeProductFromList(String listId, String productId) async {
    final lists = await getShoppingLists();
    final index = lists.indexWhere((list) => list.id == listId);
    
    if (index != -1) {
      final list = lists[index];
      final updatedProductIds = List<String>.from(list.productIds);
      updatedProductIds.remove(productId);
      
      final updatedList = list.copyWith(
        productIds: updatedProductIds,
        updatedAt: DateTime.now(),
      );
      lists[index] = updatedList;
      await _saveLists(lists);
      return updatedList;
    }
    
    throw Exception('Lista não encontrada');
  }
  
  // Obter lista por ID
  Future<ShoppingList?> getListById(String listId) async {
    final lists = await getShoppingLists();
    try {
      return lists.firstWhere((list) => list.id == listId);
    } catch (e) {
      return null;
    }
  }
}


