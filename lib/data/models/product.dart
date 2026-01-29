import 'package:equatable/equatable.dart';

class Product extends Equatable {
  final String id;
  final String nome;
  final String? principioAtivo;
  final String laboratorio;
  final double preco;
  final String apresentacao;
  final int estoque;
  final String categoria;
  final String? imagem;
  final String? tarja; // 'vermelha', 'preta', 'amarela', null
  final String? descricao;
  final bool disponivel;
  final String? codigoBarras;
  final bool emPromocao;
  final double? precoPromocional;
  
  const Product({
    required this.id,
    required this.nome,
    this.principioAtivo,
    required this.laboratorio,
    required this.preco,
    required this.apresentacao,
    required this.estoque,
    required this.categoria,
    this.imagem,
    this.tarja,
    this.descricao,
    this.disponivel = true,
    this.codigoBarras,
    this.emPromocao = false,
    this.precoPromocional,
  });
  
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      nome: json['nome'] as String,
      principioAtivo: json['principioAtivo'] as String?,
      laboratorio: json['laboratorio'] as String,
      preco: (json['preco'] as num).toDouble(),
      apresentacao: json['apresentacao'] as String,
      estoque: json['estoque'] as int,
      categoria: json['categoria'] as String,
      imagem: json['imagem'] as String?,
      tarja: json['tarja'] as String?,
      descricao: json['descricao'] as String?,
      disponivel: json['disponivel'] as bool? ?? true,
      codigoBarras: json['codigoBarras'] as String?,
      emPromocao: json['emPromocao'] as bool? ?? false,
      precoPromocional: json['precoPromocional'] != null
          ? (json['precoPromocional'] as num).toDouble()
          : null,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'principioAtivo': principioAtivo,
      'laboratorio': laboratorio,
      'preco': preco,
      'apresentacao': apresentacao,
      'estoque': estoque,
      'categoria': categoria,
      'imagem': imagem,
      'tarja': tarja,
      'descricao': descricao,
      'disponivel': disponivel,
      'codigoBarras': codigoBarras,
      'emPromocao': emPromocao,
      'precoPromocional': precoPromocional,
    };
  }
  
  double get precoFinal => emPromocao && precoPromocional != null 
      ? precoPromocional! 
      : preco;
  
  bool get isControlado => tarja == 'preta' || tarja == 'vermelha';
  
  @override
  List<Object?> get props => [
    id,
    nome,
    principioAtivo,
    laboratorio,
    preco,
    apresentacao,
    estoque,
    categoria,
    imagem,
    tarja,
    descricao,
    disponivel,
    codigoBarras,
    emPromocao,
    precoPromocional,
  ];
}

