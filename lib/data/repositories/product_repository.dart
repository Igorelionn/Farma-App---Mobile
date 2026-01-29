import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../../core/constants/app_constants.dart';

class ProductRepository {
  List<Product>? _cachedProducts;
  List<Category>? _cachedCategories;
  
  Future<List<Product>> getAllProducts() async {
    if (_cachedProducts != null) {
      return _cachedProducts!;
    }
    
    // Simular delay de API
    await Future.delayed(AppConstants.apiDelay);
    
    final String response = await rootBundle.loadString('assets/data/products.json');
    final List<dynamic> productsJson = json.decode(response);
    
    _cachedProducts = productsJson.map((json) => Product.fromJson(json)).toList();
    return _cachedProducts!;
  }
  
  Future<List<Category>> getCategories() async {
    if (_cachedCategories != null) {
      return _cachedCategories!;
    }
    
    // Simular delay de API
    await Future.delayed(AppConstants.apiDelay);
    
    final String response = await rootBundle.loadString('assets/data/categories.json');
    final List<dynamic> categoriesJson = json.decode(response);
    
    _cachedCategories = categoriesJson.map((json) => Category.fromJson(json)).toList();
    return _cachedCategories!;
  }
  
  Future<Product?> getProductById(String id) async {
    final products = await getAllProducts();
    try {
      return products.firstWhere((product) => product.id == id);
    } catch (e) {
      return null;
    }
  }
  
  Future<List<Product>> getProductsByCategory(String category) async {
    final products = await getAllProducts();
    return products.where((product) => product.categoria == category).toList();
  }
  
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      return await getAllProducts();
    }
    
    final products = await getAllProducts();
    final lowerQuery = query.toLowerCase();
    
    return products.where((product) {
      return product.nome.toLowerCase().contains(lowerQuery) ||
             (product.principioAtivo?.toLowerCase().contains(lowerQuery) ?? false) ||
             product.laboratorio.toLowerCase().contains(lowerQuery);
    }).toList();
  }
  
  Future<List<Product>> getPromotionalProducts() async {
    final products = await getAllProducts();
    return products.where((product) => product.emPromocao).toList();
  }
  
  Future<List<Product>> filterProducts({
    String? category,
    String? laboratorio,
    double? minPrice,
    double? maxPrice,
    bool? disponivel,
    String? sortBy, // 'preco_asc', 'preco_desc', 'nome_asc'
  }) async {
    List<Product> products = await getAllProducts();
    
    // Aplicar filtros
    if (category != null && category.isNotEmpty) {
      products = products.where((p) => p.categoria == category).toList();
    }
    
    if (laboratorio != null && laboratorio.isNotEmpty) {
      products = products.where((p) => p.laboratorio == laboratorio).toList();
    }
    
    if (minPrice != null) {
      products = products.where((p) => p.precoFinal >= minPrice).toList();
    }
    
    if (maxPrice != null) {
      products = products.where((p) => p.precoFinal <= maxPrice).toList();
    }
    
    if (disponivel != null && disponivel) {
      products = products.where((p) => p.disponivel && p.estoque > 0).toList();
    }
    
    // Ordenar
    if (sortBy != null) {
      switch (sortBy) {
        case 'preco_asc':
          products.sort((a, b) => a.precoFinal.compareTo(b.precoFinal));
          break;
        case 'preco_desc':
          products.sort((a, b) => b.precoFinal.compareTo(a.precoFinal));
          break;
        case 'nome_asc':
          products.sort((a, b) => a.nome.compareTo(b.nome));
          break;
      }
    }
    
    return products;
  }
  
  Future<List<String>> getLaboratorios() async {
    final products = await getAllProducts();
    final laboratorios = products.map((p) => p.laboratorio).toSet().toList();
    laboratorios.sort();
    return laboratorios;
  }
}

