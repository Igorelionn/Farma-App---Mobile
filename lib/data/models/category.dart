import 'package:equatable/equatable.dart';

class Category extends Equatable {
  final String id;
  final String nome;
  final String icone;
  final String? descricao;
  final int? produtoCount;
  
  const Category({
    required this.id,
    required this.nome,
    required this.icone,
    this.descricao,
    this.produtoCount,
  });
  
  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      nome: json['nome'] as String,
      icone: json['icone'] as String? ?? 'category',
      descricao: json['descricao'] as String?,
      produtoCount: json['produto_count'] as int? ?? json['produtoCount'] as int?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'icone': icone,
      'descricao': descricao,
      'produto_count': produtoCount,
    };
  }
  
  @override
  List<Object?> get props => [id, nome, icone, descricao, produtoCount];
}
