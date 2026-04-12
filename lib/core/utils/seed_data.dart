import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../services/supabase_service.dart';

/// Utilitario para importar dados iniciais dos JSONs locais para o Supabase.
/// Executar apenas UMA VEZ apos configurar o projeto Supabase.
class SeedData {
  static final _client = SupabaseService.client;

  static Future<void> seedAll({
    void Function(String message)? onProgress,
  }) async {
    assert(kDebugMode, 'SeedData.seedAll() não deve ser chamado em produção');
    if (!kDebugMode) return;

    onProgress?.call('Iniciando seed de dados...');

    await seedCategories(onProgress: onProgress);
    await seedProducts(onProgress: onProgress);
    await seedPaymentMethods(onProgress: onProgress);

    onProgress?.call('Seed concluido com sucesso!');
  }

  static Future<void> seedCategories({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Importando categorias...');

    final existing = await _client.from('categories').select('id').limit(1);
    if ((existing as List).isNotEmpty) {
      onProgress?.call('Categorias ja existem, pulando...');
      return;
    }

    final String jsonStr = await rootBundle.loadString('assets/data/categories.json');
    final List<dynamic> categoriesJson = json.decode(jsonStr);

    final categories = categoriesJson.map((cat) => {
      'nome': cat['nome'],
      'icone': cat['icone'] ?? 'category',
      'descricao': cat['descricao'],
      'produto_count': cat['produtoCount'] ?? 0,
    }).toList();

    await _client.from('categories').insert(categories);
    onProgress?.call('${categories.length} categorias importadas');
  }

  static Future<void> seedProducts({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Importando produtos...');

    final existing = await _client.from('products').select('id').limit(1);
    if ((existing as List).isNotEmpty) {
      onProgress?.call('Produtos ja existem, pulando...');
      return;
    }

    final categoriesResponse = await _client.from('categories').select('id, nome');
    final categoryMap = <String, String>{};
    for (final cat in categoriesResponse as List) {
      categoryMap[cat['nome'] as String] = cat['id'] as String;
    }

    final String jsonStr = await rootBundle.loadString('assets/data/products.json');
    final List<dynamic> productsJson = json.decode(jsonStr);

    final defaultCategoryId = categoryMap['Outros'] ?? categoryMap.values.first;

    const batchSize = 100;
    for (var i = 0; i < productsJson.length; i += batchSize) {
      final batch = productsJson.skip(i).take(batchSize).toList().asMap().entries.map((entry) {
        final prod = entry.value;
        final globalIndex = i + entry.key;
        final catName = prod['categoria'] as String? ?? 'Outros';
        return {
          'nome': prod['nome'],
          'principio_ativo': prod['principioAtivo'],
          'laboratorio': prod['laboratorio'],
          'preco': prod['preco'],
          'apresentacao': prod['apresentacao'],
          'estoque': prod['estoque'] ?? 0,
          'category_id': categoryMap[catName] ?? defaultCategoryId,
          'imagem_url': prod['imagem'],
          'tarja': prod['tarja'],
          'descricao': prod['descricao'],
          'disponivel': prod['disponivel'] ?? true,
          'codigo_barras': prod['codigoBarras'],
          'em_promocao': prod['emPromocao'] ?? false,
          'preco_promocional': prod['precoPromocional'],
          'excel_row_id': 'SEED_$globalIndex',
        };
      }).toList();

      await _client.from('products').insert(batch);
      final imported = (i + batchSize).clamp(0, productsJson.length);
      onProgress?.call('$imported/${productsJson.length} produtos importados...');
    }

    onProgress?.call('${productsJson.length} produtos importados');
  }

  static Future<void> seedPaymentMethods({
    void Function(String message)? onProgress,
  }) async {
    onProgress?.call('Importando metodos de pagamento...');

    final existing = await _client.from('payment_methods').select('id').limit(1);
    if ((existing as List).isNotEmpty) {
      onProgress?.call('Metodos de pagamento ja existem, pulando...');
      return;
    }

    final String jsonStr = await rootBundle.loadString('assets/data/payment_methods.json');
    final List<dynamic> methodsJson = json.decode(jsonStr);

    final methods = methodsJson.map((m) => {
      'type': m['type'],
      'label': m['label'],
      'description': m['description'],
      'installment_options': m['installmentOptions'],
      'days_to_expire': m['daysToExpire'],
    }).toList();

    await _client.from('payment_methods').insert(methods);
    onProgress?.call('${methods.length} metodos de pagamento importados');
  }
}
