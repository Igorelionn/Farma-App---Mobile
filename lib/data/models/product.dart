import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String nome;
  final String? principioAtivo;
  final String laboratorio;
  final double preco;
  final String apresentacao;
  final int estoque;
  final String categoryId;
  final String? categoryNome;
  final String? imagemUrl;
  final String? tarja;
  final String? descricao;
  final bool disponivel;
  final String? codigoBarras;
  final bool emPromocao;
  final double? precoPromocional;
  final String? excelRowId;
  final DateTime? lastSyncedAt;
  final String? classificacaoFiscal;
  final String unidade;
  
  const Product({
    required this.id,
    required this.nome,
    this.principioAtivo,
    required this.laboratorio,
    required this.preco,
    required this.apresentacao,
    required this.estoque,
    required this.categoryId,
    this.categoryNome,
    this.imagemUrl,
    this.tarja,
    this.descricao,
    this.disponivel = true,
    this.codigoBarras,
    this.emPromocao = false,
    this.precoPromocional,
    this.excelRowId,
    this.lastSyncedAt,
    this.classificacaoFiscal,
    this.unidade = 'UN',
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    String? catNome;
    String catId;

    if (json['categories'] != null && json['categories'] is Map) {
      catNome = json['categories']['nome'] as String?;
      catId = json['category_id'] as String;
    } else {
      catId = json['category_id'] as String? ?? '';
      catNome = json['category_nome'] as String?;
    }

    return Product(
      id: json['id'] as String,
      nome: json['nome'] as String,
      principioAtivo: json['principio_ativo'] as String?,
      laboratorio: json['laboratorio'] as String,
      preco: (json['preco'] as num).toDouble(),
      apresentacao: json['apresentacao'] as String,
      estoque: json['estoque'] as int? ?? 0,
      categoryId: catId,
      categoryNome: catNome,
      imagemUrl: json['imagem_url'] as String?,
      tarja: json['tarja'] as String?,
      descricao: json['descricao'] as String?,
      disponivel: json['disponivel'] as bool? ?? true,
      codigoBarras: json['codigo_barras'] as String?,
      emPromocao: json['em_promocao'] as bool? ?? false,
      precoPromocional: json['preco_promocional'] != null
          ? (json['preco_promocional'] as num).toDouble()
          : null,
      excelRowId: json['excel_row_id'] as String?,
      lastSyncedAt: json['last_synced_at'] != null
          ? DateTime.parse(json['last_synced_at'] as String)
          : null,
      classificacaoFiscal: json['classificacao_fiscal'] as String?,
      unidade: json['unidade'] as String? ?? 'UN',
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'principio_ativo': principioAtivo,
      'laboratorio': laboratorio,
      'preco': preco,
      'apresentacao': apresentacao,
      'estoque': estoque,
      'category_id': categoryId,
      'imagem_url': imagemUrl,
      'tarja': tarja,
      'descricao': descricao,
      'disponivel': disponivel,
      'codigo_barras': codigoBarras,
      'em_promocao': emPromocao,
      'preco_promocional': precoPromocional,
      'classificacao_fiscal': classificacaoFiscal,
      'unidade': unidade,
    };
  }

  String get categoria => categoryNome ?? '';
  
  double get precoFinal => emPromocao && precoPromocional != null 
      ? precoPromocional! 
      : preco;

  String? get imagem => imagemUrl;
  
  bool get isControlado => tarja == 'preta' || tarja == 'vermelha';
  
  String get codigo => excelRowId ?? '';

  @override
  List<Object?> get props => [
    id, nome, principioAtivo, laboratorio, preco,
    apresentacao, estoque, categoryId, categoryNome,
    imagemUrl, tarja, descricao, disponivel,
    codigoBarras, emPromocao, precoPromocional,
    excelRowId, lastSyncedAt, classificacaoFiscal, unidade,
  ];
}
