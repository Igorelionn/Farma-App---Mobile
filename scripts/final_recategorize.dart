import 'dart:convert';
import 'dart:io';

void main() {
  print('🔄 Consolidando categorias...\n');
  
  final inputFile = File('assets/data/products.json');
  final products = jsonDecode(inputFile.readAsStringSync()) as List;
  
  var changed = 0;
  final categorias = <String, int>{};
  
  for (var product in products) {
    final oldCat = product['categoria'] as String;
    final newCat = consolidateCategory(oldCat);
    
    if (oldCat != newCat) {
      product['categoria'] = newCat;
      changed++;
    }
    
    categorias[newCat] = (categorias[newCat] ?? 0) + 1;
  }
  
  // Salvar arquivo atualizado
  final outputFile = File('assets/data/products.json');
  final jsonOutput = JsonEncoder.withIndent('  ').convert(products);
  outputFile.writeAsStringSync(jsonOutput);
  
  print('✅ $changed produtos consolidados\n');
  print('📊 Categorias finais:\n');
  
  final sorted = categorias.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (var entry in sorted) {
    final percent = (entry.value / products.length * 100).toStringAsFixed(1);
    print('  • ${entry.key}: ${entry.value} produtos ($percent%)');
  }
}

String consolidateCategory(String oldCategory) {
  // Consolidar categorias pequenas
  switch (oldCategory) {
    case 'Medicamentos':
      return 'Medicamentos';
    
    case 'Material Médico Hospitalar':
      return 'Material Hospitalar';
    
    case 'Soluções Injetáveis':
    case 'Medicamentos Injetáveis':
      return 'Injetáveis'; // Consolidar as duas
    
    case 'Higiene e Cuidados':
    case 'Dermocosméticos':
      return 'Higiene e Dermocosméticos'; // Consolidar
    
    case 'Equipamentos e Aparelhos':
    case 'Suplementos':
    case 'Nutrição':
      return 'Equipamentos e Nutrição'; // Consolidar
    
    case 'Limpeza e Desinfecção':
      return 'Limpeza e Desinfecção';
    
    case 'Outros':
      return 'Outros';
    
    default:
      return 'Outros';
  }
}

