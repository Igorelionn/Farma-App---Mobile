import 'dart:convert';
import 'dart:io';

void main() {
  print('🔄 Recategorizando produtos com lógica melhorada...\n');
  
  final inputFile = File('assets/data/products.json');
  final products = jsonDecode(inputFile.readAsStringSync()) as List;
  
  var changed = 0;
  final categorias = <String, int>{};
  
  for (var product in products) {
    final oldCat = product['categoria'] as String;
    final newCat = recategorize(product);
    
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
  
  print('✅ $changed produtos recategorizados\n');
  print('📊 Nova distribuição de categorias:\n');
  
  final sorted = categorias.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  for (var entry in sorted) {
    final percent = (entry.value / products.length * 100).toStringAsFixed(1);
    print('  • ${entry.key}: ${entry.value} produtos ($percent%)');
  }
}

String recategorize(Map<String, dynamic> product) {
  final nome = (product['nome'] as String).toUpperCase();
  final desc = (product['descricao'] as String? ?? '').toUpperCase();
  final text = '$nome $desc';
  
  // ORDEM IMPORTANTE: do mais específico para o mais geral
  
  // 1. NUTRIÇÃO (Leites, Fórmulas)
  if (_isNutricao(text)) return 'Nutrição';
  
  // 2. SOLUÇÕES INJETÁVEIS (Água, Soro, Glicose)
  if (_isSolucaoInjetavel(text)) return 'Soluções Injetáveis';
  
  // 3. MEDICAMENTOS INJETÁVEIS (antes de vitaminas!)
  if (_isMedicamentoInjetavel(text)) return 'Medicamentos Injetáveis';
  
  // 4. MEDICAMENTOS ORAIS (inclui ferro, magnésio medicinal, etc.)
  if (_isMedicamentoOral(text)) return 'Medicamentos';
  
  // 5. SUPLEMENTOS (DEPOIS de medicamentos)
  if (_isVitaminaSuplemento(text)) return 'Suplementos';
  
  // 6. MATERIAL MÉDICO HOSPITALAR
  if (_isMaterialMedico(text)) return 'Material Médico Hospitalar';
  
  // 7. EQUIPAMENTOS
  if (_isEquipamento(text)) return 'Equipamentos e Aparelhos';
  
  // 8. HIGIENE
  if (_isHigiene(text)) return 'Higiene e Cuidados';
  
  // 9. DERMOCOSMÉTICOS
  if (_isDermocosmetico(text)) return 'Dermocosméticos';
  
  // 10. LIMPEZA
  if (_isLimpeza(text)) return 'Limpeza e Desinfecção';
  
  // 11. OUTROS
  return 'Outros';
}

bool _isNutricao(String text) {
  return text.contains('APTAMIL') ||
         text.contains('NAN ') ||
         text.contains('FORMULA') ||
         text.contains('LEITE EM PO') ||
         text.contains('NUTRI') && text.contains('800G');
}

bool _isSolucaoInjetavel(String text) {
  // Água para injetáveis, soros, glicose
  if ((text.contains('AGUA') && 
       (text.contains('INJET') || text.contains('INJ.') || text.contains('P/INJ') || text.contains('DEIONIZADA'))) ||
      text.contains('SORO ') ||
      text.contains('SF 0,9') ||
      text.contains('SOLUCAO FISIOLOGICA') ||
      (text.contains('GLICOSE') && text.contains('ML') && !text.contains('ORAL')) ||
      (text.contains('CLORETO') && text.contains('SODIO') && text.contains('ML')) ||
      text.contains('RINGER')) {
    return true;
  }
  return false;
}

bool _isVitaminaSuplemento(String text) {
  // APENAS vitaminas puras e suplementos nutricionais
  // NÃO incluir medicamentos mesmo que contenham minerais
  return text.contains('VITAMINA') ||
         text.contains('COMPLEXO B') && !text.contains('INJ') ||  // Complexo B oral é suplemento
         text.contains('ACIDO FOLICO') && !text.contains('0,2MG/ML') ||  // Ácido fólico em gotas é medicamento
         text.contains('CARBONATO') && text.contains('CALCIO') ||  // Carbonato de cálcio é suplemento
         text.contains('GLUCONATO') && text.contains('CALCIO') && !text.contains('10%');  // Gluconato injetável é medicamento
}

bool _isMedicamentoInjetavel(String text) {
  // Medicamentos em ampola ou injetáveis
  if (text.contains('F/A') ||
      text.contains('IV ') ||
      text.contains('IM ') ||
      text.contains('INJ') && text.contains('ML') ||
      text.contains('AMPOLA') && !text.contains('VAZIA') ||
      text.contains('S/DIL') ||
      text.contains('BENZILPENICILINA') ||
      text.contains('CEFTRIAXONA') && text.contains('G ') ||
      text.contains('ADRENALINA') ||
      text.contains('ATROPINA') ||
      text.contains('DIAZEPAM') && text.contains('ML') ||
      text.contains('FENTANIL') ||
      text.contains('MIDAZOLAM') && text.contains('ML') ||
      text.contains('MORFINA') ||
      text.contains('OXITOCINA') ||
      text.contains('PROPOFOL')) {
    return true;
  }
  return false;
}

bool _isMedicamentoOral(String text) {
  // Medicamentos com minerais (VERIFICAR PRIMEIRO)
  if (text.contains('SULFATO FERROSO') ||
      text.contains('SULFERMAX') ||
      text.contains('HIDROXIDO') ||
      text.contains('HIDROXID') ||
      text.contains('SULFATO') && text.contains('MAGNESIO') && text.contains('10%') ||
      text.contains('ACIDO FOLICO') && text.contains('MG/ML')) {
    return true;
  }
  
  // Medicamentos orais: comprimidos, cápsulas, xaropes, suspensões
  if (text.contains('MG') && (text.contains('C/') || text.contains('COMP') || text.contains('CAP')) ||
      text.contains('COMPRIMIDO') ||
      text.contains('CAPSULA') ||
      text.contains('DRAGEA') ||
      text.contains('XPE') ||
      text.contains('XAROPE') ||
      text.contains('SUSP.') && text.contains('ORAL') ||
      text.contains('SUSPENSAO') && !text.contains('INJ') ||
      text.contains('SOLUCAO ORAL') ||
      text.contains('SOL ORAL') ||
      text.contains('GOTAS') && !text.contains('CONTA GOTAS') ||
      text.contains('MCG') && text.contains('SPRAY') ||
      text.contains('MG/ML') && (text.contains('ML') || text.contains('ORAL')) ||
      text.contains('MG/5ML') ||
      text.contains('CREME') && text.contains('MG/G') ||
      text.contains('POMADA') && text.contains('MG')) {
    
    // Princípios ativos comuns
    final medicamentos = [
      'DIPIRONA', 'PARACETAMOL', 'IBUPROFENO', 'DICLOFENACO', 'AAS ',
      'AMOXICILINA', 'AZITROMICINA', 'CEFALEXINA', 'CIPROFLOXACINO', 'CEFADROXILA',
      'OMEPRAZOL', 'PANTOPRAZOL', 'RANITIDINA', 'ESOMEPRAZOL',
      'LOSARTANA', 'ENALAPRIL', 'CAPTOPRIL', 'ATENOLOL',
      'METFORMINA', 'GLIBENCLAMIDA',
      'SINVASTATINA', 'ATORVASTATINA',
      'DEXAMETASONA', 'PREDNISOLONA', 'PREDNISONA',
      'FLUCONAZOL', 'NISTATINA',
      'LORATADINA', 'DESLORATADINA',
      'BROMOPRIDA', 'METOCLOPRAMIDA', 'DOMPERIDONA',
      'BENZOILMETRONIDAZOL', 'METRONIDAZOL',
      'BECLOMETASONA', 'BUDESONIDA',
      'ACETILCISTEINA', 'AMBROXOL', 'CARBOCISTEINA',
      'ACICLOVIR', 'GENTAMICINA', 'NEOMICINA',
      'ESCOPOLAMINA', 'BUTILBROMETO',
      'ALBENDAZOL', 'MEBENDAZOL', 'NITAZOXANIDA',
      'SULFATO FERROSO', 'SULFERMAX',  // Sulfato ferroso é medicamento
      'HIDROXIDO', 'HIDROXID',  // Hidróxido de alumínio/magnésio é medicamento
    ];
    
    for (var med in medicamentos) {
      if (text.contains(med)) return true;
    }
    
    return true; // Se tem formato de medicamento oral, é medicamento
  }
  
  return false;
}

bool _isMaterialMedico(String text) {
  final materiais = [
    'LUVA', 'SERINGA', 'AGULHA', 'CATETER', 'SONDA', 'JELCO', 'SCALP',
    'GAZE', 'ATADURA', 'ESPARADRAPO', 'CURATIVO', 'COMPRESSA', 'ALGODAO',
    'EQUIPO', 'EXTENSOR', 'BOLSA COLETORA', 'BOLSA COLOSTOMIA',
    'MASCARA CIRURGICA', 'MASCARA N95', 'AVENTAL', 'TOUCA',
    'BANDAGEM', 'MICROPORE', 'ADESIVO',
    'FIXADOR', 'DRENO', 'CLAMP',
    'COLETOR', 'ABAIXADOR', 'ESPATULA',
    'TAMPA', 'BICO', 'ADAPTADOR', 'CONECTOR',
    'TUBO', 'CATGUT', 'FIO DE SUTURA',
    'LANCETA', 'TIRA', 'TESTE',
  ];
  
  for (var mat in materiais) {
    if (text.contains(mat)) return true;
  }
  
  return false;
}

bool _isEquipamento(String text) {
  return text.contains('BALANCA') ||
         text.contains('APARELHO') ||
         text.contains('ESFIGMO') ||
         text.contains('TENSOMETRO') ||
         text.contains('TERMOMETRO') && text.contains('DIGITAL') ||
         text.contains('NEBULIZADOR') ||
         text.contains('INALADOR') ||
         text.contains('OXIMETRO') ||
         text.contains('GLICOSIMETRO');
}

bool _isHigiene(String text) {
  return text.contains('FRALDA') ||
         text.contains('ABSORVENTE') ||
         text.contains('PROTETOR DE CAMA') ||
         text.contains('PAPEL HIGIENICO') ||
         text.contains('LENCO') && text.contains('UMEDECIDO');
}

bool _isDermocosmetico(String text) {
  return text.contains('SABONETE') && !text.contains('HOSPITALAR') ||
         text.contains('SHAMPOO') ||
         text.contains('CONDICIONADOR') ||
         text.contains('HIDRATANTE') && !text.contains('MG') ||
         text.contains('PROTETOR SOLAR') ||
         text.contains('REPELENTE') ||
         text.contains('OLEO MINERAL') && !text.contains('AGUA');
}

bool _isLimpeza(String text) {
  return text.contains('ALCOOL 70') ||
         text.contains('ALCOOL GEL') ||
         text.contains('ALCOOL ETILICO') ||
         text.contains('ALCOOL 1L') ||
         text.contains('HIPOCLORITO') ||
         text.contains('AGUA SANITARIA') ||
         text.contains('AGUA OXIGENADA') ||
         text.contains('DESINFETANTE') ||
         text.contains('DETERGENTE') ||
         text.contains('SABAO') && text.contains('LIMPEZA') ||
         text.contains('GLUTARALDEIDO') ||
         text.contains('CLOREXIDINA') && (text.contains('DEGERM') || text.contains('HOSP.') || text.contains('1L'));
}

