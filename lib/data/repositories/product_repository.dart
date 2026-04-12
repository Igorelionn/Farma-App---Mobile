import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product.dart';
import '../models/category.dart';
import '../../core/services/supabase_service.dart';

class ProductRepository {
  SupabaseClient get _client => SupabaseService.client;
  
  Future<List<Product>> getAllProducts() async {
    final response = await _client.from('products')
        .select('*, categories(nome)')
        .eq('disponivel', true)
        .order('nome');
    
    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<Category>> getCategories() async {
    final response = await _client.from('categories')
        .select()
        .order('nome');
    
    return (response as List)
        .map((json) => Category.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<Product?> getProductById(String id) async {
    final response = await _client.from('products')
        .select('*, categories(nome)')
        .eq('id', id)
        .maybeSingle();

    if (response == null) return null;
    return Product.fromJson(response);
  }
  
  Future<List<Product>> getProductsByCategory(String categoryId) async {
    final response = await _client.from('products')
        .select('*, categories(nome)')
        .eq('category_id', categoryId)
        .eq('disponivel', true)
        .order('nome');
    
    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<Product>> searchProducts(String query) async {
    if (query.isEmpty) {
      return await getAllProducts();
    }

    // Sanitiza a query: remove caracteres que podem alterar o filtro ilike
    final sanitized = query
        .replaceAll(RegExp(r'[%_\\]'), r'\\$0')
        .trim();

    final response = await _client.from('products')
        .select('*, categories(nome)')
        .eq('disponivel', true)
        .or(
          'nome.ilike.%$sanitized%,'
          'principio_ativo.ilike.%$sanitized%,'
          'laboratorio.ilike.%$sanitized%',
        )
        .order('nome');

    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<Product>> getPromotionalProducts() async {
    final response = await _client.from('products')
        .select('*, categories(nome)')
        .eq('em_promocao', true)
        .eq('disponivel', true)
        .order('nome');
    
    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<Product>> filterProducts({
    String? category,
    String? laboratorio,
    double? minPrice,
    double? maxPrice,
    bool? disponivel,
    String? sortBy,
  }) async {
    var query = _client.from('products')
        .select('*, categories(nome)');
    
    if (category != null && category.isNotEmpty) {
      query = query.eq('category_id', category);
    }
    
    if (laboratorio != null && laboratorio.isNotEmpty) {
      query = query.eq('laboratorio', laboratorio);
    }
    
    if (minPrice != null) {
      query = query.gte('preco', minPrice);
    }
    
    if (maxPrice != null) {
      query = query.lte('preco', maxPrice);
    }
    
    if (disponivel == true) {
      query = query.eq('disponivel', true).gt('estoque', 0);
    }

    String orderColumn = 'nome';
    bool ascending = true;
    if (sortBy != null) {
      switch (sortBy) {
        case 'preco_asc':
          orderColumn = 'preco';
          ascending = true;
          break;
        case 'preco_desc':
          orderColumn = 'preco';
          ascending = false;
          break;
        case 'nome_asc':
          orderColumn = 'nome';
          ascending = true;
          break;
      }
    }

    final response = await query.order(orderColumn, ascending: ascending);
    
    return (response as List)
        .map((json) => Product.fromJson(json as Map<String, dynamic>))
        .toList();
  }
  
  Future<List<String>> getLaboratorios() async {
    final response = await _client.from('products')
        .select('laboratorio')
        .eq('disponivel', true)
        .order('laboratorio');

    final labs = (response as List)
        .map((json) => json['laboratorio'] as String?)
        .whereType<String>()
        .where((l) => l.isNotEmpty)
        .toSet()
        .toList();
    labs.sort();
    return labs;
  }
}
